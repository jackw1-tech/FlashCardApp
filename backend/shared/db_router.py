from collections.abc import Callable, Iterator
from contextlib import contextmanager
from contextvars import ContextVar

from django.db import DEFAULT_DB_ALIAS, connections

PRIMARY_ONLY_APPS = {"accounts", "auth", "contenttypes", "sessions", "admin"}

ReplicaChoice = str | None | Callable[[], str | None]

_replica_choice: ContextVar[ReplicaChoice] = ContextVar("replica_choice", default=None)


@contextmanager
def replica_reads(choice: ReplicaChoice) -> Iterator[None]:
    token = _replica_choice.set(choice)
    try:
        yield
    finally:
        _replica_choice.reset(token)


def _chosen_replica() -> str | None:
    choice = _replica_choice.get()
    alias = choice() if callable(choice) else choice
    return alias if alias in connections.databases else None


class PrimaryReplicaRouter:
    def db_for_read(self, model, **hints) -> str:
        if model._meta.app_label in PRIMARY_ONLY_APPS:
            return DEFAULT_DB_ALIAS
        if connections[DEFAULT_DB_ALIAS].in_atomic_block:
            return DEFAULT_DB_ALIAS
        return _chosen_replica() or DEFAULT_DB_ALIAS

    def db_for_write(self, model, **hints) -> str:
        return DEFAULT_DB_ALIAS

    def allow_relation(self, obj1, obj2, **hints) -> bool:
        return True

    def allow_migrate(self, db, app_label, model_name=None, **hints) -> bool:
        return db == DEFAULT_DB_ALIAS
