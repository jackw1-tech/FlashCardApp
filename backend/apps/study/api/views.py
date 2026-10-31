from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.exceptions import APIException, NotFound, ValidationError
from rest_framework.request import Request
from rest_framework.response import Response

from apps.study import services
from apps.study.services import sessions
from apps.study.api.serializers import (
    DeckSummarySerializer,
    NextCardQuerySerializer,
    NoteSummarySerializer,
    ReviewInputSerializer,
    ReviewSerializer,
    StatsSerializer,
    StudyCardSerializer,
    SessionInputSerializer,
    SessionSerializer,
    TemporaryDeckSerializer,
)


class Conflict(APIException):
    status_code = status.HTTP_409_CONFLICT
    default_detail = "Conflitto con lo stato attuale."


@api_view(["GET"])
def deck_list(request: Request) -> Response:
    overview = services.overview(request.user)
    return Response(
        {
            "all": {"total_cards": overview.total_cards, "unseen_cards": overview.unseen_cards},
            "decks": DeckSummarySerializer(overview.decks, many=True).data,
        }
    )


@api_view(["GET"])
def note_list(request: Request, slug: str) -> Response:
    try:
        notes = services.notes(request.user, slug)
    except services.DeckNotFound:
        raise NotFound("Mazzo inesistente.")
    return Response({"notes": NoteSummarySerializer(notes, many=True).data})


@api_view(["GET"])
def next_card(request: Request) -> Response:
    query = NextCardQuerySerializer(data=request.query_params)
    query.is_valid(raise_exception=True)
    data = query.validated_data
    try:
        card = services.next_card(
            request.user, data.get("deck"), data.get("exclude", []), data.get("note"), data.get("temporary_deck")
        )
    except services.DeckNotFound:
        raise NotFound("Mazzo inesistente.")
    except services.TemporaryDeckNotFound:
        raise NotFound("Mazzo provvisorio inesistente o scaduto.")
    return Response({"card": StudyCardSerializer(card).data if card else None})


@api_view(["POST"])
def create_review(request: Request) -> Response:
    payload = ReviewInputSerializer(data=request.data)
    payload.is_valid(raise_exception=True)
    try:
        review = services.record_review(request.user, **payload.validated_data)
    except services.CardNotFound:
        raise NotFound("Card inesistente o archiviata.")
    return Response(ReviewSerializer(review).data, status=status.HTTP_201_CREATED)


@api_view(["POST"])
def undo_review(request: Request, review_id: int) -> Response:
    try:
        review = services.undo_review(request.user, review_id)
    except services.ReviewNotFound:
        raise NotFound("Review inesistente.")
    except services.ReviewAlreadyUndone:
        raise Conflict("Questa risposta è già stata annullata.")
    return Response(ReviewSerializer(review).data)


@api_view(["GET"])
def stats(request: Request) -> Response:
    return Response(StatsSerializer(services.stats(request.user)).data)


ACTIVE_TEMPORARY_DECKS = 20


@api_view(["GET"])
def temporary_deck_list(request: Request) -> Response:
    decks = services.list_temporary_decks(request.user, ACTIVE_TEMPORARY_DECKS, active_only=True)
    return Response({"temporary_decks": TemporaryDeckSerializer(decks, many=True).data})


@api_view(["DELETE"])
def temporary_deck_detail(request: Request, deck_id: int) -> Response:
    try:
        services.delete_temporary_deck(request.user, deck_id)
    except services.TemporaryDeckNotFound:
        raise NotFound("Mazzo provvisorio inesistente.")
    return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(["GET", "POST"])
def session_list(request: Request) -> Response:
    if request.method == "GET":
        return Response({"sessions": SessionSerializer(sessions.recent_sessions(request.user), many=True).data})
    payload = SessionInputSerializer(data=request.data)
    payload.is_valid(raise_exception=True)
    data = payload.validated_data
    try:
        session, created = sessions.save_session(
            request.user,
            client_id=data["client_id"],
            review_ids=data["review_ids"],
            deck_slug=data.get("deck"),
            note_title=data.get("note"),
            temporary_deck_id=data.get("temporary_deck"),
        )
    except sessions.EmptySession:
        raise ValidationError({"review_ids": "Nessuna risposta valida: una sessione senza risposte non si salva."})
    return Response(SessionSerializer(session).data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
