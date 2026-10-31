from django.db.models import Max

from apps.assistant.models import Conversation, ConversationStatus, Message


def create_conversation(user) -> Conversation:
    return Conversation.objects.create(user=user)


def conversations(user) -> list[Conversation]:
    return list(Conversation.objects.filter(user=user))


def get_conversation(user, pk: int) -> Conversation | None:
    return Conversation.objects.filter(user=user, pk=pk).first()


def claim(conversation: Conversation, expected: str) -> bool:
    claimed = Conversation.objects.filter(pk=conversation.pk, status=expected).update(status=ConversationStatus.RUNNING)
    if claimed:
        conversation.status = ConversationStatus.RUNNING
    return bool(claimed)


def set_status(conversation: Conversation, status: str) -> None:
    conversation.status = status
    conversation.save(update_fields=["status", "updated_at"])


def set_title(conversation: Conversation, title: str) -> None:
    conversation.title = title
    conversation.save(update_fields=["title", "updated_at"])


def messages(conversation: Conversation) -> list[Message]:
    return list(conversation.messages.all())


def append_message(conversation: Conversation, role: str, content: list[dict]) -> Message:
    last = conversation.messages.aggregate(last=Max("seq"))["last"]
    message = Message.objects.create(conversation=conversation, seq=0 if last is None else last + 1, role=role, content=content)
    conversation.save(update_fields=["updated_at"])
    return message


def delete_conversation(conversation: Conversation) -> None:
    conversation.delete()
