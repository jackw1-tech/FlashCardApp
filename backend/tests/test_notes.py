import pytest

from tests.conftest import all_cards, next_card, review


@pytest.fixture
def ddia(vault):
    vault.note("Replica", "A?::1\nB?::2", deck="ddia")
    vault.note("Partizioni", "C?::3", deck="ddia")
    vault.note("Altro", "D?::4", deck="x")
    vault.import_()


def notes(api, slug: str):
    return api.get(f"/api/decks/{slug}/notes/")


def test_le_note_di_un_mazzo_con_card_e_mai_viste(api, ddia):
    review(api, next_card(api, "ddia", note="Replica")["id"])

    response = notes(api, "ddia")

    assert response.status_code == 200
    assert response.json()["notes"] == [
        {"title": "Partizioni", "total_cards": 1, "unseen_cards": 1},
        {"title": "Replica", "total_cards": 2, "unseen_cards": 1},
    ]


def test_il_filtro_per_nota_propone_solo_le_card_di_quella_nota(api, ddia):
    assert {c["front"] for c in all_cards(api, "ddia", note="Replica")} == {"A?", "B?"}


def test_una_nota_inesistente_non_ha_card(api, ddia):
    assert next_card(api, "ddia", note="Boh") is None


def test_le_note_senza_card_attive_spariscono(api, vault, ddia):
    vault.remove("Partizioni")
    vault.import_()

    assert [n["title"] for n in notes(api, "ddia").json()["notes"]] == ["Replica"]


def test_le_note_di_un_mazzo_inesistente_rispondono_404(api, ddia):
    assert notes(api, "boh").status_code == 404


def test_le_note_richiedono_il_token(anon, ddia):
    assert notes(anon, "ddia").status_code == 401
