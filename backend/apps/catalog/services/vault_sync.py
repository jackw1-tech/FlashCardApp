import fcntl
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path

from django.conf import settings

from apps.catalog.services.embeddings import EmbeddingsUnavailable, EmbedReport, embed_cards
from apps.catalog.services.importer import ImportReport, file_modified_at, import_vault
from apps.catalog.services.vault_git import GitVault

MAX_ARCHIVED_RATIO = 0.2


class VaultNotConfigured(Exception):
    pass


class VaultSyncInProgress(Exception):
    pass


@dataclass(frozen=True)
class VaultSyncReport:
    branch: str
    commit: str
    imported: ImportReport
    embeddings: EmbedReport
    embedding_error: str | None = None


@contextmanager
def _exclusive_lock(directory: Path) -> Iterator[None]:
    directory.parent.mkdir(parents=True, exist_ok=True)
    lock_path = directory.parent / ".sync-vault.lock"
    with lock_path.open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise VaultSyncInProgress() from exc
        try:
            yield
        finally:
            fcntl.flock(lock, fcntl.LOCK_UN)


def sync_vault(
    *,
    embed: bool = True,
    force: bool = False,
    progress: Callable[[str], None] | None = None,
) -> VaultSyncReport:
    if not settings.VAULT_GIT_URL:
        raise VaultNotConfigured()

    directory = Path(settings.VAULT_GIT_DIR)
    with _exclusive_lock(directory):
        vault = GitVault(settings.VAULT_GIT_URL, settings.VAULT_GIT_BRANCH, directory, settings.VAULT_GIT_TOKEN)
        commit = vault.sync()
        dates = vault.last_commit_dates()

        def modified_at(path: Path):
            return dates.get(path.relative_to(directory).as_posix()) or file_modified_at(path)

        imported = import_vault(directory, modified_at, None if force else MAX_ARCHIVED_RATIO)
        embedding_error = None
        try:
            embeddings = embed_cards(progress=progress) if embed else EmbedReport()
        except EmbeddingsUnavailable as exc:
            embeddings = EmbedReport()
            embedding_error = str(exc)
        return VaultSyncReport(
            settings.VAULT_GIT_BRANCH,
            commit,
            imported,
            embeddings,
            embedding_error,
        )
