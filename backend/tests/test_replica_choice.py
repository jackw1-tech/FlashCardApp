import subprocess
import sys

from shared.replica_choice import replica_for

THREE = ["replica1", "replica2", "replica3"]
FOUR = [*THREE, "replica4"]
USERS = range(1, 1001)


def test_senza_repliche_si_legge_dal_primary():
    assert replica_for(7, []) is None


def test_con_una_replica_tutti_leggono_da_quella():
    assert {replica_for(user, ["replica1"]) for user in USERS} == {"replica1"}


def test_lo_stesso_utente_sceglie_sempre_la_stessa_replica():
    assert len({replica_for(42, THREE) for _ in range(100)}) == 1


def test_la_scelta_non_cambia_tra_processi_diversi():
    code = "from shared.replica_choice import replica_for; print([replica_for(u, %r) for u in range(1, 50)])" % THREE
    outputs = {
        subprocess.run(
            [sys.executable, "-c", code], env={"PYTHONHASHSEED": seed}, capture_output=True, text=True, check=True
        ).stdout
        for seed in ("1", "2", "3")
    }
    assert len(outputs) == 1


def test_gli_utenti_si_dividono_tra_le_repliche():
    counts = {alias: 0 for alias in THREE}
    for user in USERS:
        counts[replica_for(user, THREE)] += 1
    assert all(250 < count < 420 for count in counts.values()), counts


def test_aggiungendo_una_replica_si_sposta_solo_circa_un_quarto_degli_utenti_e_solo_verso_la_nuova():
    moved = [user for user in USERS if replica_for(user, THREE) != replica_for(user, FOUR)]

    assert 0.18 < len(moved) / len(USERS) < 0.32
    assert {replica_for(user, FOUR) for user in moved} == {"replica4"}


def test_con_hash_modulo_n_si_sposterebbero_quasi_tutti():
    moved = [user for user in USERS if THREE[user % 3] != FOUR[user % 4]]

    assert len(moved) / len(USERS) > 0.7
