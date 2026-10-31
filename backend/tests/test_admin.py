import pytest
from django.contrib.auth import get_user_model

from apps.catalog.models import Card, Deck
from apps.study.models import Review
from tests.conftest import next_card, review


@pytest.fixture
def admin_client(client, db):
    client.force_login(get_user_model().objects.create_superuser("admin", password="x"))
    return client


@pytest.fixture
def imported(vault, api):
    vault.note("Numeri", "Uno?::1", deck="ddia")
    vault.import_()
    review(api, next_card(api)["id"])


def test_il_nome_del_mazzo_si_modifica_e_lo_slug_no(admin_client, imported):
    deck = Deck.objects.get(slug="ddia")

    response = admin_client.post(
        f"/admin/catalog/deck/{deck.pk}/change/", {"name": "Designing Data-Intensive Applications", "slug": "altro"}
    )

    assert response.status_code == 302
    deck.refresh_from_db()
    assert (deck.slug, deck.name) == ("ddia", "Designing Data-Intensive Applications")


@pytest.mark.parametrize("model", [Card, Review])
def test_card_e_review_sono_in_sola_lettura(admin_client, imported, model):
    obj = model.objects.get()
    url = f"/admin/{model._meta.app_label}/{model._meta.model_name}/{obj.pk}/change/"

    assert admin_client.get(url).status_code == 200
    assert admin_client.post(url, {}).status_code == 403


@pytest.mark.parametrize("path", ["catalog/deck", "catalog/card", "catalog/cardreport", "study/review"])
def test_le_liste_dell_admin_si_aprono(admin_client, imported, path):
    assert admin_client.get(f"/admin/{path}/").status_code == 200
