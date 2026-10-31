from django.conf import settings
from django.db import models
from pgvector.django import VectorField


class Deck(models.Model):

    slug = models.CharField(max_length=100, unique=True)
    name = models.CharField(max_length=200)
    parent = models.ForeignKey(
        "self",
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name="subdecks",
    )

    class Meta:
        ordering = ["name"]
        verbose_name = "mazzo"
        verbose_name_plural = "mazzi"

    def __str__(self) -> str:
        return self.name


class CardKind(models.TextChoices):
    BASIC = "basic"
    MULTILINE = "multiline"
    CLOZE = "cloze"


class Card(models.Model):

    key = models.CharField(max_length=64, unique=True)
    deck = models.ForeignKey(Deck, on_delete=models.PROTECT, related_name="cards")
    note_title = models.CharField(max_length=255)
    kind = models.CharField(max_length=16, choices=CardKind.choices)
    front = models.TextField()
    back = models.TextField()
    line_number = models.PositiveIntegerField()
    note_modified_at = models.DateTimeField(null=True, blank=True)
    archived_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "card"
        verbose_name_plural = "card"

    def __str__(self) -> str:
        return self.front[:80]


class ReportReason(models.TextChoices):
    WRONG_ANSWER = "wrong_answer", "Risposta sbagliata"
    BAD_FORMAT = "bad_format", "Formattata male"
    OTHER = "other", "Altro"


class CardReport(models.Model):

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="card_reports")
    card = models.ForeignKey(Card, on_delete=models.CASCADE, related_name="reports")
    reason = models.CharField(max_length=16, choices=ReportReason.choices)
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "segnalazione"
        verbose_name_plural = "segnalazioni"

    def __str__(self) -> str:
        return f"{self.get_reason_display()}: {self.card}"


class CardEmbedding(models.Model):

    card = models.OneToOneField(Card, on_delete=models.CASCADE, related_name="embedding")
    model = models.CharField(max_length=64)
    text_hash = models.CharField(max_length=64)
    vector = VectorField(dimensions=settings.EMBEDDINGS_DIMENSIONS)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "embedding della card"
        verbose_name_plural = "embedding delle card"
