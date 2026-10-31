import base64
import subprocess
from datetime import datetime
from pathlib import Path

from apps.catalog.services.parser import NOTE_PREFIX

SPARSE_PATTERN = f"{NOTE_PREFIX}*.md"
TIMEOUT_SECONDS = 300
COMMIT_MARK = "@@commit "


class VaultSyncError(Exception):
    pass


class GitVault:
    def __init__(self, url: str, branch: str, directory: Path, token: str = ""):
        self.url = url
        self.branch = branch
        self.directory = directory
        self.token = token

    def sync(self) -> str:
        if (self.directory / ".git").is_dir():
            self._git("fetch", "--filter=blob:none", "origin", self.branch)
            self._git("reset", "--hard", f"origin/{self.branch}")
        else:
            self.directory.parent.mkdir(parents=True, exist_ok=True)
            self._git(
                "clone", "--filter=blob:none", "--no-checkout", "--branch", self.branch, self.url, str(self.directory),
                cwd=self.directory.parent,
            )
            self._git("sparse-checkout", "set", "--no-cone", SPARSE_PATTERN)
            self._git("checkout", self.branch)
        return self._git("rev-parse", "--short", "HEAD").strip()

    def last_commit_dates(self) -> dict[str, datetime]:
        output = self._git(
            "-c", "core.quotePath=false", "log", f"--format={COMMIT_MARK}%cI", "--name-only", "--",
            f"*{SPARSE_PATTERN}",
        )
        dates: dict[str, datetime] = {}
        current: datetime | None = None
        for line in output.splitlines():
            if line.startswith(COMMIT_MARK):
                current = datetime.fromisoformat(line.removeprefix(COMMIT_MARK))
            elif line and current is not None:
                dates.setdefault(line, current)
        return dates

    def _git(self, *args: str, cwd: Path | None = None) -> str:
        command = ["git", *self._auth(), *args]
        try:
            result = subprocess.run(
                command,
                cwd=cwd or self.directory,
                capture_output=True,
                text=True,
                timeout=TIMEOUT_SECONDS,
                env={"GIT_TERMINAL_PROMPT": "0", "PATH": "/usr/local/bin:/usr/bin:/bin", "HOME": "/tmp"},
            )
        except subprocess.TimeoutExpired as exc:
            raise VaultSyncError(f"git {args[0]} non ha risposto in {TIMEOUT_SECONDS} s") from exc
        if result.returncode != 0:
            raise VaultSyncError(f"git {args[0]} è fallito: {self._redact(result.stderr.strip())}")
        return result.stdout

    def _auth(self) -> list[str]:
        if not self.token:
            return []
        credentials = base64.b64encode(f"x-access-token:{self.token}".encode()).decode()
        return ["-c", f"http.extraHeader=Authorization: Basic {credentials}"]

    def _redact(self, text: str) -> str:
        return text.replace(self.token, "***") if self.token else text
