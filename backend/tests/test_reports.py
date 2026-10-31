import pytest

from tests.conftest import next_card


@pytest.fixture
def card(vault, api):
    vault.note("Replica", "Leader?::Accetta le scritture", deck="ddia")
    vault.import_()
    return next_card(api)


def report(api, card_id: int, payload: dict):
    return api.post(f"/api/cards/{card_id}/reports/", payload, format="json")


def open_reports(api) -> list[dict]:
    response = api.get("/api/reports/")
    assert response.status_code == 200
    return response.json()["reports"]


def test_una_segnalazione_compare_nella_lista_con_la_card(api, card):
    response = report(api, card["id"], {"reason": "wrong_answer", "comment": "manca il follower"})

    assert response.status_code == 201
    [item] = open_reports(api)
    assert item["reason"] == "wrong_answer"
    assert item["comment"] == "manca il follower"
    assert item["card"]["front"] == "Leader?"
    assert item["card"]["note_title"] == "Replica"
    assert item["card"]["deck"] == {"slug": "ddia", "name": "ddia"}


def test_il_commento_e_facoltativo(api, card):
    assert report(api, card["id"], {"reason": "bad_format"}).status_code == 201


def test_un_motivo_non_valido_risponde_400(api, card):
    assert report(api, card["id"], {"reason": "boh"}).status_code == 400
    assert open_reports(api) == []


def test_una_card_inesistente_risponde_404(api, card):
    assert report(api, 999_999, {"reason": "other"}).status_code == 404


def test_risolvere_toglie_la_segnalazione_dalla_lista(api, card):
    created = report(api, card["id"], {"reason": "other"}).json()

    response = api.post(f"/api/reports/{created['id']}/resolve/")

    assert response.status_code == 200
    assert open_reports(api) == []
    assert api.post(f"/api/reports/{created['id']}/resolve/").status_code == 200


def test_risolvere_una_segnalazione_inesistente_risponde_404(api, card):
    assert api.post("/api/reports/999999/resolve/").status_code == 404


def test_le_segnalazioni_richiedono_il_token(anon, card):
    assert report(anon, card["id"], {"reason": "other"}).status_code == 401
    assert anon.get("/api/reports/").status_code == 401
