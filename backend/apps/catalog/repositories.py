from datetime import datetime

from django.db.models import F, FloatField, Q, QuerySet, Value
from django.db.models.functions import Cast
from pgvector.django import CosineDistance

from apps.catalog.models import Card, CardEmbedding, CardReport, Deck


def get_or_create_deck(slug: str) -> Deck:
    parent = None
    parts = slug.split("/")
    for index, part in enumerate(parts):
        path = "/".join(parts[: index + 1])
        deck, _ = Deck.objects.get_or_create(
            slug=path,
            defaults={"name": part, "parent": parent},
        )
        if deck.parent_id != (parent.pk if parent else None):
            deck.parent = parent
            deck.save(update_fields=["parent"])
        parent = deck
    return deck


def get_deck(slug: str) -> Deck | None:
    return Deck.objects.filter(slug=slug).first()


def cards_by_key() -> dict[str, Card]:
    return {card.key: card for card in Card.objects.all()}


def create_cards(cards: list[Card]) -> None:
    Card.objects.bulk_create(cards)


def update_cards(cards: list[Card], fields: list[str]) -> None:
    Card.objects.bulk_update(cards, fields, batch_size=100)


def archive_cards(cards: list[Card], at: datetime) -> None:
    Card.objects.filter(pk__in=[card.pk for card in cards]).update(archived_at=at, updated_at=at)


def active_cards() -> QuerySet[Card]:
    return Card.objects.filter(archived_at__isnull=True).select_related("deck")


def active_cards_for_deck(deck: Deck) -> QuerySet[Card]:
    return active_cards().filter(Q(deck=deck) | Q(deck__parent=deck))


def get_active_card(pk: int) -> Card | None:
    return active_cards().filter(pk=pk).first()


def first_fronts_by_note(limit: int) -> dict[str, list[str]]:
    fronts: dict[str, list[str]] = {}
    for title, front in active_cards().order_by("note_title", "line_number").values_list("note_title", "front"):
        if len(fronts.setdefault(title, [])) < limit:
            fronts[title].append(front)
    return fronts


def active_note_titles() -> list[str]:
    return list(active_cards().order_by("note_title").values_list("note_title", flat=True).distinct())


def rename_deck(deck: Deck, name: str) -> Deck:
    deck.name = name
    deck.save(update_fields=["name"])
    return deck


def search_active_cards(query: str, deck: Deck | None, limit: int) -> list[Card]:
    cards = active_cards().filter(
        Q(front__icontains=query) | Q(back__icontains=query) | Q(note_title__icontains=query)
    )
    if deck is not None:
        cards = cards.filter(Q(deck=deck) | Q(deck__parent=deck))
    return list(cards.order_by("deck__name", "note_title", "line_number")[:limit])


def create_report(user, card: Card, reason: str, comment: str) -> CardReport:
    return CardReport.objects.create(user=user, card=card, reason=reason, comment=comment)


def open_reports(user) -> QuerySet[CardReport]:
    return CardReport.objects.filter(user=user, resolved_at__isnull=True).select_related("card__deck")


def get_report(user, report_id: int) -> CardReport | None:
    return CardReport.objects.filter(user=user, pk=report_id).first()


def resolve_report(report: CardReport, at: datetime) -> CardReport:
    if report.resolved_at is None:
        report.resolved_at = at
        report.save(update_fields=["resolved_at"])
    return report


def embedding_hashes() -> dict[int, tuple[str, str]]:
    return {card_id: (model, digest) for card_id, model, digest in CardEmbedding.objects.values_list("card_id", "model", "text_hash")}


def save_embeddings(rows: list[tuple[Card, str, str, list[float]]]) -> None:
    CardEmbedding.objects.bulk_create(
        [CardEmbedding(card=card, model=model, text_hash=digest, vector=vector) for card, model, digest, vector in rows],
        update_conflicts=True,
        unique_fields=["card"],
        update_fields=["model", "text_hash", "vector", "updated_at"],
    )


def with_similarity(cards: QuerySet[Card], vector: list[float], model: str) -> QuerySet[Card]:
    return (
        cards.filter(embedding__model=model)
        .annotate(similarity=Value(1.0) - Cast(CosineDistance("embedding__vector", vector), FloatField()))
        .order_by(F("similarity").desc())
    )


def cards_without_embedding(model: str) -> int:
    return active_cards().exclude(embedding__model=model).count()
