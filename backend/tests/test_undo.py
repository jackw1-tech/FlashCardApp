import pytest

from apps.study.models import Review
from tests.conftest import decks, next_card, review


@pytest.fixture
def one_card(vault):
    vault.note("Numeri", "Uno?::1", deck="x")
    vault.import_()


def undo(api, review_id: int):
    return api.post(f"/api/reviews/{review_id}/undo/")


def test_annullare_l_unica_risposta_rende_la_card_di_nuovo_mai_vista(api, one_card):
    created = review(api, next_card(api)["id"]).json()

    response = undo(api, created["id"])

    assert response.status_code == 200
    assert decks(api)["x"]["unseen_cards"] == 1
    assert Review.objects.filter(pk=created["id"]).exists()


def test_annullare_la_seconda_risposta_lascia_la_card_vista(api, one_card):
    card = next_card(api)
    review(api, card["id"])
    second = review(api, card["id"], "didnt_know").json()

    undo(api, second["id"])

    assert decks(api)["x"]["unseen_cards"] == 0
    assert next_card(api)["recent_outcomes"] == ["knew"]


def test_non_si_annulla_due_volte(api, one_card):
    created = review(api, next_card(api)["id"]).json()
    undo(api, created["id"])

    assert undo(api, created["id"]).status_code == 409


def test_una_review_inesistente_risponde_404(api, one_card):
    assert undo(api, 999_999).status_code == 404


def test_non_si_annullano_le_review_di_un_altro_utente(api, one_card, django_user_model):
    from rest_framework.test import APIClient

    from tests.conftest import CSRF_HEADER

    created = review(api, next_card(api)["id"]).json()
    other = APIClient()
    other.credentials(**CSRF_HEADER)
    other.force_authenticate(django_user_model.objects.create_user("altro"))

    assert undo(other, created["id"]).status_code == 404


def test_annullare_richiede_il_token(anon, one_card):
    assert undo(anon, 1).status_code == 401
