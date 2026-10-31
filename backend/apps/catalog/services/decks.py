from apps.catalog import repositories
from apps.catalog.models import Deck
from shared import cache


class DeckNotFound(Exception):
    pass


def rename_deck(slug: str, name: str) -> Deck:
    deck = repositories.get_deck(slug)
    if deck is None:
        raise DeckNotFound(slug)
    deck = repositories.rename_deck(deck, name)
    cache.bump_catalog_version()
    return deck
