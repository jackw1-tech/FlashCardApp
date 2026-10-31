from apps.catalog import repositories
from apps.catalog.models import Card

MIN_QUERY_LENGTH = 2
MAX_RESULTS = 50


def search_cards(query: str, deck_slug: str | None) -> list[Card]:
    query = query.strip()
    if len(query) < MIN_QUERY_LENGTH:
        return []
    deck = repositories.get_deck(deck_slug) if deck_slug else None
    if deck_slug and deck is None:
        return []
    return repositories.search_active_cards(query, deck, MAX_RESULTS)
