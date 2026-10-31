import asyncio
import json
from datetime import timedelta
from types import SimpleNamespace

import jwt
import pytest
from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils import timezone
from mcp import Client
from mcp.server.mcpserver.exceptions import ToolError

from apps.assistant.mcp import server, tools
from apps.assistant.mcp.auth import StaticTokenVerifier, issue_token
from apps.assistant.models import Conversation, ConversationStatus
from apps.assistant.services import chat
from apps.assistant.services.mcp_gateway import GatewayError, McpGateway, ToolOutcome, ToolSpec
from apps.study.models import TemporaryDeck

READ_ONLY = {"flashcards_find_topics", "flashcards_preview_temporary_deck", "flashcards_list_temporary_decks"}


class FakeGateway:

    def __init__(self, user, *, down: bool = False):
        self.user = user
        self.down = down
        self.calls: list[str] = []

    def list_tools(self) -> list[ToolSpec]:
        if self.down:
            raise GatewayError("giù")
        names = [*sorted(READ_ONLY), "flashcards_create_temporary_deck"]
        return [ToolSpec(n, n, f"tool {n}", {"type": "object"}, n not in READ_ONLY) for n in names]

    def call_tool(self, name: str, arguments: dict) -> ToolOutcome:
        self.calls.append(name)
        handler = {
            "flashcards_find_topics": lambda: tools.find_topics(self.user),
            "flashcards_preview_temporary_deck": lambda: tools.preview_temporary_deck(self.user, **arguments),
            "flashcards_create_temporary_deck": lambda: tools.create_temporary_deck(
                self.user, arguments["draft_id"], arguments.get("name")
            ),
            "flashcards_list_temporary_decks": lambda: tools.list_temporary_decks(self.user, 5),
        }[name]
        try:
            return ToolOutcome(json.dumps(handler()), False)
        except ToolError as exc:
            return ToolOutcome(str(exc), True)


class FakeClaude:

    def __init__(self, *script):
        self.script = list(script)
        self.requests: list[list[dict]] = []

    def create(self, tools, messages):
        self.requests.append(json.loads(json.dumps(messages)))
        step = self.script.pop(0)
        content, stop_reason = step(messages) if callable(step) else step
        return SimpleNamespace(content=content, stop_reason=stop_reason)


def text(value: str):
    return [{"type": "text", "text": value}], "end_turn"


def tool_use(name: str, arguments: dict | None = None, *, say: str | None = None, id_: str = "toolu_1"):
    content = [{"type": "text", "text": say}] if say else []
    content.append({"type": "tool_use", "id": id_, "name": name, "input": arguments or {}})
    return content, "tool_use"


def create_from_last_preview(messages):
    result = json.loads(messages[-1]["content"][0]["content"])
    return tool_use(
        "flashcards_create_temporary_deck", {"draft_id": result["draft_id"]}, say="Ecco l'anteprima.", id_="toolu_2"
    )


@pytest.fixture
def notes(vault):
    vault.note("MCP", "Cosa significa MCP?::Model Context Protocol\nChi esegue i tool?::L'harness\nTerza?::sì")
    vault.note("Raft", "Cos'è un leader?::Il nodo che coordina\nCos'è un termine?::Un'epoca")
    vault.import_()


@pytest.fixture
def conversation(user):
    return chat.start_conversation(user)


def run(user, conversation, text_: str, claude, gateway=None):
    return chat.send_message(user, conversation.pk, text_, claude=claude, gateway=gateway or FakeGateway(user))


def deck_preview(user, conversation, claude=None):
    claude = claude or FakeClaude(
        tool_use("flashcards_preview_temporary_deck", {"notes": ["MCP", "Raft"], "count": 4}), create_from_last_preview
    )
    return run(user, conversation, "oggi ripasso MCP e Raft", claude)


def test_una_risposta_di_solo_testo(user, conversation):
    result = run(user, conversation, "ciao", FakeClaude(text("Ciao! Cosa ripassiamo?")))

    assert result.status == ConversationStatus.IDLE
    assert result.title == "ciao"
    assert [m.role for m in result.messages.all()] == ["user", "assistant"]


def test_i_tool_di_lettura_si_eseguono_da_soli_e_il_risultato_torna_al_modello(user, conversation, notes):
    claude = FakeClaude(tool_use("flashcards_find_topics"), text("Hai MCP e Raft."))
    gateway = FakeGateway(user)

    run(user, conversation, "che argomenti ho?", claude, gateway)

    assert gateway.calls == ["flashcards_find_topics"]
    tool_result = claude.requests[1][-1]["content"][0]
    assert tool_result["tool_use_id"] == "toolu_1"
    assert {n["title"] for n in json.loads(tool_result["content"])["decks"][0]["notes"]} == {"MCP", "Raft"}


def test_la_storia_si_rimanda_identica_e_cresce_solo_in_coda(user, conversation, notes):
    claude = FakeClaude(tool_use("flashcards_find_topics"), text("Hai MCP e Raft."), text("Prego."))
    run(user, conversation, "che argomenti ho?", claude)
    run(user, conversation, "grazie", claude)

    for before, after in zip(claude.requests, claude.requests[1:]):
        assert after[: len(before)] == before


def test_creare_un_mazzo_si_ferma_in_attesa_di_conferma_con_l_anteprima(user, conversation, notes):
    result = deck_preview(user, conversation)

    assert result.status == ConversationStatus.WAITING_CONFIRMATION
    assert not TemporaryDeck.objects.exists()
    pending = chat_view(result)["pending"]
    assert pending["deck"]["total"] == 4
    assert pending["deck"]["by_note"] == [{"note": "MCP", "taken": 2}, {"note": "Raft", "taken": 2}]


def test_confermando_il_mazzo_viene_creato_e_il_modello_continua(user, conversation, notes):
    deck_preview(user, conversation)

    result = chat.confirm(user, conversation.pk, True, claude=FakeClaude(text("Fatto!")), gateway=FakeGateway(user))

    assert result.status == ConversationStatus.IDLE
    deck = TemporaryDeck.objects.get()
    created = [i for i in chat_view(result)["items"] if i["kind"] == "deck_created"]
    assert created == [{"kind": "deck_created", "text": deck.name, "temporary_deck_id": deck.pk, "total": 4}]


def test_rifiutando_non_si_crea_niente_e_il_modello_lo_sa(user, conversation, notes):
    deck_preview(user, conversation)
    claude = FakeClaude(text("Cosa vuoi cambiare?"))

    chat.confirm(user, conversation.pk, False, claude=claude, gateway=FakeGateway(user))

    assert not TemporaryDeck.objects.exists()
    rejection = claude.requests[0][-1]["content"][0]
    assert rejection["is_error"] is True and rejection["content"] == chat.REJECTED


def test_mentre_aspetta_una_conferma_non_accetta_messaggi(user, conversation, notes):
    deck_preview(user, conversation)

    with pytest.raises(chat.ConversationBusy):
        run(user, conversation, "e invece?", FakeClaude(text("no")))


def test_se_il_server_mcp_e_giu_alla_conferma_la_richiesta_resta_in_piedi(user, conversation, notes):
    deck_preview(user, conversation)

    with pytest.raises(chat.ChatError, match="server MCP"):
        chat.confirm(user, conversation.pk, True, claude=FakeClaude(), gateway=FakeGateway(user, down=True))

    assert Conversation.objects.get().status == ConversationStatus.WAITING_CONFIRMATION


def test_un_rifiuto_del_modello_e_un_errore_ma_la_conversazione_resta_usabile(user, conversation):
    with pytest.raises(chat.ChatError, match="rifiutato"):
        run(user, conversation, "boh", FakeClaude(([], "refusal")))

    assert Conversation.objects.get().status == ConversationStatus.IDLE
    assert [m.role for m in Conversation.objects.get().messages.all()] == ["user"]


def test_un_ciclo_che_non_finisce_si_ferma(user, conversation, notes):
    script = [tool_use("flashcards_find_topics", id_=f"toolu_{i}") for i in range(chat.MAX_STEPS)]

    with pytest.raises(chat.ChatError, match="troppi passi"):
        run(user, conversation, "vai", FakeClaude(*script))


def chat_view(conversation) -> dict:
    from apps.assistant.services import transcript

    return transcript.render(conversation)


def test_api_crea_elenca_mostra_e_cancella_le_conversazioni(api):
    created = api.post("/api/conversations/").json()

    assert api.get("/api/conversations/").json()["conversations"][0]["id"] == created["id"]
    assert api.get(f"/api/conversations/{created['id']}/").json()["items"] == []
    assert api.delete(f"/api/conversations/{created['id']}/").status_code == 204
    assert api.get(f"/api/conversations/{created['id']}/").status_code == 404


def test_api_la_conversazione_di_un_altro_utente_non_esiste(api):
    other = chat.start_conversation(get_user_model().objects.create_user("altro"))

    assert api.get(f"/api/conversations/{other.pk}/").status_code == 404


def test_api_un_errore_del_turno_torna_nella_conversazione(api, monkeypatch, user):
    monkeypatch.setattr(chat, "ClaudeClient", lambda: FakeClaude(([], "refusal")))
    monkeypatch.setattr(chat, "McpGateway", FakeGateway)
    conversation_id = api.post("/api/conversations/").json()["id"]

    response = api.post(f"/api/conversations/{conversation_id}/messages/", {"text": "boh"}, format="json")

    assert response.status_code == 200
    assert "rifiutato" in response.json()["error"]
    assert response.json()["items"] == [{"kind": "user", "text": "boh"}]


def test_api_conferma_quando_non_c_e_niente_da_confermare_e_409(api):
    conversation_id = api.post("/api/conversations/").json()["id"]

    response = api.post(f"/api/conversations/{conversation_id}/confirmation/", {"approve": True}, format="json")

    assert response.status_code == 409


def verify(token: str):
    return asyncio.run(StaticTokenVerifier().verify_token(token))


def test_il_token_della_chat_vale_per_il_suo_utente(user, settings):
    settings.MCP_TOKEN = "statico"

    assert verify(issue_token(user)).subject == user.username


def test_un_token_per_un_altro_server_o_scaduto_viene_rifiutato(user):
    now = timezone.now()
    base = {"sub": user.username, "typ": "mcp", "iat": now, "exp": now + timedelta(minutes=5)}
    other_audience = jwt.encode({**base, "aud": "https://altro/mcp"}, settings.JWT_SIGNING_KEY, algorithm="HS256")
    expired = jwt.encode(
        {**base, "aud": settings.MCP_PUBLIC_URL, "exp": now - timedelta(seconds=1)}, settings.JWT_SIGNING_KEY, algorithm="HS256"
    )

    assert verify(other_audience) is None
    assert verify(expired) is None


def test_un_jwt_dell_accesso_all_app_non_vale_per_il_server_mcp(user):
    app_token = jwt.encode({"sub": user.username, "aud": settings.MCP_PUBLIC_URL}, settings.JWT_SIGNING_KEY, algorithm="HS256")

    assert verify(app_token) is None


@pytest.mark.django_db(transaction=True)
def test_il_gateway_chiede_conferma_solo_per_i_tool_che_scrivono(monkeypatch):
    user = get_user_model().objects.create_user("giacomo")

    class InProcessGateway(McpGateway):
        def _run(self, operation):
            async def go():
                async with Client(server.build_server()) as client:
                    return await operation(client)

            return asyncio.run(go())

    specs = InProcessGateway(user).list_tools()

    assert [s.name for s in specs if s.needs_confirmation] == ["flashcards_create_temporary_deck"]
    assert all(s.input_schema["type"] == "object" for s in specs)
