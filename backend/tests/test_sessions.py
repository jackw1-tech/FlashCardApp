import uuid

import pytest
from django.contrib.auth import get_user_model

from apps.study.models import Review, ReviewUndo, StudySession
from tests.conftest import all_cards, review


@pytest.fixture
def three_cards(vault):
    vault.note("Numeri", "Uno?::1\nDue?::2\nTre?::3", deck="x")
    vault.import_()


def answer(api, card_id: int, outcome: str = "knew") -> int:
    return review(api, card_id, outcome).json()["id"]


def save(api, review_ids: list[int], client_id: str | None = None, **extra):
    body = {"client_id": client_id or str(uuid.uuid4()), "review_ids": review_ids, **extra}
    return api.post("/api/sessions/", body, format="json")


def test_una_sessione_con_risposte_si_salva_con_i_conteggi_ricalcolati(api, three_cards):
    one, two, three = all_cards(api)
    ids = [answer(api, one["id"]), answer(api, two["id"], "didnt_know"), answer(api, three["id"])]

    response = save(api, ids, deck="x")

    assert response.status_code == 201
    body = response.json()
    assert (body["knew"], body["didnt_know"]) == (2, 1)
    assert body["deck"] == {"slug": "x", "name": "x"}
    first, *_, last = Review.objects.filter(pk__in=ids).order_by("created_at")
    session = StudySession.objects.get()
    assert (session.started_at, session.ended_at) == (first.created_at, last.created_at)
    assert session.reviews.count() == 3


def test_le_risposte_annullate_non_contano(api, three_cards):
    one, two, _ = all_cards(api)
    kept = answer(api, one["id"])
    undone = answer(api, two["id"], "didnt_know")
    ReviewUndo.objects.create(review_id=undone)

    body = save(api, [kept, undone]).json()

    assert (body["knew"], body["didnt_know"]) == (1, 0)


def test_una_sessione_senza_risposte_valide_non_si_salva(api, three_cards):
    one, *_ = all_cards(api)
    undone = answer(api, one["id"])
    ReviewUndo.objects.create(review_id=undone)

    response = save(api, [undone])

    assert response.status_code == 400
    assert not StudySession.objects.exists()


def test_le_risposte_di_un_altro_utente_non_entrano(api, three_cards):
    from rest_framework.test import APIClient

    from tests.conftest import CSRF_HEADER

    other = APIClient()
    other.credentials(**CSRF_HEADER)
    other.force_authenticate(get_user_model().objects.create_user("altro"))
    foreign = answer(other, all_cards(other)[0]["id"])

    assert save(api, [foreign]).status_code == 400


def test_salvare_due_volte_la_stessa_sessione_ne_crea_una(api, three_cards):
    one, *_ = all_cards(api)
    ids = [answer(api, one["id"])]
    client_id = str(uuid.uuid4())

    first = save(api, ids, client_id)
    second = save(api, ids, client_id)

    assert (first.status_code, second.status_code) == (201, 200)
    assert first.json()["id"] == second.json()["id"]
    assert StudySession.objects.count() == 1


def test_l_elenco_mostra_le_sessioni_dalla_piu_recente(api, three_cards):
    one, two, _ = all_cards(api)
    first = save(api, [answer(api, one["id"])]).json()
    second = save(api, [answer(api, two["id"])], note="Numeri").json()

    sessions = api.get("/api/sessions/").json()["sessions"]

    assert [s["id"] for s in sessions] == [second["id"], first["id"]]
    assert sessions[0]["note_title"] == "Numeri"
