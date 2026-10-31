import pytest

from apps.catalog import repositories
from apps.catalog.models import Deck
from tests.conftest import all_cards, decks, next_card, review

TRE_CARD = "Uno?::1\nDue?::2\nTre?::3"


def test_gli_aggiornamenti_massivi_vengono_divisi_in_batch(monkeypatch):
    calls = []
    cards = [object()] * 2_568

    def bulk_update(cards, fields, *, batch_size=None):
        calls.append((cards, fields, batch_size))

    monkeypatch.setattr(repositories.Card.objects, "bulk_update", bulk_update)

    repositories.update_cards(cards, ["front", "back"])

    assert len(calls) == 1
    assert calls[0][0] is cards
    assert calls[0][1:] == (["front", "back"], 100)


def test_una_nota_con_tre_card_produce_un_mazzo_con_tre_card_mai_viste(vault, api):
    vault.note("Numeri", TRE_CARD, deck="x")

    vault.import_()

    assert decks(api)["x"] == {
        "slug": "x",
        "name": "x",
        "total_cards": 3,
        "unseen_cards": 3,
        "subdecks": [],
    }


def test_le_note_che_non_sono_flashcard_vengono_ignorate(vault, api):
    vault.write("Trucchi Tailwind.md", "---\ntags:\n  - flashcards/x\n---\nhover::colore al passaggio\n")
    vault.note("Numeri", TRE_CARD, deck="x")

    vault.import_()

    assert decks(api)["x"]["total_cards"] == 3


def test_rilanciare_l_import_non_crea_duplicati(vault, api):
    vault.note("Numeri", TRE_CARD, deck="x")

    vault.import_()
    report = vault.import_()

    assert decks(api)["x"]["total_cards"] == 3
    assert "create: 0" in report


def test_le_note_dello_stesso_mazzo_finiscono_insieme_e_tutti_somma_i_mazzi(vault, api):
    vault.note("Numeri", TRE_CARD, deck="x")
    vault.note("Altri numeri", "Quattro?::4", deck="x")
    vault.note("Lettere", "A?::a\nB?::b", deck="y")

    vault.import_()

    result = decks(api)
    assert result["x"]["total_cards"] == 4
    assert result["y"]["total_cards"] == 2
    assert result["all"] == {"total_cards": 6, "unseen_cards": 6}


def test_i_sottomazzi_sono_annidati_e_il_mazzo_padre_ne_aggrega_le_card(vault, api):
    vault.note("Basi", "Uno?::1\nDue?::2", deck="dss/fondamenti")
    vault.note("Reti", "Tre?::3", deck="dss/reti")
    vault.note("Canvas", "Pixel?::colore", deck="cg")
    vault.import_()

    response = api.get("/api/decks/").json()
    assert [deck["slug"] for deck in response["decks"]] == ["cg", "dss"]
    dss = response["decks"][1]
    assert (dss["total_cards"], dss["unseen_cards"]) == (3, 3)
    assert [(deck["slug"], deck["total_cards"]) for deck in dss["subdecks"]] == [
        ("dss/fondamenti", 2),
        ("dss/reti", 1),
    ]
    assert {card["front"] for card in all_cards(api, "dss")} == {"Uno?", "Due?", "Tre?"}
    assert {card["front"] for card in all_cards(api, "dss/fondamenti")} == {"Uno?", "Due?"}
    assert [note["title"] for note in api.get("/api/decks/dss/fondamenti/notes/").json()["notes"]] == ["Basi"]

    renamed = api.patch("/api/decks/dss/fondamenti/", {"name": "Fondamenti"}, format="json")
    assert renamed.status_code == 200
    assert renamed.json()["name"] == "Fondamenti"


def test_spostare_una_nota_in_un_sottomazzo_conserva_card_e_storico(vault, api):
    vault.note("Basi", "Uno?::1", deck="dss")
    vault.import_()
    before = next_card(api, "dss")
    review(api, before["id"])

    vault.note("Basi", "Uno?::1", deck="dss/fondamenti")
    report = vault.import_()

    after = next_card(api, "dss/fondamenti")
    assert after["id"] == before["id"]
    assert decks(api)["dss"]["unseen_cards"] == 0
    assert "create: 0" in report and "archiviate: 0" in report


def test_il_report_riporta_le_card_create(vault):
    vault.note("Numeri", TRE_CARD)

    assert "create: 3" in vault.import_()


def test_la_card_mostra_mazzo_nota_e_tipo(vault, api):
    vault.note("Numeri", "Uno?::`1`", deck="x")
    vault.import_()

    card = next_card(api)

    assert card["deck"] == {"slug": "x", "name": "x"}
    assert card["note_title"] == "Numeri"
    assert card["kind"] == "basic"
    assert (card["front"], card["back"]) == ("Uno?", "`1`")


def test_cambiare_solo_la_risposta_aggiorna_la_card_e_ne_mantiene_lo_storico(vault, api):
    vault.note("Numeri", "Uno?::1")
    vault.import_()
    before = next_card(api)
    review(api, before["id"])

    vault.note("Numeri", "Uno?::uno")
    report = vault.import_()

    after = next_card(api)
    assert after["id"] == before["id"]
    assert after["back"] == "uno"
    assert decks(api)["dss"]["unseen_cards"] == 0
    assert "aggiornate: 1" in report


def test_cambiare_la_domanda_crea_una_card_nuova_e_archivia_la_vecchia(vault, api):
    vault.note("Numeri", "Uno?::1")
    vault.import_()
    old = next_card(api)

    vault.note("Numeri", "Il numero uno?::1")
    report = vault.import_()

    assert [c["id"] for c in all_cards(api)] != [old["id"]]
    assert decks(api)["dss"]["total_cards"] == 1
    assert "create: 1" in report and "archiviate: 1" in report


def test_una_card_tolta_sparisce_e_rimessa_torna_con_il_suo_storico(vault, api):
    vault.note("Numeri", "Uno?::1\nDue?::2")
    vault.import_()
    uno = next(c for c in all_cards(api) if c["front"] == "Uno?")
    review(api, uno["id"])

    vault.note("Numeri", "Due?::2")
    vault.import_()
    assert decks(api)["dss"] == {
        "slug": "dss",
        "name": "dss",
        "total_cards": 1,
        "unseen_cards": 1,
        "subdecks": [],
    }

    vault.note("Numeri", "Uno?::1\nDue?::2")
    report = vault.import_()
    restored = next(c for c in all_cards(api) if c["front"] == "Uno?")
    assert restored["id"] == uno["id"]
    assert decks(api)["dss"]["unseen_cards"] == 1
    assert "ripristinate: 1" in report


def test_l_import_non_sovrascrive_il_nome_del_mazzo(vault, api):
    vault.note("Numeri", "Uno?::1", deck="designdataintensiveapplications")
    vault.import_()
    Deck.objects.filter(slug="designdataintensiveapplications").update(name="DDIA")

    vault.import_()

    assert decks(api)["designdataintensiveapplications"]["name"] == "DDIA"


def test_un_mazzo_senza_card_attive_non_compare_nella_lista(vault, api):
    vault.note("Numeri", "Uno?::1", deck="x")
    vault.note("Lettere", "A?::a", deck="y")
    vault.import_()

    vault.remove("Lettere")
    vault.import_()

    assert "y" not in decks(api)


def test_un_errore_a_meta_import_lascia_il_db_invariato(vault, api, monkeypatch):
    from apps.catalog import repositories

    vault.note("Numeri", "Uno?::1")
    vault.import_()
    vault.note("Numeri", "Due?::2")

    def boom(*args, **kwargs):
        raise RuntimeError("guasto simulato")

    monkeypatch.setattr(repositories, "archive_cards", boom)
    with pytest.raises(RuntimeError):
        vault.import_()

    assert [c["front"] for c in all_cards(api)] == ["Uno?"]


def test_il_report_riporta_i_quattro_conteggi(vault):
    vault.note("A", "Uno?::1\nDue?::2\nTre?::3")
    vault.import_()
    vault.note("A", "Uno?::uno\nTre?::3\nQuattro?::4")
    vault.import_()
    vault.note("A", "Uno?::uno\nDue?::2\nTre?::3\nQuattro?::4\nCinque?::5")

    report = vault.import_()

    assert "create: 1" in report
    assert "aggiornate: 0" in report
    assert "archiviate: 0" in report
    assert "ripristinate: 1" in report


def test_un_vault_con_tutti_i_formati_produce_le_card_attese(vault, api):
    vault.note(
        "Formati",
        "Basic?::sì\n\nDomanda lunga\n?\nRisposta\nsu due righe\n\nIl canvas va a ==50-60== fps e ha origine in ==alto a sinistra==.",
    )

    vault.import_()

    kinds = sorted(c["kind"] for c in all_cards(api))
    assert kinds == ["basic", "cloze", "cloze", "multiline"]


def test_i_problemi_finiscono_nel_report_ma_l_import_va_a_buon_fine(vault, api):
    vault.note("Buona", "Uno?::1")
    vault.note("Rotta", "::senza domanda\nDue?::2")
    vault.write("Flashcard -> Senza tag.md", "Tre?::3\n")

    report = vault.import_()

    assert "Flashcard -> Rotta.md" in report
    assert "Flashcard -> Senza tag.md" in report
    assert decks(api)["all"]["total_cards"] == 2
