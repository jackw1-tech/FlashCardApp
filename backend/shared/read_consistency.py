import logging

import redis
from django.conf import settings
from django.db import DEFAULT_DB_ALIAS, DatabaseError, connections

from shared.redis import get_redis
from shared.replica_choice import replica_for

logger = logging.getLogger(__name__)

MARKER_TTL_SECONDS = 600

_ADVANCE = """
local function position(lsn)
  local high, low = string.match(lsn, "^(%x+)/(%x+)$")
  return tonumber(high, 16) * 4294967296 + tonumber(low, 16)
end
local current = redis.call("GET", KEYS[1])
if current and position(current) >= position(ARGV[1]) then
  redis.call("EXPIRE", KEYS[1], ARGV[2])
  return current
end
redis.call("SET", KEYS[1], ARGV[1], "EX", ARGV[2])
return ARGV[1]
"""


def _marker_key(user_id) -> str:
    return f"seen:lsn:user:{user_id}"


def advance_marker(user, lsn: str) -> None:
    get_redis().eval(_ADVANCE, 1, _marker_key(user.pk), lsn, MARKER_TTL_SECONDS)


def _position(alias: str) -> str | None:
    query = (
        "SELECT pg_current_wal_insert_lsn()"
        if alias == DEFAULT_DB_ALIAS
        else "SELECT CASE WHEN pg_is_in_recovery() THEN pg_last_wal_replay_lsn() END"
    )
    with connections[alias].cursor() as cursor:
        cursor.execute(query)
        (lsn,) = cursor.fetchone()
    return lsn


def remember_seen(user, alias: str) -> None:
    try:
        lsn = _position(alias)
        if lsn is not None:
            advance_marker(user, lsn)
    except (DatabaseError, redis.RedisError):
        logger.warning("Marcatore non aggiornato per l'utente %s", user.pk)


def replica_reached(alias: str, lsn: str) -> bool:
    try:
        with connections[alias].cursor() as cursor:
            cursor.execute("SELECT pg_is_in_recovery() AND pg_last_wal_replay_lsn() >= %s::pg_lsn", [lsn])
            (reached,) = cursor.fetchone()
    except DatabaseError:
        logger.warning("Replica %s non raggiungibile: lettura dal primary", alias)
        return False
    return bool(reached)


def choose_replica(user) -> str | None:
    if not user.is_authenticated:
        return None
    alias = replica_for(user.pk, settings.REPLICA_DB_ALIASES)
    if alias is None:
        return None
    try:
        marker = get_redis().get(_marker_key(user.pk))
    except redis.RedisError:
        logger.warning("Redis non raggiungibile: lettura dal primary")
        return None
    if marker is None or replica_reached(alias, marker):
        return alias
    return None


class ReadPolicy:

    def __init__(self, request, check_marker: bool = True):
        self.request = request
        self.check_marker = check_marker
        self.decided = False
        self.alias: str | None = None

    def __call__(self) -> str | None:
        if not self.decided:
            user = self.request.user
            if self.check_marker:
                self.alias = choose_replica(user)
            else:
                self.alias = replica_for(user.pk if user.is_authenticated else None, settings.REPLICA_DB_ALIASES)
            self.decided = True
        return self.alias

    def remember_seen(self) -> None:
        if self.check_marker and self.decided and self.request.user.is_authenticated:
            remember_seen(self.request.user, self.alias or DEFAULT_DB_ALIAS)
