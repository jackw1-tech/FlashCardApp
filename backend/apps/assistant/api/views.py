from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.exceptions import APIException, NotFound
from rest_framework.request import Request
from rest_framework.response import Response

from apps.assistant import repositories
from apps.assistant.api.serializers import ConfirmationInputSerializer, MessageInputSerializer
from apps.assistant.services import chat, transcript


class Conflict(APIException):
    status_code = status.HTTP_409_CONFLICT
    default_detail = "La conversazione sta già rispondendo o aspetta una conferma."


@api_view(["GET", "POST"])
def conversation_list(request: Request) -> Response:
    if request.method == "POST":
        conversation = chat.start_conversation(request.user)
        return Response(transcript.render(conversation), status=status.HTTP_201_CREATED)
    return Response({"conversations": [transcript.summary(c) for c in repositories.conversations(request.user)]})


@api_view(["GET", "DELETE"])
def conversation_detail(request: Request, conversation_id: int) -> Response:
    try:
        if request.method == "DELETE":
            chat.delete_conversation(request.user, conversation_id)
            return Response(status=status.HTTP_204_NO_CONTENT)
        return Response(transcript.render(_get(request, conversation_id)))
    except chat.ConversationNotFound:
        raise NotFound("Conversazione inesistente.")


@api_view(["POST"])
def send_message(request: Request, conversation_id: int) -> Response:
    payload = MessageInputSerializer(data=request.data)
    payload.is_valid(raise_exception=True)
    return _turn(request, conversation_id, lambda: chat.send_message(request.user, conversation_id, payload.validated_data["text"]))


@api_view(["POST"])
def confirmation(request: Request, conversation_id: int) -> Response:
    payload = ConfirmationInputSerializer(data=request.data)
    payload.is_valid(raise_exception=True)
    return _turn(request, conversation_id, lambda: chat.confirm(request.user, conversation_id, payload.validated_data["approve"]))


def _turn(request: Request, conversation_id: int, run) -> Response:
    try:
        return Response(transcript.render(run()))
    except chat.ConversationNotFound:
        raise NotFound("Conversazione inesistente.")
    except chat.ConversationBusy:
        raise Conflict()
    except chat.ChatError as exc:
        return Response(transcript.render(_get(request, conversation_id), error=str(exc)))


def _get(request: Request, conversation_id: int):
    conversation = repositories.get_conversation(request.user, conversation_id)
    if conversation is None:
        raise chat.ConversationNotFound(conversation_id)
    return conversation
