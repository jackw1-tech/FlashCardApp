import hashlib
import io
import json
import math
import re
import urllib.error

import pytest
from django.core.management import call_command
from django.core.management.base import CommandError
from mcp.server.mcpserver.exceptions import ToolError

from apps.assistant.mcp import tools
from apps.catalog.models import Card, CardEmbedding
from apps.catalog.services import embeddings, semantic
from apps.study.services.temporary_decks import NoCards, preview_temporary_deck

DIMENSIONS = 1024


class FakeEmbedder:

    def __init__(self, model: str = "fake-1", synonyms: dict[str, str] | None = None):
        self.model = model
        self.synonyms = synonyms or {}
        self.calls: list[tuple[int, str]] = []

    def embed(self, texts, *, input_type):
        self.calls.append((len(texts), input_type))
        return [self._vector(text) for text in texts]

    def _vector(self, text: str) -> list[float]:
        vector = [0.0] * DIMENSIONS
        for word in re.findall(r"\w+", text.lower()):
            word = self.synonyms.get(word, word)
            vector[int(hashlib.md5(word.encode()).hexdigest(), 16) % DIMENSIONS] += 1.0
        norm = math.sqrt(sum(v * v for v in vector)) or 1.0
        return [v / norm for v in vector]


@pytest.fixture
def embedder(monkeypatch):
    fake = FakeEmbedder(synonyms={"consenso": "raft", "accordo": "raft"})
    monkeypatch.setattr(embeddings, "get_embedder", lambda: fake)
    monkeypatch.setattr(semantic, "get_embedder", lambda: fake)
    return fake


@pytest.fixture
def cards(vault):
    vault.note("Raft", "Cos'è un leader in Raft?::Il nodo che coordina\nCos'è un termine in Raft?::Un'epoca", deck="dss")
    vault.note("MCP", "Cosa significa MCP?::Model Context Protocol\nChi esegue i tool?::L'harness", deck="dss")
    vault.note("Fencing", "A cosa serve un fencing token?::A rifiutare un vecchio leader", deck="ddia")
    vault.import_()


def test_embed_cards_calcola_tutto_e_poi_niente(embedder, cards):
    first = embeddings.embed_cards(embedder)
    second = embeddings.embed_cards(embedder)

    assert (first.embedded, first.up_to_date) == (5, 0)
    assert (second.embedded, second.up_to_date) == (0, 5)
    assert all(input_type == "document" for _, input_type in embedder.calls)


def test_si_ricalcola_solo_la_card_cambiata(embedder, vault, cards):
    embeddings.embed_cards(embedder)
    vault.note("MCP", "Cosa significa MCP?::Il protocollo di Anthropic\nChi esegue i tool?::L'harness", deck="dss")
    vault.import_()

    report = embeddings.embed_cards(embedder)

    assert report.embedded == 1


def test_cambiare_modello_ricalcola_tutto(embedder, cards):
    embeddings.embed_cards(embedder)

    report = embeddings.embed_cards(FakeEmbedder(model="fake-2"))

    assert report.embedded == 5
    assert set(CardEmbedding.objects.values_list("model", flat=True)) == {"fake-2"}


def test_le_card_si_mandano_a_blocchi(embedder, cards, monkeypatch):
    monkeypatch.setattr(embeddings, "BATCH_SIZE", 2)

    embeddings.embed_cards(embedder)

    assert [size for size, _ in embedder.calls] == [2, 2, 1]


def test_i_blocchi_restano_sotto_il_tetto_di_token(embedder, cards, monkeypatch):
    monkeypatch.setattr(embeddings, "BATCH_TOKENS", 30)

    embeddings.embed_cards(embedder)

    assert len(embedder.calls) > 1
    assert sum(size for size, _ in embedder.calls) == 5


def test_su_un_429_aspetta_e_riprova_lo_stesso_blocco(embedder, cards, monkeypatch):
    waits = []
    monkeypatch.setattr(embeddings.time, "sleep", waits.append)
    real = embedder.embed
    failures = iter([embeddings.EmbeddingsRateLimited("429", retry_after=7.0)])

    def flaky(texts, *, input_type):
        if (error := next(failures, None)) is not None:
            raise error
        return real(texts, input_type=input_type)

    embedder.embed = flaky

    report = embeddings.embed_cards(embedder)

    assert waits == [7.0]
    assert report.embedded == 5


def test_le_card_nuove_non_sono_indicizzate_finche_non_si_rilancia(embedder, vault, cards):
    embeddings.embed_cards(embedder)
    vault.note("Kafka", "Cos'è una partizione?::Un log ordinato", deck="dss")
    vault.import_()

    assert semantic.missing_embeddings(embedder) == 1


def test_la_card_piu_vicina_viene_prima(embedder, cards):
    embeddings.embed_cards(embedder)

    [best, *_] = semantic.search_cards("fencing token vecchio leader", embedder=embedder)

    assert best.card.note_title == "Fencing"
    assert 0 < best.similarity <= 1


def test_le_note_si_trovano_anche_senza_la_parola_nel_titolo(embedder, cards):
    embeddings.embed_cards(embedder)

    found = semantic.search_notes(["consenso"], embedder)

    assert found["consenso"][0].title == "Raft"
    assert len({m.title for m in found["consenso"]}) == len(found["consenso"])


def test_le_card_archiviate_non_si_trovano(embedder, vault, cards):
    embeddings.embed_cards(embedder)
    vault.remove("Fencing")
    vault.import_()

    titles = {m.card.note_title for m in semantic.search_cards("fencing token", embedder=embedder)}

    assert "Fencing" not in titles


def test_about_prende_solo_le_card_che_parlano_dell_argomento(embedder, user, cards, settings):
    settings.SEMANTIC_MIN_SIMILARITY = 0.3
    embeddings.embed_cards(embedder)

    preview = preview_temporary_deck(user, about="consenso leader termine")

    chosen = set(Card.objects.filter(pk__in=preview.draft.card_ids).values_list("note_title", flat=True))
    assert chosen == {"Raft"}
    assert preview.draft.name == "Consenso leader termine"


def test_about_si_combina_con_le_note(embedder, user, cards, settings):
    settings.SEMANTIC_MIN_SIMILARITY = 0.2
    embeddings.embed_cards(embedder)

    preview = preview_temporary_deck(user, notes=["Fencing"], about="leader")

    assert set(Card.objects.filter(pk__in=preview.draft.card_ids).values_list("note_title", flat=True)) == {"Fencing"}


def test_se_niente_parla_dell_argomento_lo_dice(embedder, user, cards):
    embeddings.embed_cards(embedder)

    with pytest.raises(NoCards, match='Nessuna card parla abbastanza di "kubernetes"'):
        preview_temporary_deck(user, about="kubernetes")


def test_find_topics_con_query_restituisce_le_note_piu_vicine(embedder, user, cards):
    embeddings.embed_cards(embedder)

    result = tools.find_topics(user, query=["consenso"])

    assert result["matches"]["consenso"][0] == {
        "title": "Raft",
        "deck": "dss",
        "similarity": result["matches"]["consenso"][0]["similarity"],
    }
    assert result["cards_not_indexed"] == 0


def test_senza_chiave_find_topics_con_query_dice_di_fare_senza(user, cards, settings):
    settings.VOYAGE_API_KEY = ""

    with pytest.raises(ToolError, match="senza `query`"):
        tools.find_topics(user, query=["consenso"])


def test_senza_chiave_l_anteprima_con_about_dice_di_usare_le_note(user, cards, settings):
    settings.VOYAGE_API_KEY = ""

    with pytest.raises(ToolError, match="senza `about`"):
        tools.preview_temporary_deck(user, about="consenso")


class FakeResponse(io.BytesIO):
    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False


def test_voyage_riceve_testi_modello_e_tipo_e_l_ordine_si_rispetta(monkeypatch):
    sent = {}

    def fake_urlopen(request, timeout):
        sent["auth"] = request.headers["Authorization"]
        sent["body"] = json.loads(request.data)
        data = [{"index": 1, "embedding": [0.0, 1.0]}, {"index": 0, "embedding": [1.0, 0.0]}]
        return FakeResponse(json.dumps({"data": data}).encode())

    monkeypatch.setattr(embeddings.urllib.request, "urlopen", fake_urlopen)

    vectors = embeddings.VoyageEmbedder("chiave", "voyage-4").embed(["a", "b"], input_type="query")

    assert vectors == [[1.0, 0.0], [0.0, 1.0]]
    assert sent["auth"] == "Bearer chiave"
    assert sent["body"] == {"input": ["a", "b"], "model": "voyage-4", "input_type": "query"}


def test_un_429_di_voyage_porta_il_tempo_di_attesa(monkeypatch):
    def limited(request, timeout):
        raise urllib.error.HTTPError(embeddings.VOYAGE_URL, 429, "lento", {"Retry-After": "20"}, io.BytesIO(b"rate"))

    monkeypatch.setattr(embeddings.urllib.request, "urlopen", limited)

    with pytest.raises(embeddings.EmbeddingsRateLimited) as error:
        embeddings.VoyageEmbedder("x", "voyage-4").embed(["a"], input_type="document")

    assert error.value.retry_after == 20.0


def test_un_errore_di_voyage_diventa_embeddings_unavailable(monkeypatch):
    def fail(request, timeout):
        raise urllib.error.HTTPError(embeddings.VOYAGE_URL, 401, "no", {}, io.BytesIO(b"chiave sbagliata"))

    monkeypatch.setattr(embeddings.urllib.request, "urlopen", fail)

    with pytest.raises(embeddings.EmbeddingsUnavailable, match="401"):
        embeddings.VoyageEmbedder("x", "voyage-4").embed(["a"], input_type="document")


def test_il_comando_senza_chiave_spiega_cosa_manca(cards, settings):
    settings.VOYAGE_API_KEY = ""

    with pytest.raises(CommandError, match="VOYAGE_API_KEY"):
        call_command("embed_cards")
