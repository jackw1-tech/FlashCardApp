import hashlib
import secrets
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta

import jwt
from django.conf import settings
from django.utils import timezone

ALGORITHM = "HS256"


class InvalidToken(Exception):
    pass


@dataclass(frozen=True)
class AccessToken:
    value: str
    jti: str
    user_id: str
    expires_at: datetime


def issue_access_token(user_id: int, now: datetime | None = None) -> AccessToken:
    now = now or timezone.now()
    expires_at = now + timedelta(seconds=settings.ACCESS_TOKEN_LIFETIME_SECONDS)
    jti = uuid.uuid4().hex
    value = jwt.encode(
        {"sub": str(user_id), "jti": jti, "iat": now, "exp": expires_at, "typ": "access"},
        settings.JWT_SIGNING_KEY,
        algorithm=ALGORITHM,
    )
    return AccessToken(value, jti, str(user_id), expires_at)


def decode_access_token(value: str) -> AccessToken:
    try:
        claims = jwt.decode(
            value,
            settings.JWT_SIGNING_KEY,
            algorithms=[ALGORITHM],
            options={"require": ["sub", "jti", "exp"]},
        )
    except jwt.PyJWTError as error:
        raise InvalidToken(str(error)) from error
    if claims.get("typ") != "access":
        raise InvalidToken("non è un access token")
    expires_at = datetime.fromtimestamp(claims["exp"], tz=timezone.get_current_timezone())
    return AccessToken(value, claims["jti"], claims["sub"], expires_at)


def new_refresh_token() -> str:
    return secrets.token_urlsafe(32)


def hash_refresh_token(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()
