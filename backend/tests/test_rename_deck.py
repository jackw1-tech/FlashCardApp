import pytest

from tests.conftest import decks, next_card


@pytest.fixture
def ddia(vault):
    vault.note("Replica", "Leader?::Accetta le scritture", deck="ddia")
    vault.import_()


def rename(api, slug: str, payload: dict):
    return api.patch(f"/api/decks/{slug}/", payload, format="json")


def test_il_nuovo_nome_compare_nella_lista_e_nelle_card(api, ddia):
    response = rename(api, "ddia", {"name": "Designing Data-Intensive Applications"})

    assert response.status_code == 200
    assert response.json() == {"slug": "ddia", "name": "Designing Data-Intensive Applications"}
    assert decks(api)["ddia"]["name"] == "Designing Data-Intensive Applications"
    assert next_card(api)["deck"]["name"] == "Designing Data-Intensive Applications"


def test_gli_spazi_ai_bordi_vengono_tolti(api, ddia):
    assert rename(api, "ddia", {"name": "  DDIA  "}).json()["name"] == "DDIA"


@pytest.mark.parametrize("payload", [{"name": ""}, {"name": "   "}, {"name": "x" * 201}, {}])
def test_un_nome_non_valido_risponde_400_e_non_cambia_nulla(api, ddia, payload):
    assert rename(api, "ddia", payload).status_code == 400
    assert decks(api)["ddia"]["name"] == "ddia"


def test_lo_slug_non_si_puo_cambiare(api, ddia):
    rename(api, "ddia", {"name": "DDIA", "slug": "altro"})

    assert decks(api)["ddia"]["name"] == "DDIA"


def test_un_mazzo_inesistente_risponde_404(api, ddia):
    assert rename(api, "boh", {"name": "Boh"}).status_code == 404


def test_rinominare_richiede_il_token(anon, ddia):
    assert rename(anon, "ddia", {"name": "DDIA"}).status_code == 401


def test_il_nome_scelto_dall_app_sopravvive_al_re_import(api, vault, ddia):
    rename(api, "ddia", {"name": "DDIA"})

    vault.import_()

    assert decks(api)["ddia"]["name"] == "DDIA"
