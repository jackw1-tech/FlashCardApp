import hashlib
import json
import logging
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from collections.abc import Callable
from typing import Protocol

from django.conf import settings

from apps.catalog import repositories
from apps.catalog.models import Card

logger = logging.getLogger(__name__)

VOYAGE_URL = "https://api.voyageai.com/v1/embeddings"
BATCH_SIZE = 128
BATCH_TOKENS = 6000
CHARS_PER_TOKEN = 3
TIMEOUT_SECONDS = 30
RATE_LIMIT_RETRIES = 10
RATE_LIMIT_WAIT_SECONDS = 25


class EmbeddingsUnavailable(Exception):
    pass


class EmbeddingsRateLimited(EmbeddingsUnavailable):

    def __init__(self, message: str, retry_after: float | None):
        super().__init__(message)
        self.retry_after = retry_after


class Embedder(Protocol):
    model: str

    def embed(self, texts: list[str], *, input_type: str) -> list[list[float]]:
        pass


class VoyageEmbedder:

    def __init__(self, api_key: str, model: str):
        self.api_key = api_key
        self.model = model

    def embed(self, texts: list[str], *, input_type: str) -> list[list[float]]:
        body = json.dumps({"input": texts, "model": self.model, "input_type": input_type}).encode()
        request = urllib.request.Request(
            VOYAGE_URL,
            data=body,
            headers={"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
                payload = json.load(response)
        except urllib.error.HTTPError as exc:
            message = f"Voyage ha risposto {exc.code}: {exc.read()[:200]!r}"
            if exc.code == 429:
                retry_after = exc.headers.get("Retry-After") if exc.headers else None
                raise EmbeddingsRateLimited(message, float(retry_after) if retry_after else None) from exc
            raise EmbeddingsUnavailable(message) from exc
        except (urllib.error.URLError, TimeoutError) as exc:
            raise EmbeddingsUnavailable(f"Voyage non risponde: {exc}") from exc
        rows = sorted(payload["data"], key=lambda row: row["index"])
        return [row["embedding"] for row in rows]


def get_embedder() -> Embedder:
    if not settings.VOYAGE_API_KEY:
        raise EmbeddingsUnavailable("Ricerca semantica non configurata: manca VOYAGE_API_KEY.")
    return VoyageEmbedder(settings.VOYAGE_API_KEY, settings.EMBEDDINGS_MODEL)


def card_text(card: Card) -> str:
    return f"{card.note_title}\n{card.front}\n{card.back}"


def text_hash(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


@dataclass
class EmbedReport:
    embedded: int = 0
    up_to_date: int = 0


def embed_cards(embedder: Embedder | None = None, progress: Callable[[str], None] | None = None) -> EmbedReport:
    embedder = embedder or get_embedder()
    current = repositories.embedding_hashes()
    report = EmbedReport()
    stale: list[tuple[Card, str, str]] = []
    for card in repositories.active_cards().order_by("pk"):
        text = card_text(card)
        digest = text_hash(text)
        if current.get(card.pk) == (embedder.model, digest):
            report.up_to_date += 1
        else:
            stale.append((card, text, digest))

    for batch in _batches(stale):
        vectors = _embed_with_retry(embedder, [text for _, text, _ in batch], progress)
        repositories.save_embeddings(
            [(card, embedder.model, digest, vector) for (card, _, digest), vector in zip(batch, vectors)]
        )
        report.embedded += len(batch)
        if progress:
            progress(f"{report.embedded}/{len(stale)} card")
    return report


def _batches(items: list[tuple[Card, str, str]]):
    batch: list[tuple[Card, str, str]] = []
    tokens = 0
    for item in items:
        estimate = len(item[1]) // CHARS_PER_TOKEN + 1
        if batch and (len(batch) == BATCH_SIZE or tokens + estimate > BATCH_TOKENS):
            yield batch
            batch, tokens = [], 0
        batch.append(item)
        tokens += estimate
    if batch:
        yield batch


def _embed_with_retry(embedder: Embedder, texts: list[str], progress: Callable[[str], None] | None):
    for attempt in range(RATE_LIMIT_RETRIES + 1):
        try:
            return embedder.embed(texts, input_type="document")
        except EmbeddingsRateLimited as exc:
            if attempt == RATE_LIMIT_RETRIES:
                raise
            wait = exc.retry_after or RATE_LIMIT_WAIT_SECONDS
            if progress:
                progress(f"limite di Voyage raggiunto, aspetto {wait:.0f} s")
            time.sleep(wait)


def embed_query(text: str, embedder: Embedder | None = None) -> list[float]:
    [vector] = (embedder or get_embedder()).embed([text], input_type="query")
    return vector
