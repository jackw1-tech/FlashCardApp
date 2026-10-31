from dataclasses import dataclass
from datetime import datetime, timedelta

from django.conf import settings
from django.contrib.auth import authenticate
from django.db import transaction
from django.utils import timezone

from apps.accounts import repositories
from apps.accounts.services import tokens

REFRESH_REUSE_GRACE = timedelta(seconds=10)


class InvalidCredentials(Exception):
    pass


class TooManyAttempts(Exception):
    pass


class NotAuthenticated(Exception):
    pass


class RefreshInProgress(Exception):
    pass


@dataclass(frozen=True)
class IssuedSession:
    user: object
    access: tokens.AccessToken
    refresh: str | None = None
    refresh_expires_at: datetime | None = None


def login(username: str, password: str, ip: str) -> IssuedSession:
    if repositories.failed_login_attempts(ip, username) >= settings.LOGIN_RATE_LIMIT:
        raise TooManyAttempts()
    user = authenticate(username=username, password=password)
    if user is None or not user.is_active:
        repositories.record_failed_login(ip, username, settings.LOGIN_RATE_WINDOW_SECONDS)
        raise InvalidCredentials()
    return _issue(user, family=None)


def session(access_value: str | None, refresh_value: str | None) -> IssuedSession:
    if access_value:
        try:
            access = authenticate_access(access_value)
            return IssuedSession(user=access[0], access=access[1])
        except NotAuthenticated:
            pass
    if refresh_value:
        return rotate(refresh_value)
    raise NotAuthenticated()


def authenticate_access(value: str):
    try:
        access = tokens.decode_access_token(value)
    except tokens.InvalidToken as error:
        raise NotAuthenticated() from error
    if repositories.is_access_token_denied(access.jti):
        raise NotAuthenticated()
    user = repositories.get_active_user(access.user_id)
    if user is None:
        raise NotAuthenticated()
    return user, access


def rotate(refresh_value: str) -> IssuedSession:
    outcome = _rotate(refresh_value)
    if isinstance(outcome, Exception):
        raise outcome
    return outcome


@transaction.atomic
def _rotate(refresh_value: str) -> IssuedSession | Exception:
    now = timezone.now()
    stored = repositories.get_refresh_token_for_update(tokens.hash_refresh_token(refresh_value))
    if stored is None or stored.revoked_at is not None or stored.expires_at <= now:
        return NotAuthenticated()
    if stored.used_at is not None:
        if now - stored.used_at <= REFRESH_REUSE_GRACE:
            return RefreshInProgress()
        repositories.revoke_family(stored.family, now)
        return NotAuthenticated()
    if not stored.user.is_active:
        return NotAuthenticated()
    repositories.mark_used(stored, now)
    return _issue(stored.user, family=stored.family, now=now)


def logout(access_value: str | None, refresh_value: str | None) -> None:
    now = timezone.now()
    if access_value:
        try:
            access = tokens.decode_access_token(access_value)
            repositories.deny_access_token(access.jti, int((access.expires_at - now).total_seconds()) + 1)
        except tokens.InvalidToken:
            pass
    if refresh_value:
        with transaction.atomic():
            stored = repositories.get_refresh_token_for_update(tokens.hash_refresh_token(refresh_value))
            if stored is not None:
                repositories.revoke_family(stored.family, now)


def _issue(user, family, now: datetime | None = None) -> IssuedSession:
    now = now or timezone.now()
    refresh = tokens.new_refresh_token()
    refresh_expires_at = now + timedelta(seconds=settings.REFRESH_TOKEN_LIFETIME_SECONDS)
    repositories.create_refresh_token(user, tokens.hash_refresh_token(refresh), refresh_expires_at, family)
    return IssuedSession(
        user=user,
        access=tokens.issue_access_token(user.pk, now),
        refresh=refresh,
        refresh_expires_at=refresh_expires_at,
    )
