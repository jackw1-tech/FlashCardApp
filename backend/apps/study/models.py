from django.conf import settings
from django.db import models

from apps.catalog.models import Card


class Outcome(models.TextChoices):
    KNEW = "knew", "Sapevo"
    DIDNT_KNOW = "didnt_know", "Non sapevo"


class Review(models.Model):

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="reviews")
    card = models.ForeignKey(Card, on_delete=models.PROTECT, related_name="reviews")
    outcome = models.CharField(max_length=16, choices=Outcome.choices)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "review"
        verbose_name_plural = "review"

    def __str__(self) -> str:
        return f"{self.card} → {self.get_outcome_display()}"


class CardState(models.Model):

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="card_states")
    card = models.ForeignKey(Card, on_delete=models.CASCADE, related_name="states")
    last_seen_at = models.DateTimeField()
    times_seen = models.PositiveIntegerField()

    class Meta:
        constraints = [models.UniqueConstraint(fields=["user", "card"], name="unique_card_state_per_user")]
        verbose_name = "stato card"
        verbose_name_plural = "stati card"


class ReviewUndo(models.Model):

    review = models.OneToOneField(Review, on_delete=models.PROTECT, related_name="undo")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "annullamento"
        verbose_name_plural = "annullamenti"


class TemporaryDeck(models.Model):

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="temporary_decks")
    name = models.CharField(max_length=200)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    expires_at = models.DateTimeField()

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "mazzo provvisorio"
        verbose_name_plural = "mazzi provvisori"

    def __str__(self) -> str:
        return self.name


class TemporaryDeckCard(models.Model):
    temporary_deck = models.ForeignKey(TemporaryDeck, on_delete=models.CASCADE, related_name="entries")
    card = models.ForeignKey(Card, on_delete=models.CASCADE, related_name="temporary_deck_entries")
    position = models.PositiveIntegerField()

    class Meta:
        ordering = ["position"]
        constraints = [
            models.UniqueConstraint(fields=["temporary_deck", "card"], name="unique_card_per_temporary_deck"),
            models.UniqueConstraint(fields=["temporary_deck", "position"], name="unique_position_per_temporary_deck"),
        ]


class TemporaryDeckDraft(models.Model):

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="temporary_deck_drafts")
    name = models.CharField(max_length=200)
    card_ids = models.JSONField()
    by_note = models.JSONField()
    adjustments = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    temporary_deck = models.OneToOneField(
        TemporaryDeck, on_delete=models.SET_NULL, null=True, blank=True, related_name="draft"
    )

    class Meta:
        verbose_name = "anteprima di mazzo provvisorio"
        verbose_name_plural = "anteprime di mazzi provvisori"


class StudySession(models.Model):

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="study_sessions")
    client_id = models.UUIDField()
    deck = models.ForeignKey("catalog.Deck", on_delete=models.SET_NULL, null=True, blank=True, related_name="+")
    note_title = models.CharField(max_length=255, blank=True)
    temporary_deck = models.ForeignKey(
        TemporaryDeck, on_delete=models.SET_NULL, null=True, blank=True, related_name="sessions"
    )
    reviews = models.ManyToManyField(Review, related_name="sessions")
    started_at = models.DateTimeField()
    ended_at = models.DateTimeField(db_index=True)
    knew = models.PositiveIntegerField()
    didnt_know = models.PositiveIntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-ended_at"]
        constraints = [models.UniqueConstraint(fields=["user", "client_id"], name="unique_session_client_id")]
        verbose_name = "sessione"
        verbose_name_plural = "sessioni"

    def __str__(self) -> str:
        return f"{self.ended_at:%d/%m %H:%M} · {self.knew + self.didnt_know} risposte"
