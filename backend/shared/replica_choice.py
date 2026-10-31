from hashlib import sha256


def replica_for(user_id, aliases: list[str]) -> str | None:
    if not aliases:
        return None
    return max(aliases, key=lambda alias: sha256(f"{user_id}:{alias}".encode()).digest())
