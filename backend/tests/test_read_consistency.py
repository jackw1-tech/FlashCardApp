import re

import pytest
import redis
from django.contrib.auth.models import AnonymousUser

from shared import read_consistency
from shared.read_consistency import MARKER_TTL_SECONDS, advance_marker, choose_replica, replica_reached
from tests.conftest import next_card, review

LSN = re.compile(r"^[0-9A-F]+/[0-9A-F]+$")


def position(lsn: str) -> int:
    high, low = lsn.split("/")
    return (int(high, 16) << 32) + int(low, 16)


@pytest.fixture
def card(vault):
    vault.note("Numeri", "Uno?::1", deck="x")
    vault.import_()
    return vault


@pytest.fixture
def lsn_mode(settings):
    settings.READ_REPLICA_MODE = "lsn"
    settings.REPLICA_DB_ALIASES = ["replica1"]


def marker(isolated_redis, user) -> str | None:
    return isolated_redis.get(f"seen:lsn:user:{user.pk}")


def replica_at(monkeypatch, replay: str) -> list[str]:
    asked = []

    def reached(alias, lsn):
        asked.append(lsn)
        return position(replay) >= position(lsn)

    monkeypatch.setattr(read_consistency, "replica_reached", reached)
    return asked


def test_il_marcatore_non_torna_mai_indietro(user, isolated_redis):
    advance_marker(user, "0/200")
    advance_marker(user, "0/100")

    assert marker(isolated_redis, user) == "0/200"


def test_le_posizioni_si_confrontano_come_numeri_e_non_come_testo(user, isolated_redis):
    advance_marker(user, "0/FF")
    advance_marker(user, "0/100")
    assert marker(isolated_redis, user) == "0/100"

    advance_marker(user, "1/0")
    advance_marker(user, "0/FFFFFFFF")
    assert marker(isolated_redis, user) == "1/0"


def test_ogni_avanzamento_rinnova_la_scadenza(user, isolated_redis):
    advance_marker(user, "0/200")
    isolated_redis.expire(f"seen:lsn:user:{user.pk}", 5)

    advance_marker(user, "0/100")

    assert isolated_redis.ttl(f"seen:lsn:user:{user.pk}") > 5


def test_dopo_una_review_il_marcatore_e_la_posizione_del_primary(api, user, card, lsn_mode, isolated_redis):
    assert review(api, next_card(api)["id"]).status_code == 201

    assert LSN.match(marker(isolated_redis, user))
    assert 0 < isolated_redis.ttl(f"seen:lsn:user:{user.pk}") <= MARKER_TTL_SECONDS


def test_una_scrittura_rifiutata_non_fa_avanzare_il_marcatore(api, user, card, lsn_mode, isolated_redis):
    assert review(api, 999_999).status_code == 404

    assert marker(isolated_redis, user) is None


@pytest.mark.parametrize("mode", ["off", "always"])
def test_fuori_dalla_modalita_lsn_non_si_salva_niente(api, user, card, settings, isolated_redis, mode):
    settings.READ_REPLICA_MODE = mode

    review(api, next_card(api)["id"])

    assert marker(isolated_redis, user) is None


def test_senza_marcatore_si_legge_dalla_replica_dell_utente(user, lsn_mode):
    assert choose_replica(user) == "replica1"


def test_read_your_writes_replica_indietro_rispetto_alla_scrittura(user, lsn_mode, monkeypatch):
    replica_at(monkeypatch, "0/1D02A000")
    advance_marker(user, "0/1D02AE38")

    assert choose_replica(user) is None


def test_read_your_writes_replica_in_pari(user, lsn_mode, monkeypatch):
    replica_at(monkeypatch, "0/1D02AE38")
    advance_marker(user, "0/1D02AE38")

    assert choose_replica(user) == "replica1"


def test_monotonic_reads_dopo_aver_visto_il_primary_la_replica_piu_indietro_non_basta(user, lsn_mode, monkeypatch):
    replica_at(monkeypatch, "0/120")
    advance_marker(user, "0/100")
    advance_marker(user, "0/150")

    assert choose_replica(user) is None


def test_con_redis_giu_si_legge_dal_primary(user, lsn_mode, monkeypatch):
    def broken(*args, **kwargs):
        raise redis.ConnectionError("Redis giù (simulato)")

    with monkeypatch.context() as patch:
        patch.setattr(redis.Redis, "execute_command", broken)
        assert choose_replica(user) is None


def test_un_utente_non_autenticato_legge_dal_primary(lsn_mode):
    assert choose_replica(AnonymousUser()) is None


def test_senza_repliche_configurate_si_legge_dal_primary(user, settings):
    settings.REPLICA_DB_ALIASES = []

    assert choose_replica(user) is None


@pytest.mark.django_db(databases=["default", "replica1"])
def test_un_server_che_non_e_una_replica_non_ha_raggiunto_niente(lsn_mode):
    assert not replica_reached("replica1", "0/0")


@pytest.mark.django_db(transaction=True, databases=["default", "replica1"])
def test_una_get_fa_avanzare_il_marcatore_fino_a_quello_che_l_utente_ha_visto(api, user, card, lsn_mode, isolated_redis):
    advance_marker(user, "0/1")

    assert next_card(api) is not None

    assert position(marker(isolated_redis, user)) > position("0/1")


@pytest.mark.django_db(transaction=True, databases=["default", "replica1"])
@pytest.mark.parametrize(("mode", "expected"), [("lsn", "primary"), ("always", "replica1")])
def test_l_header_dice_da_dove_ha_letto_la_richiesta(api, user, card, settings, mode, expected):
    settings.READ_REPLICA_MODE = mode
    settings.REPLICA_DB_ALIASES = ["replica1"]
    advance_marker(user, "0/1")

    assert api.get("/api/next-card/")["X-Read-From"] == expected


def test_le_scritture_dichiarano_il_primary(api, card, lsn_mode):
    assert review(api, next_card(api)["id"])["X-Read-From"] == "primary"


def test_l_header_c_e_anche_con_la_replica_spenta(api, card, settings):
    settings.READ_REPLICA_MODE = "off"
    assert api.get("/api/next-card/")["X-Read-From"] == "primary"
