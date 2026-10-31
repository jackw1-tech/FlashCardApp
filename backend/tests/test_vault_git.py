import base64
import subprocess
from datetime import datetime
from io import StringIO

import pytest
from django.core.management import call_command
from django.core.management.base import CommandError

from apps.catalog.models import Card
from apps.catalog.services.embeddings import EmbedReport
from apps.catalog.services.importer import ImportReport
from apps.catalog.services.vault_sync import VaultSyncReport
from apps.catalog.services.vault_git import GitVault, VaultSyncError

FIRST = "2026-10-01T09:00:00+02:00"
SECOND = "2026-10-20T18:30:00+02:00"


class Remote:

    def __init__(self, path):
        self.path = path
        path.mkdir()
        self._git("init", "-q", "-b", "main")
        self._git("config", "uploadpack.allowFilter", "true")

    @property
    def url(self) -> str:
        return f"file://{self.path}"

    def note(self, title: str, body: str, deck: str = "dss") -> None:
        self.write(f"Flashcard -> {title}.md", f"---\ntags:\n  - flashcards/{deck}\n---\n\n{body}\n")

    def write(self, name: str, text: str) -> None:
        target = self.path / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8")

    def remove(self, name: str) -> None:
        self._git("rm", "-q", name)

    def commit(self, when: str, message: str = "note") -> None:
        self._git("add", "-A")
        env = {"GIT_AUTHOR_DATE": when, "GIT_COMMITTER_DATE": when}
        self._git("-c", "user.name=Test", "-c", "user.email=t@t", "commit", "-q", "-m", message, env=env)

    def _git(self, *args, env=None):
        subprocess.run(["git", *args], cwd=self.path, check=True, capture_output=True, env={"PATH": "/usr/bin:/bin", "HOME": "/tmp", **(env or {})})


@pytest.fixture
def remote(tmp_path):
    repo = Remote(tmp_path / "remote")
    repo.note("MCP", "Cosa significa MCP?::Model Context Protocol")
    repo.note("Raft", "Cos'è un leader?::Il nodo che coordina\nCos'è un termine?::Un'epoca")
    repo.write("MCP.md", "# La nota di studio, non una nota flashcard")
    repo.write("allegati/lezione.pdf", "%PDF finto")
    repo.commit(FIRST)
    return repo


@pytest.fixture
def clone_dir(tmp_path):
    return tmp_path / "clone" / "repo"


@pytest.fixture
def git_settings(settings, remote, clone_dir):
    settings.VAULT_GIT_URL = remote.url
    settings.VAULT_GIT_BRANCH = "main"
    settings.VAULT_GIT_TOKEN = ""
    settings.VAULT_GIT_DIR = str(clone_dir)
    return settings


def sync_vault(*args) -> str:
    out = StringIO()
    call_command("sync_vault", *args, stdout=out)
    return out.getvalue()


def test_si_scaricano_solo_le_note_flashcard(remote, clone_dir):
    GitVault(remote.url, "main", clone_dir).sync()

    files = sorted(p.name for p in clone_dir.rglob("*") if p.is_file() and ".git" not in p.parts)
    assert files == ["Flashcard -> MCP.md", "Flashcard -> Raft.md"]


def test_la_data_di_una_nota_e_il_suo_ultimo_commit(remote, clone_dir):
    remote.note("Raft", "Cos'è un leader?::Il nodo che coordina le scritture")
    remote.commit(SECOND)
    vault = GitVault(remote.url, "main", clone_dir)
    vault.sync()

    dates = vault.last_commit_dates()

    assert dates == {
        "Flashcard -> MCP.md": datetime.fromisoformat(FIRST),
        "Flashcard -> Raft.md": datetime.fromisoformat(SECOND),
    }


def test_il_secondo_sync_porta_le_novita(remote, clone_dir):
    vault = GitVault(remote.url, "main", clone_dir)
    first = vault.sync()
    remote.note("Kafka", "Cos'è una partizione?::Un log ordinato")
    remote.commit(SECOND)

    second = vault.sync()

    assert second != first
    assert (clone_dir / "Flashcard -> Kafka.md").exists()


def test_un_url_sbagliato_e_un_errore_chiaro_senza_il_token(tmp_path, clone_dir):
    vault = GitVault(f"file://{tmp_path}/non-esiste", "main", clone_dir, token="segreto")

    with pytest.raises(VaultSyncError, match="git clone è fallito") as error:
        vault.sync()

    assert "segreto" not in str(error.value)


def test_il_token_va_in_un_header_e_non_nell_url(clone_dir):
    vault = GitVault("https://github.com/x/vault.git", "main", clone_dir, token="ghp_abc")

    [flag, header] = vault._auth()

    assert flag == "-c"
    assert header == "http.extraHeader=Authorization: Basic " + base64.b64encode(b"x-access-token:ghp_abc").decode()


def test_l_endpoint_sync_e_riservato_allo_staff(api, monkeypatch):
    monkeypatch.setattr(
        "apps.catalog.api.views.vault_sync.sync_vault",
        lambda **kwargs: pytest.fail("un utente normale non deve avviare il sync"),
    )

    assert api.post("/api/vault/sync/", {}, format="json").status_code == 403


def test_l_endpoint_sync_restituisce_il_report(api, user, monkeypatch):
    user.is_staff = True
    user.save(update_fields=["is_staff"])
    monkeypatch.setattr(
        "apps.catalog.api.views.vault_sync.sync_vault",
        lambda **kwargs: VaultSyncReport(
            branch="main",
            commit="abc1234",
            imported=ImportReport(notes=76, cards=2568, created=3, updated=2, archived=1, restored=4),
            embeddings=EmbedReport(embedded=5, up_to_date=2563),
        ),
    )

    response = api.post("/api/vault/sync/", {}, format="json")

    assert response.status_code == 200
    assert response.json() == {
        "status": "completed",
        "branch": "main",
        "commit": "abc1234",
        "notes": 76,
        "cards": 2568,
        "created": 3,
        "updated": 2,
        "archived": 1,
        "restored": 4,
        "problems": 0,
        "embeddings": 5,
        "embeddings_up_to_date": 2563,
        "embedding_error": None,
    }


def test_l_endpoint_distingue_import_riuscito_ed_embedding_falliti(api, user, monkeypatch):
    user.is_staff = True
    user.save(update_fields=["is_staff"])
    monkeypatch.setattr(
        "apps.catalog.api.views.vault_sync.sync_vault",
        lambda **kwargs: VaultSyncReport(
            branch="main",
            commit="abc1234",
            imported=ImportReport(notes=2, cards=10, created=1),
            embeddings=EmbedReport(),
            embedding_error="Voyage non risponde",
        ),
    )

    response = api.post("/api/vault/sync/", {}, format="json")

    assert response.status_code == 207
    assert response.json()["status"] == "partial"
    assert response.json()["created"] == 1
    assert response.json()["embedding_error"] == "Voyage non risponde"


def test_sync_vault_importa_con_le_date_dei_commit(db, git_settings):
    output = sync_vault()

    assert "create: 3" in output
    assert {c.note_modified_at for c in Card.objects.all()} == {datetime.fromisoformat(FIRST)}


def test_senza_url_dice_cosa_impostare(db, settings):
    settings.VAULT_GIT_URL = ""

    with pytest.raises(CommandError, match="VAULT_GIT_URL"):
        sync_vault()


def test_se_archivierebbe_troppe_card_si_ferma_senza_toccare_niente(db, git_settings, remote):
    sync_vault()
    remote.remove("Flashcard -> Raft.md")
    remote.commit(SECOND)

    with pytest.raises(CommandError, match="archivierebbe 2 card su 3"):
        sync_vault()

    assert Card.objects.filter(archived_at__isnull=True).count() == 3


def test_con_force_archivia_lo_stesso(db, git_settings, remote):
    sync_vault()
    remote.remove("Flashcard -> Raft.md")
    remote.commit(SECOND)

    output = sync_vault("--force")

    assert "archiviate: 2" in output
    assert Card.objects.filter(archived_at__isnull=True).count() == 1
