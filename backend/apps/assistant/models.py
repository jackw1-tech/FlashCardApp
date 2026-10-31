from django.conf import settings
from django.db import models


class ConversationStatus(models.TextChoices):
    IDLE = "idle", "In attesa di un messaggio"
    RUNNING = "running", "Sta rispondendo"
    WAITING_CONFIRMATION = "waiting_confirmation", "In attesa di conferma"


class Conversation(models.Model):

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="conversations")
    title = models.CharField(max_length=200, blank=True)
    status = models.CharField(max_length=24, choices=ConversationStatus.choices, default=ConversationStatus.IDLE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]
        verbose_name = "conversazione"
        verbose_name_plural = "conversazioni"

    def __str__(self) -> str:
        return self.title or f"Conversazione {self.pk}"


class Message(models.Model):

    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name="messages")
    seq = models.PositiveIntegerField()
    role = models.CharField(max_length=16)
    content = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["seq"]
        constraints = [models.UniqueConstraint(fields=["conversation", "seq"], name="unique_message_seq")]
        verbose_name = "messaggio"
        verbose_name_plural = "messaggi"
