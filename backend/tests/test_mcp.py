import pytest
from mcp import Client
from mcp.server.mcpserver.exceptions import ToolError

from apps.assistant.mcp import server, tools
from apps.assistant.mcp.auth import StaticTokenVerifier
from apps.study.models import TemporaryDeck
from tests.conftest import review


@pytest.fixture
def notes(vault):
    vault.note("MCP", "Cosa significa MCP?::Model Context Protocol\nChi esegue i tool?::L'harness\nTerza?::sì")
    vault.note("REST o gRPC", "Quando gRPC?::Tra servizi\nQuando REST?::Ai bordi")
    vault.import_()


@pytest.fixture
def anyio_backend():
    return "asyncio"


def test_find_topics_da_titoli_conteggi_e_le_prime_domande(user, notes):
    [deck] = tools.find_topics(user)["decks"]

    mcp_note = next(n for n in deck["notes"] if n["title"] == "MCP")
    assert mcp_note == {
        "title": "MCP",
        "cards": 3,
        "unseen": 3,
        "sample_questions": ["Cosa significa MCP?", "Chi esegue i tool?"],
    }


def test_l_anteprima_mostra_composizione_e_avvisi_senza_creare_il_mazzo(user, notes):
    preview = tools.preview_temporary_deck(user, notes=["MCP", "grpc"], count=2)

    assert preview["total"] == 2
    assert preview["by_note"] == [{"note": "MCP", "taken": 2, "available": 3}]
    assert preview["adjustments"] == ['Nota "grpc" non trovata. Simili: "REST o gRPC".']
    assert not TemporaryDeck.objects.exists()


def test_la_conferma_crea_il_mazzo_dell_anteprima(user, notes):
    preview = tools.preview_temporary_deck(user, notes=["MCP", "grpc"], count=2)

    created = tools.create_temporary_deck(user, preview["draft_id"], None)

    assert (created["name"], created["total"], created["adjustments"]) == ("MCP", 2, preview["adjustments"])
    assert TemporaryDeck.objects.get(pk=created["temporary_deck_id"]).entries.count() == 2


def test_l_anteprima_senza_card_e_un_errore_che_dice_la_causa(user, notes):
    with pytest.raises(ToolError, match="Nessun mazzo creato. Negli ultimi 7 giorni .* non ha ripassato"):
        tools.preview_temporary_deck(user, missed_in_days=7)


def test_un_mazzo_sorgente_inesistente_dice_quale_tool_usare(user, notes):
    with pytest.raises(ToolError, match="flashcards_list_temporary_decks"):
        tools.preview_temporary_deck(user, missed_in_deck=999)


def test_una_bozza_inesistente_dice_di_rifare_l_anteprima(user, notes):
    with pytest.raises(ToolError, match="Rifai flashcards_preview_temporary_deck"):
        tools.create_temporary_deck(user, 999, None)


def test_list_temporary_decks(api, user, notes):
    preview = tools.preview_temporary_deck(user, notes=["REST o gRPC"])
    created = tools.create_temporary_deck(user, preview["draft_id"], None)
    review(api, TemporaryDeck.objects.get().entries.first().card_id, "didnt_know")

    [deck] = tools.list_temporary_decks(user, limit=5)["temporary_decks"]

    assert (deck["id"], deck["total"], deck["done"], deck["missed"]) == (created["temporary_deck_id"], 2, 1, 1)


@pytest.mark.anyio
async def test_il_token_giusto_vale_per_l_utente_configurato(settings):
    settings.MCP_TOKEN, settings.MCP_USERNAME = "segreto", "giacomo"

    access = await StaticTokenVerifier().verify_token("segreto")

    assert access.subject == "giacomo"
    assert await StaticTokenVerifier().verify_token("sbagliato") is None


@pytest.mark.anyio
async def test_senza_token_configurato_nessun_token_vale(settings):
    settings.MCP_TOKEN = ""

    assert await StaticTokenVerifier().verify_token("") is None


@pytest.fixture
def as_user(monkeypatch, user):
    monkeypatch.setattr(server, "current_user", lambda: user)


@pytest.mark.anyio
async def test_tools_list_espone_il_contratto(settings):
    async with Client(server.build_server()) as client:
        listed = {tool.name: tool for tool in (await client.list_tools()).tools}

    assert set(listed) == {
        "flashcards_find_topics",
        "flashcards_preview_temporary_deck",
        "flashcards_create_temporary_deck",
        "flashcards_list_temporary_decks",
    }
    create = listed["flashcards_create_temporary_deck"].annotations
    assert (create.read_only_hint, create.destructive_hint, create.idempotent_hint) == (False, False, True)
    preview = listed["flashcards_preview_temporary_deck"]
    assert preview.annotations.read_only_hint is True
    assert "flashcards_find_topics" in preview.description
    assert listed["flashcards_create_temporary_deck"].input_schema["required"] == ["draft_id"]
    schema = preview.input_schema["properties"]
    assert schema["count"]["anyOf"][0]["maximum"] == 200
    assert "worst_first" in str(schema["order"])


@pytest.mark.anyio
@pytest.mark.django_db(transaction=True)
async def test_anteprima_e_conferma_attraverso_il_protocollo(as_user, notes):
    async with Client(server.build_server()) as client:
        preview = await client.call_tool("flashcards_preview_temporary_deck", {"notes": ["MCP"], "count": 2})
        draft_id = preview.structured_content["draft_id"]
        created = await client.call_tool("flashcards_create_temporary_deck", {"draft_id": draft_id})
        again = await client.call_tool("flashcards_create_temporary_deck", {"draft_id": draft_id})

    assert created.is_error is False
    assert created.structured_content["total"] == 2
    assert again.structured_content["temporary_deck_id"] == created.structured_content["temporary_deck_id"]


@pytest.mark.anyio
@pytest.mark.django_db(transaction=True)
async def test_un_errore_del_tool_arriva_al_modello_come_is_error(as_user, notes):
    async with Client(server.build_server()) as client:
        result = await client.call_tool("flashcards_preview_temporary_deck", {"notes": ["Kubernetes"]})

    assert result.is_error is True
    assert "Nessuna delle note richieste esiste" in result.content[0].text


@pytest.mark.anyio
async def test_un_parametro_fuori_schema_viene_rifiutato_prima_del_tool(as_user):
    async with Client(server.build_server()) as client:
        result = await client.call_tool("flashcards_preview_temporary_deck", {"order": "peggiori"})

    assert result.is_error is True
