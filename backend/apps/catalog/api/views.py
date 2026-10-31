from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.exceptions import NotFound
from rest_framework.permissions import IsAdminUser
from rest_framework.decorators import permission_classes
from rest_framework.request import Request
from rest_framework.response import Response

from apps.catalog.api.serializers import (
    CardSerializer,
    DeckRenameSerializer,
    DeckSerializer,
    ReportInputSerializer,
    ReportSerializer,
    SearchQuerySerializer,
)
from apps.catalog.services import decks, reports, search
from apps.catalog.services import vault_sync
from apps.catalog.services.importer import ImportAborted
from apps.catalog.services.vault_git import VaultSyncError


@api_view(["PATCH"])
def rename_deck(request: Request, slug: str) -> Response:
    payload = DeckRenameSerializer(data=request.data)
    payload.is_valid(raise_exception=True)
    try:
        deck = decks.rename_deck(slug, payload.validated_data["name"])
    except decks.DeckNotFound:
        raise NotFound("Mazzo inesistente.")
    return Response(DeckSerializer(deck).data)


@api_view(["GET"])
def search_cards(request: Request) -> Response:
    query = SearchQuerySerializer(data=request.query_params)
    query.is_valid(raise_exception=True)
    results = search.search_cards(query.validated_data["q"], query.validated_data.get("deck"))
    return Response({"results": CardSerializer(results, many=True).data})


@api_view(["POST"])
def report_card(request: Request, card_id: int) -> Response:
    payload = ReportInputSerializer(data=request.data)
    payload.is_valid(raise_exception=True)
    try:
        report = reports.report_card(request.user, card_id, **payload.validated_data)
    except reports.CardNotFound:
        raise NotFound("Card inesistente o archiviata.")
    return Response(ReportSerializer(report).data, status=status.HTTP_201_CREATED)


@api_view(["GET"])
def open_reports(request: Request) -> Response:
    return Response({"reports": ReportSerializer(reports.open_reports(request.user), many=True).data})


@api_view(["POST"])
def resolve_report(request: Request, report_id: int) -> Response:
    try:
        report = reports.resolve_report(request.user, report_id)
    except reports.ReportNotFound:
        raise NotFound("Segnalazione inesistente.")
    return Response(ReportSerializer(report).data)


@api_view(["POST"])
@permission_classes([IsAdminUser])
def sync_vault(request: Request) -> Response:
    try:
        result = vault_sync.sync_vault(embed=True)
    except vault_sync.VaultSyncInProgress:
        return Response({"detail": "Una sincronizzazione è già in corso."}, status=status.HTTP_409_CONFLICT)
    except vault_sync.VaultNotConfigured:
        return Response({"detail": "Il Vault Git non è configurato sul server."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
    except ImportAborted as exc:
        return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
    except VaultSyncError as exc:
        return Response({"detail": str(exc)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    imported = result.imported
    return Response(
        {
            "status": "partial" if result.embedding_error else "completed",
            "branch": result.branch,
            "commit": result.commit,
            "notes": imported.notes,
            "cards": imported.cards,
            "created": imported.created,
            "updated": imported.updated,
            "archived": imported.archived,
            "restored": imported.restored,
            "problems": len(imported.problems),
            "embeddings": result.embeddings.embedded,
            "embeddings_up_to_date": result.embeddings.up_to_date,
            "embedding_error": result.embedding_error,
        },
        status=status.HTTP_207_MULTI_STATUS if result.embedding_error else status.HTTP_200_OK,
    )
