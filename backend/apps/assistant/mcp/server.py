from typing import Annotated, Any, Literal

from django.conf import settings
from django.contrib.auth import get_user_model
from django.db import close_old_connections, connections
from mcp.server import MCPServer
from mcp.server.auth.middleware.auth_context import get_access_token
from mcp.server.auth.settings import AuthSettings
from mcp.server.mcpserver.exceptions import ToolError
from mcp.server.transport_security import TransportSecuritySettings
from mcp.types import ToolAnnotations
from pydantic import Field
from starlette.applications import Starlette
from starlette.requests import Request
from starlette.responses import JSONResponse

from apps.assistant.mcp import tools
from apps.assistant.mcp.auth import StaticTokenVerifier
from apps.study.services.temporary_decks import DEFAULT_COUNT, MAX_COUNT, MAX_DAYS

INSTRUCTIONS = (
    "Strumenti di FlashCardApp, l'app con cui l'utente ripassa le flashcard del suo vault Obsidian. "
    "Servono a preparare mazzi provvisori da ripassare nell'app: non modificano mai le flashcard."
)

READ_ONLY = ToolAnnotations(read_only_hint=True, open_world_hint=False)


def current_user():
    token = get_access_token()
    user = None
    if token is not None and token.subject:
        user = get_user_model().objects.filter(username=token.subject, is_active=True).first()
    if user is None:
        raise ToolError("Utente non autenticato o inesistente: controlla MCP_TOKEN e MCP_USERNAME sul server.")
    return user


def _call(tool, **kwargs) -> dict:
    close_old_connections()
    try:
        return tool(current_user(), **kwargs)
    finally:
        connections.close_all()


def build_server() -> MCPServer:
    server = MCPServer(
        name="flashcardapp",
        title="FlashCardApp",
        instructions=INSTRUCTIONS,
        token_verifier=StaticTokenVerifier(),
        auth=AuthSettings(
            issuer_url=settings.MCP_ISSUER_URL,
            resource_server_url=settings.MCP_PUBLIC_URL,
            validate_token_resource=True,
        ),
    )

    @server.tool(name="flashcards_find_topics",
        description='Trova gli argomenti (note) che hanno flashcard.\n- Senza `query`: elenca tutte le note, raggruppate per mazzo, con il numero di card, quante sono mai viste\n  e le prime domande di ogni nota (per capire di cosa parla anche quando il titolo è poco chiaro).\n- Con `query`: per ogni argomento le note più vicine **per significato** (ricerca semantica sul contenuto\n  delle card), con una similarità da 0 a 1. Usala quando l\'argomento non compare nei titoli\n  ("consenso" → Raft) o quando le note sono tante.\nUsalo per trovare i titoli esatti delle note che l\'utente nomina. Se più note corrispondono, chiedi\nall\'utente quale; se nessuna, diglielo e proponi le più simili.', title="Trova argomenti", annotations=READ_ONLY, structured_output=True)
    def find_topics(
        query: Annotated[
            list[str] | None,
            Field(description="Argomenti da cercare per significato, uno per elemento (es. [\"consenso\", \"replica\"])."),
        ] = None,
    ) -> dict[str, Any]:
        return _call(tools.find_topics, query=query)

    @server.tool(
        name="flashcards_preview_temporary_deck",
        description='Prepara l\'anteprima di un mazzo provvisorio di flashcard, da ripassare nell\'app FlashCardApp, senza\ncrearlo. Usalo quando l\'utente vuole ripassare degli argomenti o le card che ha sbagliato.\n\nPrima di chiamarlo:\n- se l\'utente nomina degli argomenti, usa flashcards_find_topics e passa in `notes` i titoli esatti;\n- se si riferisce a un ripasso precedente ("quelle di prima", "il mazzo di ieri") e l\'id del mazzo non è\n  nella conversazione, usa flashcards_list_temporary_decks.\n\nTutti i parametri sono facoltativi e si combinano (es. notes + missed_in_days + order="worst_first" =\n"le sbagliate di quelle note negli ultimi giorni, dalla peggiore").\n- about: per "le card che parlano di X" quando X è un concetto e non una nota intera.\n- count: se l\'utente non dice quante card, non passarlo. Le card si dividono in parti uguali tra le note.\n- order="worst_first" quando l\'utente vuole prima quelle che sbaglia di più.\n\nMostra all\'utente la composizione (`by_note`) e ogni voce di `adjustments` (card che non bastano, note\ninesistenti). Se chiede modifiche, richiama questo tool con i parametri nuovi. Quando conferma, chiama\nflashcards_create_temporary_deck con il `draft_id`, che vale 30 minuti.\nNon modifica le flashcard del vault e non ne genera di nuove.', title="Anteprima mazzo provvisorio", annotations=READ_ONLY, structured_output=True
    )
    def preview_temporary_deck(
        notes: Annotated[list[str] | None, Field(description="Titoli esatti delle note, da flashcards_find_topics.")] = None,
        count: Annotated[int | None, Field(ge=1, le=MAX_COUNT, description=f"Quante card. Default {DEFAULT_COUNT}.")] = None,
        modified: Annotated[Literal["today"] | None, Field(description="Solo note modificate oggi.")] = None,
        missed_in_days: Annotated[
            int | None, Field(ge=1, le=MAX_DAYS, description="Solo card sbagliate almeno una volta negli ultimi N giorni.")
        ] = None,
        missed_in_deck: Annotated[
            int | None, Field(description="Id di un mazzo provvisorio: solo le card sbagliate lì dopo la sua creazione.")
        ] = None,
        about: Annotated[
            str | None,
            Field(
                max_length=200,
                description="Solo card che parlano di questo, per significato e in qualsiasi nota (es. \"fencing token\").",
            ),
        ] = None,
        order: Annotated[
            Literal["least_recent", "worst_first"],
            Field(description="least_recent: mai viste e viste meno di recente. worst_first: prima le più sbagliate."),
        ] = "least_recent",
        name: Annotated[str | None, Field(max_length=200, description="Nome del mazzo. Se manca lo sceglie il server.")] = None,
    ) -> dict[str, Any]:
        return _call(
            tools.preview_temporary_deck,
            notes=notes,
            count=count,
            modified=modified,
            missed_in_days=missed_in_days,
            missed_in_deck=missed_in_deck,
            about=about,
            order=order,
            name=name,
        )

    @server.tool(
        name="flashcards_create_temporary_deck",
        description="Crea il mazzo provvisorio dell'anteprima, con esattamente le card mostrate all'utente: lo ritrova\nnell'app FlashCardApp fino a mezzanotte. Chiamalo solo dopo che l'utente ha confermato l'anteprima.\nRichiamarlo con lo stesso draft_id restituisce lo stesso mazzo, non ne crea un secondo.\nRiferisci all'utente ogni voce di `adjustments`.",
        title="Crea mazzo provvisorio",
        annotations=ToolAnnotations(
            read_only_hint=False, destructive_hint=False, idempotent_hint=True, open_world_hint=False
        ),
        structured_output=True,
    )
    def create_temporary_deck(
        draft_id: Annotated[int, Field(description="Il draft_id restituito da flashcards_preview_temporary_deck.")],
        name: Annotated[str | None, Field(max_length=200, description="Nome del mazzo, se l'utente lo cambia.")] = None,
    ) -> dict[str, Any]:
        return _call(tools.create_temporary_deck, draft_id=draft_id, name=name)

    @server.tool(
        name="flashcards_list_temporary_decks",
        description="Elenca i mazzi provvisori più recenti dell'utente, dal più nuovo, anche quelli scaduti, con quante\ncard ha fatto e quante ne ha sbagliate.\nUsalo quando l'utente si riferisce a un ripasso precedente e l'id del mazzo non è nella conversazione.\nSe più mazzi possono essere quello giusto, chiedi all'utente quale.", title="Elenca mazzi provvisori", annotations=READ_ONLY, structured_output=True
    )
    def list_temporary_decks(limit: Annotated[int, Field(ge=1, le=20)] = 5) -> dict[str, Any]:
        return _call(tools.list_temporary_decks, limit=limit)

    @server.custom_route("/health", methods=["GET"])
    async def health(request: Request) -> JSONResponse:
        return JSONResponse({"status": "ok"})

    return server


def build_app() -> Starlette:
    return build_server().streamable_http_app(
        stateless_http=True,
        json_response=True,
        transport_security=TransportSecuritySettings(
            enable_dns_rebinding_protection=True, allowed_hosts=settings.MCP_ALLOWED_HOSTS
        ),
    )
