import pytest


@pytest.fixture
def cards(vault):
    vault.note("Replica", "Cos'è il leader?::Il nodo che accetta le scritture\nCos'è un follower?::Una replica", deck="ddia")
    vault.note("Liste", "Cosa fa `::`?::Prepend in testa", deck="scala")
    vault.import_()


def search(api, q: str, deck: str | None = None) -> list[dict]:
    params = {"q": q, **({"deck": deck} if deck else {})}
    response = api.get("/api/cards/search/", params)
    assert response.status_code == 200
    return response.json()["results"]


def test_cerca_in_domanda_e_risposta_senza_maiuscole(api, cards):
    assert [c["front"] for c in search(api, "LEADER")] == ["Cos'è il leader?"]
    assert [c["front"] for c in search(api, "scritture")] == ["Cos'è il leader?"]


def test_cerca_anche_nel_titolo_della_nota(api, cards):
    assert len(search(api, "replica")) == 2


def test_il_filtro_per_mazzo(api, cards):
    assert search(api, "cos", deck="scala")[0]["deck"] == {"slug": "scala", "name": "scala"}
    assert len(search(api, "cos", deck="scala")) == 1


def test_le_card_archiviate_non_compaiono(api, vault, cards):
    vault.remove("Liste")
    vault.import_()

    assert search(api, "prepend") == []


def test_una_ricerca_troppo_corta_non_restituisce_nulla(api, cards):
    assert search(api, "c") == []


def test_i_risultati_hanno_il_retro(api, cards):
    [card] = search(api, "follower")

    assert card["back"] == "Una replica"


def test_cercare_richiede_il_token(anon, cards):
    assert anon.get("/api/cards/search/", {"q": "leader"}).status_code == 401
