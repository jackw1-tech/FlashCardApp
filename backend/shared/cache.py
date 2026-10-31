import json
import logging
from collections.abc import Callable

import redis
from django.db import transaction

from shared.redis import get_redis

logger = logging.getLogger(__name__)

CATALOG_VERSION_KEY = "catalog:version"


def catalog_version() -> str | None:
    try:
        return get_redis().get(CATALOG_VERSION_KEY) or "0"
    except redis.RedisError:
        logger.warning("Redis non raggiungibile: cache saltata")
        return None


def bump_catalog_version() -> None:

    def bump():
        try:
            get_redis().incr(CATALOG_VERSION_KEY)
        except redis.RedisError:
            logger.warning("Redis non raggiungibile: versione del catalogo non aggiornata")

    bump()
    transaction.on_commit(bump)


def cached_json(key: str | None, ttl_seconds: int, compute: Callable[[], dict]) -> dict:
    if key is None:
        return compute()
    try:
        hit = get_redis().get(key)
    except redis.RedisError:
        logger.warning("Redis non raggiungibile: %s letto dal database", key)
        return compute()
    if hit is not None:
        return json.loads(hit)
    value = compute()
    try:
        get_redis().set(key, json.dumps(value), ex=max(1, ttl_seconds))
    except redis.RedisError:
        logger.warning("Redis non raggiungibile: %s non salvato in cache", key)
    return value


def invalidate(*keys: str) -> None:

    def delete():
        try:
            get_redis().delete(*keys)
        except redis.RedisError:
            logger.warning("Redis non raggiungibile: chiavi %s non invalidate", keys)

    delete()
    transaction.on_commit(delete)
