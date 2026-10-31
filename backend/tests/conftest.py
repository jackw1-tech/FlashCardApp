from io import StringIO
from pathlib import Path

import pytest
from django.contrib.auth import get_user_model
from django.core.management import call_command
from rest_framework.test import APIClient

CSRF_HEADER = {"HTTP_X_REQUESTED_WITH": "flashcard"}


class Vault:

    def __init__(self, root: Path):
        self.root = root

    def note(self, title: str, body: str, deck: str | None = "dss") -> None:
        frontmatter = f"---\ntags:\n  - flashcards/{deck}\n---\n" if deck else ""
        self.write(f"Flashcard -> {title}.md", f"{frontmatter}\n# Flashcard -> {title}\n\n{body}\n")

    def write(self, filename: str, text: str) -> None:
        (self.root / filename).write_text(text, encoding="utf-8")

    def remove(self, title: str) -> None:
        (self.root / f"Flashcard -> {title}.md").unlink()

    def import_(self) -> str:
        out = StringIO()
        call_command("import_vault", str(self.root), stdout=out)
        return out.getvalue()


@pytest.fixture
def vault(tmp_path, db) -> Vault:
    return Vault(tmp_path)


@pytest.fixture(scope="session")
def django_db_modify_db_settings():
    from django.conf import settings

    for alias in settings.REPLICA_DB_ALIASES:
        settings.DATABASES[alias]["HOST"] = settings.DATABASES["default"]["HOST"]


@pytest.fixture
def user(db):
    return get_user_model().objects.create_user("giacomo")


@pytest.fixture
def api(user) -> APIClient:
    client = APIClient()
    client.credentials(**CSRF_HEADER)
    client.force_authenticate(user)
    return client


@pytest.fixture
def anon() -> APIClient:
    client = APIClient()
    client.credentials(**CSRF_HEADER)
    return client


@pytest.fixture(autouse=True)
def isolated_redis(settings):
    from shared import redis as shared_redis

    settings.REDIS_URL = settings.REDIS_URL.rsplit("/", 1)[0] + "/15"
    client = shared_redis.get_redis()
    client.flushdb()
    yield client
    client.flushdb()


def decks(api: APIClient) -> dict:
    response = api.get("/api/decks/")
    assert response.status_code == 200
    body = response.json()
    return {"all": body["all"], **{d["slug"]: d for d in body["decks"]}}


def next_card(api: APIClient, deck: str | None = None, exclude: list[int] = (), note: str | None = None) -> dict | None:
    params = {}
    if deck:
        params["deck"] = deck
    if note:
        params["note"] = note
    if exclude:
        params["exclude"] = ",".join(map(str, exclude))
    response = api.get("/api/next-card/", params)
    assert response.status_code == 200, response.content
    return response.json()["card"]


def all_cards(api: APIClient, deck: str | None = None, note: str | None = None) -> list[dict]:
    cards = []
    while card := next_card(api, deck, [c["id"] for c in cards], note):
        cards.append(card)
    return cards


def review(api: APIClient, card_id: int, outcome: str = "knew"):
    return api.post("/api/reviews/", {"card_id": card_id, "outcome": outcome}, format="json")
