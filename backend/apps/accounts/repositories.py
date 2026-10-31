import logging
import uuid
from datetime import datetime

import redis
from django.contrib.auth import get_user_model

from apps.accounts.models import RefreshToken
from shared.redis import get_redis

logger = logging.getLogger(__name__)


def get_active_user(user_id: str):
    return get_user_model().objects.filter(pk=user_id, is_active=True).first()


def create_refresh_token(user, token_hash: str, expires_at: datetime, family: uuid.UUID | None = None) -> RefreshToken:
    return RefreshToken.objects.create(
        user=user, token_hash=token_hash, expires_at=expires_at, family=family or uuid.uuid4()
    )


def get_refresh_token_for_update(token_hash: str) -> RefreshToken | None:
    return RefreshToken.objects.select_for_update().select_related("user").filter(token_hash=token_hash).first()


def mark_used(token: RefreshToken, at: datetime) -> None:
    token.used_at = at
    token.save(update_fields=["used_at"])


def revoke_family(family: uuid.UUID, at: datetime) -> int:
    return RefreshToken.objects.filter(family=family, revoked_at__isnull=True).update(revoked_at=at)


def deny_access_token(jti: str, ttl_seconds: int) -> None:
    if ttl_seconds <= 0:
        return
    try:
        get_redis().set(f"revoked:{jti}", "1", ex=ttl_seconds)
    except redis.RedisError:
        logger.warning("Redis non raggiungibile: access token %s non messo in denylist", jti)


def is_access_token_denied(jti: str) -> bool:
    try:
        return bool(get_redis().exists(f"revoked:{jti}"))
    except redis.RedisError:
        logger.warning("Redis non raggiungibile: denylist non controllata (fail-open)")
        return False


def _attempt_keys(ip: str, username: str) -> list[str]:
    return [f"login:ip:{ip}", f"login:user:{username.lower()}"]


def failed_login_attempts(ip: str, username: str) -> int:
    try:
        values = get_redis().mget(_attempt_keys(ip, username))
    except redis.RedisError:
        logger.warning("Redis non raggiungibile: limite ai tentativi di login non applicato (fail-open)")
        return 0
    return max(int(value or 0) for value in values)


def record_failed_login(ip: str, username: str, window_seconds: int) -> None:
    try:
        pipe = get_redis().pipeline()
        for key in _attempt_keys(ip, username):
            pipe.incr(key)
            pipe.expire(key, window_seconds, nx=True)
        pipe.execute()
    except redis.RedisError:
        logger.warning("Redis non raggiungibile: tentativo di login fallito non contato")
