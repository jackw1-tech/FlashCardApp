import redis
from django.conf import settings

_clients: dict[str, redis.Redis] = {}


def get_redis() -> redis.Redis:
    url = settings.REDIS_URL
    if url not in _clients:
        _clients[url] = redis.Redis.from_url(
            url,
            socket_timeout=0.25,
            socket_connect_timeout=0.25,
            decode_responses=True,
        )
    return _clients[url]
