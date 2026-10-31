from datetime import date, datetime
from zoneinfo import ZoneInfo

from django.db.models import Count, Exists, F, FloatField, Max, OuterRef, Q, QuerySet, Subquery
from django.db.models.functions import Cast, Coalesce, Random, TruncDate

from apps.catalog import repositories as catalog
from apps.catalog.models import Card, Deck
from apps.study.models import (
    CardState,
    Outcome,
    Review,
    ReviewUndo,
    StudySession,
    TemporaryDeck,
    TemporaryDeckCard,
    TemporaryDeckDraft,
)


def valid_reviews(user) -> QuerySet[Review]:
    return Review.objects.filter(user=user, undo__isnull=True)


def _with_counts(user, decks: QuerySet[Deck]) -> list[Deck]:
    result = []
    for deck in decks:
        cards = catalog.active_cards_for_deck(deck)
        deck.total_cards = cards.count()
        if not deck.total_cards:
            continue
        deck.seen_cards = cards.filter(states__user=user).distinct().count()
        result.append(deck)
    return result


def decks_with_counts(user) -> list[Deck]:
    return _with_counts(user, Deck.objects.filter(parent__isnull=True).order_by("name"))


def subdecks_with_counts(user, deck: Deck) -> list[Deck]:
    return _with_counts(user, deck.subdecks.order_by("name"))


def notes_with_counts(user, deck: Deck) -> QuerySet:
    return (
        catalog.active_cards_for_deck(deck)
        .values("note_title")
        .annotate(
            total_cards=Count("id", distinct=True),
            seen_cards=Count("states", filter=Q(states__user=user), distinct=True),
        )
        .order_by("note_title")
    )


def least_recently_seen_card(
    user,
    deck: Deck | None,
    exclude: list[int],
    note: str | None = None,
    temporary_deck: TemporaryDeck | None = None,
) -> Card | None:
    cards = catalog.active_cards().exclude(pk__in=exclude)
    if deck is not None:
        cards = cards.filter(Q(deck=deck) | Q(deck__parent=deck))
    if note is not None:
        cards = cards.filter(note_title=note)
    if temporary_deck is not None:
        cards = cards.filter(temporary_deck_entries__temporary_deck=temporary_deck).exclude(
            pk__in=done_cards(user, temporary_deck).values("pk")
        )
    return order_for_study(user, cards, "least_recent").first()


def order_for_study(user, cards: QuerySet[Card], order: str) -> QuerySet[Card]:
    if order == "worst_first":
        mine = valid_reviews(user).filter(card=OuterRef("pk")).order_by().values("card")
        answered = Subquery(mine.annotate(n=Count("id")).values("n"))
        errors = Coalesce(Subquery(mine.filter(outcome=Outcome.DIDNT_KNOW).annotate(n=Count("id")).values("n")), 0)
        return cards.annotate(
            errors=errors, error_ratio=Cast(errors, FloatField()) / Cast(answered, FloatField())
        ).order_by(F("error_ratio").desc(nulls_last=True), F("errors").desc(), Random())
    last_seen = CardState.objects.filter(user=user, card=OuterRef("pk")).values("last_seen_at")[:1]
    return cards.annotate(last_seen=Subquery(last_seen)).order_by(F("last_seen").asc(nulls_first=True), Random())


def recent_outcomes(user, card: Card, limit: int) -> list[str]:
    latest = valid_reviews(user).filter(card=card).order_by("-created_at").values_list("outcome", flat=True)[:limit]
    return list(reversed(latest))


def create_review(user, card: Card, outcome: str) -> Review:
    return Review.objects.create(user=user, card=card, outcome=outcome)


def mark_seen(user, card: Card, at: datetime) -> None:
    state, created = CardState.objects.select_for_update().get_or_create(
        user=user, card=card, defaults={"last_seen_at": at, "times_seen": 1}
    )
    if not created:
        state.last_seen_at = at
        state.times_seen = F("times_seen") + 1
        state.save(update_fields=["last_seen_at", "times_seen"])


def get_review_for_update(user, review_id: int) -> Review | None:
    return Review.objects.select_for_update().select_related("card").filter(user=user, pk=review_id).first()


def is_undone(review: Review) -> bool:
    return ReviewUndo.objects.filter(review=review).exists()


def create_undo(review: Review) -> ReviewUndo:
    return ReviewUndo.objects.create(review=review)


def rebuild_card_state(user, card: Card) -> None:
    summary = valid_reviews(user).filter(card=card).aggregate(last=Max("created_at"), count=Count("id"))
    if summary["count"] == 0:
        CardState.objects.filter(user=user, card=card).delete()
        return
    CardState.objects.update_or_create(
        user=user, card=card, defaults={"last_seen_at": summary["last"], "times_seen": summary["count"]}
    )


def review_days(user, tz: ZoneInfo) -> list[date]:
    return list(
        valid_reviews(user)
        .annotate(day=TruncDate("created_at", tzinfo=tz))
        .values_list("day", flat=True)
        .distinct()
        .order_by("-day")
    )


def reviews_since(user, since: datetime) -> int:
    return valid_reviews(user).filter(created_at__gte=since).count()


def deck_stats(user) -> list[Deck]:
    result = []
    for deck in Deck.objects.filter(parent__isnull=True).order_by("name"):
        cards = catalog.active_cards_for_deck(deck)
        if not cards.exists():
            continue
        mine = valid_reviews(user).filter(card__in=cards)
        summary = mine.aggregate(
            reviews=Count("id"),
            knew=Count("id", filter=Q(outcome=Outcome.KNEW)),
            last_studied_at=Max("created_at"),
        )
        deck.reviews = summary["reviews"]
        deck.knew = summary["knew"]
        deck.last_studied_at = summary["last_studied_at"]
        result.append(deck)
    return result


def missed_since(user, since: datetime) -> QuerySet[Review]:
    return valid_reviews(user).filter(outcome=Outcome.DIDNT_KNOW, created_at__gte=since)


def answered_since(user, since: datetime) -> QuerySet[Review]:
    return valid_reviews(user).filter(created_at__gte=since)


def create_temporary_deck(user, name: str, expires_at: datetime, cards: list[Card]) -> TemporaryDeck:
    deck = TemporaryDeck.objects.create(user=user, name=name, expires_at=expires_at)
    TemporaryDeckCard.objects.bulk_create(
        TemporaryDeckCard(temporary_deck=deck, card=card, position=position) for position, card in enumerate(cards)
    )
    return deck


def get_temporary_deck(user, pk: int) -> TemporaryDeck | None:
    return TemporaryDeck.objects.filter(user=user, pk=pk).first()


def recent_temporary_decks(user, limit: int, active_after: datetime | None = None) -> list[TemporaryDeck]:
    decks = TemporaryDeck.objects.filter(user=user)
    if active_after is not None:
        decks = decks.filter(expires_at__gt=active_after)
    decks = decks.annotate(total=Count("entries")).order_by("-created_at", "-pk")
    return list(decks[:limit])


def delete_temporary_deck(deck: TemporaryDeck) -> None:
    deck.delete()


def temporary_deck_cards(deck: TemporaryDeck) -> QuerySet[Card]:
    return Card.objects.filter(temporary_deck_entries__temporary_deck=deck)


def done_cards(user, deck: TemporaryDeck) -> QuerySet[Card]:
    answered = answered_since(user, deck.created_at).filter(card=OuterRef("pk"))
    return temporary_deck_cards(deck).filter(Exists(answered))


def missed_cards(user, deck: TemporaryDeck) -> QuerySet[Card]:
    return temporary_deck_cards(deck).filter(Exists(missed_since(user, deck.created_at).filter(card=OuterRef("pk"))))


def create_draft(user, **fields) -> TemporaryDeckDraft:
    return TemporaryDeckDraft.objects.create(user=user, **fields)


def get_draft_for_update(user, pk: int) -> TemporaryDeckDraft | None:
    drafts = TemporaryDeckDraft.objects.select_for_update(of=("self",)).select_related("temporary_deck")
    return drafts.filter(user=user, pk=pk).first()


def mark_draft_used(draft: TemporaryDeckDraft, deck: TemporaryDeck) -> None:
    draft.temporary_deck = deck
    draft.save(update_fields=["temporary_deck"])


def active_cards_in_order(card_ids: list[int]) -> list[Card]:
    by_id = {card.pk: card for card in catalog.active_cards().filter(pk__in=card_ids)}
    return [by_id[pk] for pk in card_ids if pk in by_id]


def get_session(user, client_id) -> StudySession | None:
    return StudySession.objects.filter(user=user, client_id=client_id).first()


def create_session(user, *, reviews: list[Review], **fields) -> StudySession:
    session = StudySession.objects.create(user=user, **fields)
    session.reviews.set(reviews)
    return session


def recent_sessions(user, limit: int) -> list[StudySession]:
    return list(StudySession.objects.filter(user=user).select_related("deck", "temporary_deck")[:limit])
