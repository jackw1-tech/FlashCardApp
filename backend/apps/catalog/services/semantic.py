from dataclasses import dataclass

from django.conf import settings
from django.db.models import QuerySet

from apps.catalog import repositories
from apps.catalog.models import Card
from apps.catalog.services.embeddings import Embedder, embed_query, get_embedder

CANDIDATES_PER_QUERY = 60
NOTES_PER_QUERY = 5


@dataclass(frozen=True)
class CardMatch:
    card: Card
    similarity: float


@dataclass(frozen=True)
class NoteMatch:
    title: str
    deck_slug: str
    similarity: float


def search_cards(query: str, limit: int = 20, embedder: Embedder | None = None) -> list[CardMatch]:
    embedder = embedder or get_embedder()
    cards = repositories.with_similarity(repositories.active_cards(), embed_query(query, embedder), embedder.model)
    return [CardMatch(card, round(card.similarity, 3)) for card in cards[:limit]]


def search_notes(queries: list[str], embedder: Embedder | None = None) -> dict[str, list[NoteMatch]]:
    embedder = embedder or get_embedder()
    results: dict[str, list[NoteMatch]] = {}
    for query in queries:
        best: dict[str, NoteMatch] = {}
        for match in search_cards(query, CANDIDATES_PER_QUERY, embedder):
            title = match.card.note_title
            if title not in best:
                best[title] = NoteMatch(title, match.card.deck.slug, match.similarity)
        results[query] = list(best.values())[:NOTES_PER_QUERY]
    return results


def cards_about(cards: QuerySet[Card], about: str, embedder: Embedder | None = None) -> QuerySet[Card]:
    embedder = embedder or get_embedder()
    near = repositories.with_similarity(cards, embed_query(about, embedder), embedder.model)
    return cards.filter(pk__in=near.filter(similarity__gte=settings.SEMANTIC_MIN_SIMILARITY).values("pk"))


def missing_embeddings(embedder: Embedder | None = None) -> int:
    return repositories.cards_without_embedding((embedder or get_embedder()).model)
