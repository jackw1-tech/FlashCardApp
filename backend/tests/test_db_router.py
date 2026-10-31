import pytest
from django.conf import settings as django_settings
from django.contrib.auth import get_user_model
from django.test import RequestFactory

from apps.accounts.models import RefreshToken
from apps.catalog.models import Card
from apps.study.models import CardState
from shared.db_router import PrimaryReplicaRouter, replica_reads
from shared.middleware import reads_from_replica

router = PrimaryReplicaRouter()

pytestmark = pytest.mark.skipif(
    not django_settings.REPLICA_DB_ALIASES, reason="serve POSTGRES_REPLICA_HOSTS (compose del backend)"
)


def test_senza_una_replica_scelta_si_legge_dal_primary():
    assert router.db_for_read(Card) == "default"


def test_catalogo_e_studio_si_leggono_dalla_replica_scelta():
    with replica_reads("replica1"):
        assert router.db_for_read(Card) == "replica1"
        assert router.db_for_read(CardState) == "replica1"


def test_un_alias_che_non_esiste_vale_come_primary():
    with replica_reads("replica99"):
        assert router.db_for_read(Card) == "default"


def test_utenti_e_token_restano_sul_primary():
    with replica_reads("replica1"):
        assert router.db_for_read(get_user_model()) == "default"
        assert router.db_for_read(RefreshToken) == "default"


def test_le_scritture_vanno_sempre_al_primary():
    with replica_reads("replica1"):
        assert router.db_for_write(Card) == "default"


def test_dentro_una_transazione_si_legge_dal_primary(db):
    with replica_reads("replica1"):
        assert router.db_for_read(CardState) == "default"


@pytest.mark.parametrize(("chosen", "expected"), [("replica1", "replica1"), (None, "default")])
def test_in_modalita_lsn_decide_la_funzione(chosen, expected):
    with replica_reads(lambda: chosen):
        assert router.db_for_read(Card) == expected


def test_la_funzione_non_viene_chiamata_per_utenti_e_token():
    calls = []
    with replica_reads(lambda: calls.append(1) or "replica1"):
        router.db_for_read(get_user_model())
        router.db_for_read(RefreshToken)
    assert calls == []


def test_le_migrazioni_girano_solo_sul_primary():
    assert router.allow_migrate("default", "study")
    assert not router.allow_migrate("replica1", "study")


@pytest.mark.parametrize(
    ("method", "path", "expected"),
    [
        ("get", "/api/next-card/", True),
        ("get", "/api/decks/", True),
        ("post", "/api/reviews/", False),
        ("get", "/api/auth/session/", False),
        ("get", "/admin/", False),
    ],
)
@pytest.mark.parametrize("mode", ["always", "lsn"])
def test_solo_le_get_dell_api_possono_leggere_dalla_replica(settings, mode, method, path, expected):
    settings.READ_REPLICA_MODE = mode

    assert reads_from_replica(getattr(RequestFactory(), method)(path)) is expected


def test_con_off_nessuna_richiesta_legge_dalla_replica(settings):
    settings.READ_REPLICA_MODE = "off"

    assert not reads_from_replica(RequestFactory().get("/api/next-card/"))
