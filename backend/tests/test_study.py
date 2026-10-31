import pytest

from tests.conftest import all_cards, decks, next_card, review


@pytest.fixture
def three_cards(vault):
    vault.note("Numeri", "Uno?::1\nDue?::2\nTre?::3", deck="x")
    vault.import_()


def test_le_card_mai_viste_vengono_sempre_prima(api, three_cards):
    seen_one, seen_two, unseen = all_cards(api)
    review(api, seen_one["id"])
    review(api, seen_two["id"])

    for _ in range(10):
        assert next_card(api)["id"] == unseen["id"]


def test_dopo_una_review_la_prossima_card_e_un_altra(api, three_cards):
    for _ in range(6):
        card = next_card(api)
        review(api, card["id"])
        assert next_card(api)["id"] != card["id"]


def test_tra_le_card_viste_viene_proposta_quella_vista_meno_di_recente(api, three_cards):
    first, second, third = all_cards(api)
    for card in (first, second, third):
        review(api, card["id"])

    assert next_card(api)["id"] == first["id"]


def test_il_filtro_per_mazzo(api, vault):
    vault.note("Numeri", "Uno?::1\nDue?::2", deck="x")
    vault.note("Lettere", "A?::a", deck="y")
    vault.import_()

    assert {c["deck"]["slug"] for c in all_cards(api, "y")} == {"y"}
    assert len(all_cards(api)) == 3


def test_un_mazzo_inesistente_risponde_404(api, three_cards):
    assert api.get("/api/next-card/", {"deck": "boh"}).status_code == 404


def test_gli_id_esclusi_non_tornano_mai_e_alla_fine_non_ci_sono_card(api, three_cards):
    ids = [c["id"] for c in all_cards(api)]

    assert next_card(api, exclude=ids[:2])["id"] == ids[2]
    assert next_card(api, exclude=ids) is None


def test_exclude_non_numerico_risponde_400(api, three_cards):
    assert api.get("/api/next-card/", {"exclude": "1,a"}).status_code == 400


def test_le_card_archiviate_non_vengono_proposte_ne_accettano_review(api, vault):
    vault.note("Numeri", "Uno?::1\nDue?::2", deck="x")
    vault.import_()
    uno = next(c for c in all_cards(api) if c["front"] == "Uno?")
    vault.note("Numeri", "Due?::2", deck="x")
    vault.import_()

    assert [c["front"] for c in all_cards(api)] == ["Due?"]
    assert review(api, uno["id"]).status_code == 404


def test_review_di_una_card_inesistente_risponde_404(api, three_cards):
    assert review(api, 999_999).status_code == 404


def test_una_review_viene_creata_e_aggiorna_le_mai_viste(api, three_cards):
    card = next_card(api)

    response = review(api, card["id"], "didnt_know")

    assert response.status_code == 201
    assert response.json()["card_id"] == card["id"]
    assert response.json()["outcome"] == "didnt_know"
    assert decks(api)["x"]["unseen_cards"] == 2
    assert decks(api)["all"]["unseen_cards"] == 2


def test_rispondere_due_volte_alla_stessa_card_la_conta_una_volta_tra_le_viste(api, three_cards):
    card = next_card(api)

    review(api, card["id"])
    review(api, card["id"], "didnt_know")

    assert decks(api)["x"]["unseen_cards"] == 2


def test_un_esito_non_valido_risponde_400_e_non_scrive_nulla(api, three_cards):
    card = next_card(api)

    assert review(api, card["id"], "forse").status_code == 400
    assert decks(api)["x"]["unseen_cards"] == 3


def test_le_api_di_studio_richiedono_il_token(anon, three_cards):
    assert anon.get("/api/next-card/").status_code == 401
    assert anon.post("/api/reviews/", {"card_id": 1, "outcome": "knew"}).status_code == 401
