from dataclasses import asdict, dataclass, field
from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from apps.catalog import repositories as catalog
from apps.catalog.models import Card
from apps.study import repositories
from apps.study.models import Review
from apps.study.services.temporary_decks import (
    TemporaryDeckNotFound,
    delete_temporary_deck,
    get_active_temporary_deck,
    list_temporary_decks,
)
from shared import cache

RECENT_OUTCOMES = 5
OVERVIEW_TTL_SECONDS = 3600


class DeckNotFound(Exception):
    pass


class CardNotFound(Exception):
    pass


class ReviewNotFound(Exception):
    pass


class ReviewAlreadyUndone(Exception):
    pass


@dataclass(frozen=True)
class DeckSummary:
    slug: str
    name: str
    total_cards: int
    unseen_cards: int
    subdecks: list["DeckSummary"] = field(default_factory=list)


@dataclass(frozen=True)
class Overview:
    total_cards: int
    unseen_cards: int
    decks: list[DeckSummary]


@dataclass(frozen=True)
class NoteSummary:
    title: str
    total_cards: int
    unseen_cards: int


@dataclass(frozen=True)
class DeckStats:
    slug: str
    name: str
    reviews: int
    knew_ratio: float | None
    last_studied_at: datetime | None


@dataclass(frozen=True)
class Stats:
    today: date
    today_reviews: int
    streak_days: int
    decks: list[DeckStats]


def overview(user) -> Overview:
    data = cache.cached_json(_overview_key(user), OVERVIEW_TTL_SECONDS, lambda: asdict(_compute_overview(user)))
    return Overview(
        total_cards=data["total_cards"],
        unseen_cards=data["unseen_cards"],
        decks=[_deck_summary_from_dict(deck) for deck in data["decks"]],
    )


def _deck_summary_from_dict(data: dict) -> DeckSummary:
    return DeckSummary(
        slug=data["slug"],
        name=data["name"],
        total_cards=data["total_cards"],
        unseen_cards=data["unseen_cards"],
        subdecks=[_deck_summary_from_dict(child) for child in data.get("subdecks", [])],
    )


def _compute_overview(user) -> Overview:
    decks = [
        DeckSummary(
            deck.slug,
            deck.name,
            deck.total_cards,
            deck.total_cards - deck.seen_cards,
            [
                DeckSummary(child.slug, child.name, child.total_cards, child.total_cards - child.seen_cards, [])
                for child in repositories.subdecks_with_counts(user, deck)
            ],
        )
        for deck in repositories.decks_with_counts(user)
    ]
    return Overview(
        total_cards=sum(d.total_cards for d in decks),
        unseen_cards=sum(d.unseen_cards for d in decks),
        decks=decks,
    )


def notes(user, deck_slug: str) -> list[NoteSummary]:
    deck = _get_deck(deck_slug)
    return [
        NoteSummary(row["note_title"], row["total_cards"], row["total_cards"] - row["seen_cards"])
        for row in repositories.notes_with_counts(user, deck)
    ]


def next_card(
    user, deck_slug: str | None, exclude: list[int], note: str | None = None, temporary_deck: int | None = None
) -> Card | None:
    deck = _get_deck(deck_slug) if deck_slug else None
    source = get_active_temporary_deck(user, temporary_deck) if temporary_deck is not None else None
    card = repositories.least_recently_seen_card(user, deck, exclude, note, source)
    if card is not None:
        card.recent_outcomes = repositories.recent_outcomes(user, card, RECENT_OUTCOMES)
    return card


@transaction.atomic
def record_review(user, card_id: int, outcome: str) -> Review:
    card = catalog.get_active_card(card_id)
    if card is None:
        raise CardNotFound(card_id)
    review = repositories.create_review(user, card, outcome)
    repositories.mark_seen(user, card, review.created_at)
    _invalidate_user_cache(user)
    return review


@transaction.atomic
def undo_review(user, review_id: int) -> Review:
    review = repositories.get_review_for_update(user, review_id)
    if review is None:
        raise ReviewNotFound(review_id)
    if repositories.is_undone(review):
        raise ReviewAlreadyUndone(review_id)
    repositories.create_undo(review)
    repositories.rebuild_card_state(user, review.card)
    _invalidate_user_cache(user)
    return review


def stats(user) -> Stats:
    tz = ZoneInfo(settings.STUDY_TIME_ZONE)
    today = timezone.localdate(timezone=tz)
    midnight = datetime.combine(today + timedelta(days=1), time.min, tzinfo=tz)
    ttl = int((midnight - timezone.now()).total_seconds())
    data = cache.cached_json(_stats_key(user, today), ttl, lambda: _stats_to_json(_compute_stats(user, tz, today)))
    return Stats(
        today=date.fromisoformat(data["today"]),
        today_reviews=data["today_reviews"],
        streak_days=data["streak_days"],
        decks=[
            DeckStats(
                slug=deck["slug"],
                name=deck["name"],
                reviews=deck["reviews"],
                knew_ratio=deck["knew_ratio"],
                last_studied_at=datetime.fromisoformat(deck["last_studied_at"]) if deck["last_studied_at"] else None,
            )
            for deck in data["decks"]
        ],
    )


def _compute_stats(user, tz: ZoneInfo, today: date) -> Stats:
    start_of_today = datetime.combine(today, time.min, tzinfo=tz)
    return Stats(
        today=today,
        today_reviews=repositories.reviews_since(user, start_of_today),
        streak_days=_streak(repositories.review_days(user, tz), today),
        decks=[
            DeckStats(
                slug=deck.slug,
                name=deck.name,
                reviews=deck.reviews,
                knew_ratio=deck.knew / deck.reviews if deck.reviews else None,
                last_studied_at=deck.last_studied_at,
            )
            for deck in repositories.deck_stats(user)
        ],
    )


def _stats_to_json(stats: Stats) -> dict:
    data = asdict(stats)
    data["today"] = stats.today.isoformat()
    for deck in data["decks"]:
        deck["last_studied_at"] = deck["last_studied_at"].isoformat() if deck["last_studied_at"] else None
    return data


def _overview_key(user) -> str | None:
    version = cache.catalog_version()
    return None if version is None else f"decks:hierarchy:v{version}:user:{user.pk}"


def _stats_key(user, day: date) -> str | None:
    version = cache.catalog_version()
    return None if version is None else f"stats:hierarchy:v{version}:user:{user.pk}:{day.isoformat()}"


def _invalidate_user_cache(user) -> None:
    keys = [_overview_key(user), _stats_key(user, timezone.localdate(timezone=ZoneInfo(settings.STUDY_TIME_ZONE)))]
    keys = [key for key in keys if key is not None]
    if keys:
        cache.invalidate(*keys)


def _streak(days: list[date], today: date) -> int:
    expected = today if days and days[0] == today else today - timedelta(days=1)
    streak = 0
    for day in days:
        if day != expected:
            break
        streak += 1
        expected -= timedelta(days=1)
    return streak


def _get_deck(slug: str):
    deck = catalog.get_deck(slug)
    if deck is None:
        raise DeckNotFound(slug)
    return deck
