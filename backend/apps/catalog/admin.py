from django.contrib import admin
from django.db.models import Count, F, Func, IntegerField, Q, TextField
from django.db.models.functions import Cast, Left
from django.utils import timezone

from apps.catalog.models import Card, CardEmbedding, CardReport, Deck


@admin.register(Deck)
class DeckAdmin(admin.ModelAdmin):

    list_display = ["slug", "name", "parent", "active_cards"]
    fields = ["slug", "name", "parent"]
    readonly_fields = ["slug", "parent"]

    def get_queryset(self, request):
        return super().get_queryset(request).annotate(
            _active_cards=Count("cards", filter=Q(cards__archived_at__isnull=True), distinct=True),
            _subdeck_active_cards=Count(
                "subdecks__cards",
                filter=Q(subdecks__cards__archived_at__isnull=True),
                distinct=True,
            ),
        )

    @admin.display(description="card attive", ordering="_active_cards")
    def active_cards(self, deck: Deck) -> int:
        return deck._active_cards + deck._subdeck_active_cards

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(Card)
class CardAdmin(admin.ModelAdmin):

    list_display = ["front_preview", "deck", "note_title", "kind", "is_active"]
    list_filter = ["deck", "kind", ("archived_at", admin.EmptyFieldListFilter)]
    list_select_related = ["deck"]
    search_fields = ["front", "note_title"]

    @admin.display(description="domanda")
    def front_preview(self, card: Card) -> str:
        return card.front[:80]

    @admin.display(description="attiva", boolean=True)
    def is_active(self, card: Card) -> bool:
        return card.archived_at is None

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(CardReport)
class CardReportAdmin(admin.ModelAdmin):

    list_display = ["created_at", "reason", "card", "note_title", "comment", "is_open"]
    list_filter = ["reason", ("resolved_at", admin.EmptyFieldListFilter)]
    list_select_related = ["card"]
    search_fields = ["card__front", "card__note_title", "comment"]
    actions = ["mark_resolved"]
    readonly_fields = ["user", "card", "reason", "comment", "created_at"]

    @admin.display(description="nota")
    def note_title(self, report: CardReport) -> str:
        return report.card.note_title

    @admin.display(description="aperta", boolean=True)
    def is_open(self, report: CardReport) -> bool:
        return report.resolved_at is None

    @admin.action(description="Segna come risolte")
    def mark_resolved(self, request, queryset):
        queryset.filter(resolved_at__isnull=True).update(resolved_at=timezone.now())

    def has_add_permission(self, request):
        return False


@admin.register(CardEmbedding)
class CardEmbeddingAdmin(admin.ModelAdmin):

    list_display = ["card_preview", "note_title", "model", "dimensions", "vector_preview", "updated_at"]
    list_filter = ["model", "card__deck"]
    list_select_related = ["card"]
    search_fields = ["card__front", "card__note_title"]
    fields = ["card", "model", "text_hash", "dimensions", "vector_preview", "updated_at"]
    readonly_fields = fields

    def get_queryset(self, request):
        return (
            super()
            .get_queryset(request)
            .defer("vector")
            .annotate(
                _dimensions=Func(F("vector"), function="vector_dims", output_field=IntegerField()),
                _preview=Left(Cast("vector", TextField()), 90),
            )
        )

    @admin.display(description="domanda")
    def card_preview(self, embedding: CardEmbedding) -> str:
        return embedding.card.front[:60]

    @admin.display(description="nota", ordering="card__note_title")
    def note_title(self, embedding: CardEmbedding) -> str:
        return embedding.card.note_title

    @admin.display(description="dimensioni")
    def dimensions(self, embedding: CardEmbedding) -> int:
        return embedding._dimensions

    @admin.display(description="vettore (inizio)")
    def vector_preview(self, embedding: CardEmbedding) -> str:
        return f"{embedding._preview}…"

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

