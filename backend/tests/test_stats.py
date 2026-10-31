from datetime import timedelta
from zoneinfo import ZoneInfo

import pytest
from django.utils import timezone

from apps.study.models import Review
from tests.conftest import all_cards, next_card, review


@pytest.fixture
def two_decks(vault):
    vault.note("Numeri", "Uno?::1\nDue?::2\nTre?::3", deck="x")
    vault.note("Lettere", "A?::a", deck="y")
    vault.import_()


def stats(api) -> dict:
    response = api.get("/api/stats/")
    assert response.status_code == 200
    return response.json()


def shift_reviews_back(days: int) -> None:
    for item in Review.objects.all():
        Review.objects.filter(pk=item.pk).update(created_at=item.created_at - timedelta(days=days))


def test_senza_risposte_tutto_a_zero(api, two_decks):
    result = stats(api)

    assert (result["today_reviews"], result["streak_days"]) == (0, 0)
    assert {d["slug"]: (d["reviews"], d["knew_ratio"], d["last_studied_at"]) for d in result["decks"]} == {
        "x": (0, None, None),
        "y": (0, None, None),
    }


def test_le_risposte_di_oggi_e_la_percentuale_per_mazzo(api, two_decks):
    one, two, three = all_cards(api, "x")
    review(api, one["id"])
    review(api, two["id"])
    review(api, three["id"], "didnt_know")

    result = stats(api)

    assert (result["today_reviews"], result["streak_days"]) == (3, 1)
    deck = next(d for d in result["decks"] if d["slug"] == "x")
    assert deck["reviews"] == 3
    assert deck["knew_ratio"] == pytest.approx(2 / 3)
    assert deck["last_studied_at"] is not None


def test_i_giorni_di_fila(api, two_decks):
    card = next_card(api, "y")
    review(api, card["id"])
    shift_reviews_back(1)
    review(api, card["id"])
    shift_reviews_back(1)
    review(api, card["id"])

    assert stats(api)["streak_days"] == 3


def test_la_serie_resta_viva_se_oggi_non_hai_ancora_studiato(api, two_decks):
    review(api, next_card(api, "y")["id"])
    shift_reviews_back(1)

    result = stats(api)

    assert (result["today_reviews"], result["streak_days"]) == (0, 1)


def test_un_giorno_saltato_azzera_la_serie(api, two_decks):
    review(api, next_card(api, "y")["id"])
    shift_reviews_back(2)

    assert stats(api)["streak_days"] == 0


def test_le_risposte_annullate_non_contano(api, two_decks):
    created = review(api, next_card(api, "y")["id"]).json()
    api.post(f"/api/reviews/{created['id']}/undo/")

    assert stats(api)["today_reviews"] == 0


def test_la_card_porta_gli_ultimi_cinque_esiti_in_ordine(api, two_decks):
    card = next_card(api, "y")
    assert card["recent_outcomes"] == []
    for outcome in ["knew", "didnt_know", "knew", "knew", "didnt_know", "knew"]:
        review(api, card["id"], outcome)

    assert next_card(api, "y")["recent_outcomes"] == ["didnt_know", "knew", "knew", "didnt_know", "knew"]


def test_le_statistiche_richiedono_il_token(anon, two_decks):
    assert anon.get("/api/stats/").status_code == 401


def test_oggi_e_calcolato_nel_fuso_di_studio(api, two_decks, settings):
    settings.STUDY_TIME_ZONE = "Pacific/Kiritimati"

    assert stats(api)["today"] == timezone.localdate(timezone=ZoneInfo("Pacific/Kiritimati")).isoformat()
