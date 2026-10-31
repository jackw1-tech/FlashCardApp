from datetime import datetime, time, timedelta
from zoneinfo import ZoneInfo

import pytest
import redis
from django.conf import settings

from tests.conftest import decks, next_card, review


@pytest.fixture
def imported(vault):
    vault.note("Numeri", "Uno?::1\nDue?::2", deck="x")
    vault.import_()
    return vault


def stats(api) -> dict:
    return api.get("/api/stats/").json()


def test_la_seconda_lettura_dei_mazzi_non_tocca_il_database(api, imported, django_assert_num_queries):
    decks(api)

    with django_assert_num_queries(0):
        decks(api)


def test_la_seconda_lettura_delle_statistiche_non_tocca_il_database(api, imported, django_assert_num_queries):
    stats(api)

    with django_assert_num_queries(0):
        stats(api)


def test_una_risposta_aggiorna_mazzi_e_statistiche_in_cache(api, imported):
    assert decks(api)["x"]["unseen_cards"] == 2
    assert stats(api)["today_reviews"] == 0

    review(api, next_card(api)["id"])

    assert decks(api)["x"]["unseen_cards"] == 1
    assert stats(api)["today_reviews"] == 1


def test_un_annullamento_aggiorna_la_cache(api, imported):
    created = review(api, next_card(api)["id"]).json()
    assert decks(api)["x"]["unseen_cards"] == 1

    api.post(f"/api/reviews/{created['id']}/undo/")

    assert decks(api)["x"]["unseen_cards"] == 2
    assert stats(api)["today_reviews"] == 0


def test_rinominare_un_mazzo_aggiorna_la_cache(api, imported):
    decks(api)
    stats(api)

    api.patch("/api/decks/x/", {"name": "Numeri"}, format="json")

    assert decks(api)["x"]["name"] == "Numeri"
    assert next(d for d in stats(api)["decks"] if d["slug"] == "x")["name"] == "Numeri"


def test_un_import_aggiorna_la_cache(api, imported):
    decks(api)

    imported.note("Altri", "Tre?::3", deck="x")
    imported.import_()

    assert decks(api)["x"]["total_cards"] == 3


def test_le_statistiche_in_cache_scadono_a_mezzanotte(api, imported, isolated_redis):
    stats(api)

    [key] = isolated_redis.keys("stats:*")
    tz = ZoneInfo(settings.STUDY_TIME_ZONE)
    now = datetime.now(tz)
    seconds_to_midnight = (datetime.combine(now.date() + timedelta(days=1), time.min, tzinfo=tz) - now).total_seconds()
    assert 0 < isolated_redis.ttl(key) <= seconds_to_midnight + 1


def test_la_cache_e_per_utente(api, imported, django_user_model):
    from rest_framework.test import APIClient

    from tests.conftest import CSRF_HEADER

    review(api, next_card(api)["id"])
    other = APIClient()
    other.credentials(**CSRF_HEADER)
    other.force_authenticate(django_user_model.objects.create_user("altro"))

    assert decks(other)["x"]["unseen_cards"] == 2
    assert decks(api)["x"]["unseen_cards"] == 1


def test_con_redis_giu_mazzi_e_statistiche_si_leggono_dal_database(api, imported, monkeypatch):
    def broken(*args, **kwargs):
        raise redis.ConnectionError("Redis giù (simulato)")

    with monkeypatch.context() as patch:
        patch.setattr(redis.Redis, "execute_command", broken)
        patch.setattr(redis.client.Pipeline, "execute", broken)
        assert decks(api)["x"]["total_cards"] == 2
        assert stats(api)["today_reviews"] == 0
