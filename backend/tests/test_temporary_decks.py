import os
from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

import pytest
from django.contrib.auth import get_user_model
from django.utils import timezone

from apps.catalog.models import Card
from apps.study.models import Review, ReviewUndo, TemporaryDeck, TemporaryDeckDraft
from apps.study.services.temporary_decks import (
    DraftNotFound,
    NoCards,
    TemporaryDeckNotFound,
    create_from_draft,
    create_temporary_deck,
    list_temporary_decks,
    preview_temporary_deck,
    split_equally,
)
from tests.conftest import review


def note_with(vault, title: str, n: int, deck: str = "dss") -> None:
    vault.note(title, "\n".join(f"{title} domanda {i}?::risposta {i}" for i in range(n)), deck=deck)


def touch(vault, title: str, when: datetime) -> None:
    os.utime(vault.root / f"Flashcard -> {title}.md", (when.timestamp(), when.timestamp()))


def cards_of(title: str) -> list[Card]:
    return list(Card.objects.filter(note_title=title).order_by("line_number"))


def answer(api, card: Card, outcome: str, ago: timedelta | None = None) -> Review:
    created = review(api, card.pk, outcome)
    assert created.status_code == 201, created.content
    if ago is not None:
        Review.objects.filter(pk=created.json()["id"]).update(created_at=timezone.now() - ago)
    return Review.objects.get(pk=created.json()["id"])


def taken(result) -> dict:
    return {n.note: n.taken for n in result.by_note}


def deck_cards(deck: TemporaryDeck) -> list[Card]:
    return [entry.card for entry in deck.entries.select_related("card")]


@pytest.fixture
def three_notes(vault):
    for title in ("MCP", "gRPC", "Raft"):
        note_with(vault, title, 30)
    vault.import_()


def test_l_import_salva_la_data_di_modifica_del_file_della_nota(vault, db):
    note_with(vault, "MCP", 2)
    when = datetime(2026, 10, 20, 9, 30, tzinfo=UTC)
    touch(vault, "MCP", when)
    vault.import_()

    assert {c.note_modified_at for c in cards_of("MCP")} == {when}


def test_se_cambia_solo_la_data_di_modifica_le_card_si_aggiornano_senza_contare_come_modificate(vault, db):
    note_with(vault, "MCP", 2)
    touch(vault, "MCP", datetime(2026, 10, 20, tzinfo=UTC))
    vault.import_()
    later = datetime(2026, 10, 25, tzinfo=UTC)
    touch(vault, "MCP", later)

    output = vault.import_()

    assert "aggiornate: 0" in output
    assert {c.note_modified_at for c in cards_of("MCP")} == {later}


def test_senza_numero_sono_20_divise_in_parti_uguali_e_il_resto_va_ai_primi(user, three_notes):
    result = create_temporary_deck(user, notes=["MCP", "gRPC", "Raft"])

    assert taken(result) == {"MCP": 7, "gRPC": 7, "Raft": 6}
    assert result.deck.entries.count() == 20
    assert result.adjustments == []


def test_quello_che_una_nota_non_ha_passa_alle_altre(user, vault):
    note_with(vault, "MCP", 48)
    note_with(vault, "gRPC", 3)
    note_with(vault, "Raft", 45)
    vault.import_()

    result = create_temporary_deck(user, notes=["MCP", "gRPC", "Raft"])

    assert taken(result) == {"MCP": 9, "gRPC": 3, "Raft": 8}
    assert any('"gRPC" ha solo 3 card' in a for a in result.adjustments)


def test_se_le_card_non_bastano_il_mazzo_nasce_con_quelle_che_ci_sono(user, vault):
    note_with(vault, "MCP", 5)
    vault.import_()

    result = create_temporary_deck(user, notes=["MCP"], count=20)

    assert result.deck.entries.count() == 5
    assert "Chieste 20 card, ne esistono 5" in result.adjustments[-1]


def test_senza_note_si_sceglie_tra_tutte_le_card(user, three_notes):
    result = create_temporary_deck(user, count=10)

    assert result.deck.entries.count() == 10
    assert taken(result) == {None: 10}


@pytest.mark.parametrize(
    ("count", "available", "expected"),
    [(20, [48, 3, 45], [9, 3, 8]), (20, [30, 30, 30], [7, 7, 6]), (2, [5, 5, 5], [1, 1, 0]), (10, [0, 0], [0, 0])],
)
def test_split_equally(count, available, expected):
    assert split_equally(count, available) == expected


def test_un_numero_fuori_dai_limiti_viene_rifiutato(user, three_notes):
    with pytest.raises(ValueError):
        create_temporary_deck(user, count=0)


def test_i_titoli_si_riconoscono_senza_badare_alle_maiuscole(user, three_notes):
    result = create_temporary_deck(user, notes=["mcp"], count=3)

    assert taken(result) == {"MCP": 3}


def test_una_nota_inesistente_tra_quelle_valide_finisce_negli_avvisi_con_i_titoli_simili(user, vault):
    note_with(vault, "MCP", 10)
    note_with(vault, "REST o gRPC", 10)
    vault.import_()

    result = create_temporary_deck(user, notes=["MCP", "grpc"], count=4)

    assert taken(result) == {"MCP": 4}
    assert result.adjustments == ['Nota "grpc" non trovata. Simili: "REST o gRPC".']


def test_se_nessuna_nota_esiste_non_nasce_nessun_mazzo(user, three_notes):
    with pytest.raises(NoCards, match="Nessuna delle note richieste esiste"):
        create_temporary_deck(user, notes=["Kubernetes"])

    assert not TemporaryDeck.objects.exists()


def test_modificate_oggi_prende_solo_le_note_modificate_oggi(user, vault):
    note_with(vault, "Vecchia", 3)
    note_with(vault, "Nuova", 3)
    touch(vault, "Vecchia", timezone.now() - timedelta(days=3))
    vault.import_()

    result = create_temporary_deck(user, modified="today")

    assert {c.note_title for c in deck_cards(result.deck)} == {"Nuova"}


def test_se_oggi_non_e_stata_modificata_nessuna_nota_lo_dice(user, vault):
    note_with(vault, "Vecchia", 3)
    touch(vault, "Vecchia", timezone.now() - timedelta(days=3))
    vault.import_()

    with pytest.raises(NoCards, match="Oggi non è stata modificata nessuna nota"):
        create_temporary_deck(user, modified="today")


def test_sbagliate_negli_ultimi_giorni_basta_un_errore_valido_nel_periodo(api, user, vault):
    note_with(vault, "MCP", 4)
    vault.import_()
    recovered, old, undone, never = cards_of("MCP")
    answer(api, recovered, "didnt_know", ago=timedelta(days=3))
    answer(api, recovered, "knew", ago=timedelta(days=1))
    answer(api, old, "didnt_know", ago=timedelta(days=10))
    ReviewUndo.objects.create(review=answer(api, undone, "didnt_know"))

    result = create_temporary_deck(user, missed_in_days=7)

    assert deck_cards(result.deck) == [recovered]


def test_se_nel_periodo_non_hai_ripassato_lo_dice(api, user, vault):
    note_with(vault, "MCP", 2)
    vault.import_()

    with pytest.raises(NoCards, match="non ha ripassato nessuna"):
        create_temporary_deck(user, missed_in_days=7)


def test_se_nel_periodo_non_hai_sbagliato_niente_lo_dice(api, user, vault):
    note_with(vault, "MCP", 2)
    vault.import_()
    for card in cards_of("MCP"):
        answer(api, card, "knew")

    with pytest.raises(NoCards, match="ha risposto 2 volte senza sbagliare"):
        create_temporary_deck(user, missed_in_days=7)


def test_peggiori_prima_per_percentuale_di_errori_e_le_mai_viste_in_fondo(api, user, vault):
    note_with(vault, "MCP", 4)
    vault.import_()
    always_wrong, half, never, always_right = cards_of("MCP")
    answer(api, always_wrong, "didnt_know")
    answer(api, half, "didnt_know")
    answer(api, half, "knew")
    answer(api, always_right, "knew")

    result = create_temporary_deck(user, notes=["MCP"], count=4, order="worst_first")

    assert deck_cards(result.deck) == [always_wrong, half, always_right, never]


def test_i_filtri_si_combinano(api, user, vault):
    note_with(vault, "MCP", 2)
    note_with(vault, "Raft", 2)
    vault.import_()
    for title in ("MCP", "Raft"):
        answer(api, cards_of(title)[0], "didnt_know")

    result = create_temporary_deck(user, notes=["MCP"], missed_in_days=7)

    assert deck_cards(result.deck) == [cards_of("MCP")[0]]


def test_sbagliate_in_un_mazzo_conta_solo_gli_errori_dopo_la_sua_creazione(api, user, vault):
    note_with(vault, "MCP", 3)
    vault.import_()
    wrong_before, wrong_after, right_after = cards_of("MCP")
    answer(api, wrong_before, "didnt_know")
    source = create_temporary_deck(user, notes=["MCP"]).deck
    answer(api, wrong_after, "didnt_know")
    answer(api, right_after, "knew")

    result = create_temporary_deck(user, missed_in_deck=source.pk)

    assert deck_cards(result.deck) == [wrong_after]
    assert result.deck.name == 'Sbagliate in "MCP"'


def test_un_mazzo_scaduto_vale_ancora_per_le_sbagliate_di_prima(api, user, vault):
    note_with(vault, "MCP", 2)
    vault.import_()
    source = create_temporary_deck(user, notes=["MCP"]).deck
    answer(api, cards_of("MCP")[0], "didnt_know")
    TemporaryDeck.objects.filter(pk=source.pk).update(expires_at=timezone.now() - timedelta(hours=1))

    assert create_temporary_deck(user, missed_in_deck=source.pk).deck.entries.count() == 1


def test_il_mazzo_di_un_altro_utente_non_si_trova(user, three_notes):
    other = get_user_model().objects.create_user("altro")
    source = create_temporary_deck(other, notes=["MCP"]).deck

    with pytest.raises(TemporaryDeckNotFound):
        create_temporary_deck(user, missed_in_deck=source.pk)


def test_se_nel_mazzo_non_hai_sbagliato_niente_lo_dice(user, three_notes):
    source = create_temporary_deck(user, notes=["MCP"]).deck

    with pytest.raises(NoCards, match='Nel mazzo "MCP" non ci sono card sbagliate'):
        create_temporary_deck(user, missed_in_deck=source.pk)


def test_il_nome_viene_dalle_note_e_il_mazzo_scade_alla_prossima_mezzanotte(user, three_notes, settings):
    deck = create_temporary_deck(user, notes=["MCP", "gRPC", "Raft"]).deck

    assert deck.name == "MCP, gRPC e Raft"
    local = deck.expires_at.astimezone(ZoneInfo(settings.STUDY_TIME_ZONE))
    assert (local.hour, local.minute) == (0, 0)
    assert deck.expires_at > timezone.now()


def test_il_nome_scelto_dalla_chat_vince(user, three_notes):
    assert create_temporary_deck(user, notes=["MCP"], name="Prima dell'esame").deck.name == "Prima dell'esame"


def test_l_elenco_mostra_i_piu_recenti_con_fatte_e_sbagliate(api, user, three_notes):
    first = create_temporary_deck(user, notes=["MCP"], count=3).deck
    second = create_temporary_deck(user, notes=["Raft"], count=2).deck
    one, two = deck_cards(second)
    answer(api, one, "didnt_know")
    answer(api, two, "knew")
    TemporaryDeck.objects.filter(pk=first.pk).update(expires_at=timezone.now() - timedelta(hours=1))

    newest, oldest = list_temporary_decks(user)

    assert (newest.id, newest.total, newest.done, newest.missed, newest.expired) == (second.pk, 2, 2, 1, False)
    assert (oldest.id, oldest.total, oldest.done, oldest.missed, oldest.expired) == (first.pk, 3, 0, 0, True)
    assert [d.id for d in list_temporary_decks(user, limit=1)] == [second.pk]


def test_la_prossima_card_viene_solo_dal_mazzo_e_le_fatte_non_tornano(api, user, three_notes):
    deck = create_temporary_deck(user, notes=["Raft"], count=3).deck
    expected = {c.pk for c in deck_cards(deck)}
    seen = set()

    while card := next_card_of(api, deck):
        assert card["id"] in expected and card["id"] not in seen
        seen.add(card["id"])
        review(api, card["id"], "knew")

    assert seen == expected


def test_un_mazzo_scaduto_o_di_un_altro_utente_risponde_404(api, user, three_notes):
    expired = create_temporary_deck(user, notes=["MCP"], count=1).deck
    TemporaryDeck.objects.filter(pk=expired.pk).update(expires_at=timezone.now() - timedelta(seconds=1))
    other = create_temporary_deck(get_user_model().objects.create_user("altro"), notes=["MCP"], count=1).deck

    for deck in (expired, other):
        assert api.get("/api/next-card/", {"temporary_deck": deck.pk}).status_code == 404


def next_card_of(api, deck: TemporaryDeck) -> dict | None:
    response = api.get("/api/next-card/", {"temporary_deck": deck.pk})
    assert response.status_code == 200, response.content
    return response.json()["card"]


def test_l_anteprima_salva_le_card_scelte_ma_non_crea_il_mazzo(user, three_notes):
    preview = preview_temporary_deck(user, notes=["MCP", "Raft"], count=4)

    assert len(preview.draft.card_ids) == 4
    assert {n.note: n.taken for n in preview.by_note} == {"MCP": 2, "Raft": 2}
    assert not TemporaryDeck.objects.exists()


def test_la_conferma_crea_esattamente_le_card_dell_anteprima_nello_stesso_ordine(user, three_notes):
    preview = preview_temporary_deck(user, notes=["MCP", "Raft"], count=6, name="Prova")

    created = create_from_draft(user, preview.draft.pk)

    assert [c.pk for c in deck_cards(created.deck)] == preview.draft.card_ids
    assert created.deck.name == "Prova"


def test_confermare_due_volte_restituisce_lo_stesso_mazzo(user, three_notes):
    draft = preview_temporary_deck(user, notes=["MCP"], count=3).draft

    first = create_from_draft(user, draft.pk)
    second = create_from_draft(user, draft.pk)

    assert first.deck.pk == second.deck.pk
    assert TemporaryDeck.objects.count() == 1


def test_un_anteprima_scaduta_o_di_un_altro_utente_non_si_conferma(user, three_notes):
    expired = preview_temporary_deck(user, notes=["MCP"], count=1).draft
    TemporaryDeckDraft.objects.filter(pk=expired.pk).update(expires_at=timezone.now() - timedelta(seconds=1))
    other = preview_temporary_deck(get_user_model().objects.create_user("altro"), notes=["MCP"], count=1).draft

    for draft in (expired, other):
        with pytest.raises(DraftNotFound):
            create_from_draft(user, draft.pk)


def test_le_card_tolte_dal_vault_dopo_l_anteprima_restano_fuori_e_lo_dice(user, vault):
    note_with(vault, "MCP", 2)
    note_with(vault, "Raft", 2)
    vault.import_()
    draft = preview_temporary_deck(user, notes=["MCP", "Raft"], count=4).draft
    vault.remove("Raft")
    vault.import_()

    created = create_from_draft(user, draft.pk)

    assert {c.note_title for c in deck_cards(created.deck)} == {"MCP"}
    assert "2 card dell'anteprima sono state tolte dal vault" in created.adjustments[-1]


def test_l_app_vede_solo_i_mazzi_attivi_con_l_avanzamento(api, user, three_notes):
    active = create_temporary_deck(user, notes=["MCP"], count=2).deck
    expired = create_temporary_deck(user, notes=["Raft"], count=1).deck
    TemporaryDeck.objects.filter(pk=expired.pk).update(expires_at=timezone.now() - timedelta(seconds=1))
    review(api, deck_cards(active)[0].pk, "didnt_know")

    response = api.get("/api/temporary-decks/")

    assert response.status_code == 200
    [deck] = response.json()["temporary_decks"]
    assert (deck["id"], deck["name"], deck["total"], deck["done"], deck["missed"]) == (active.pk, "MCP", 2, 1, 1)


def test_cancellare_un_mazzo_lascia_le_review(api, user, three_notes):
    deck = create_temporary_deck(user, notes=["MCP"], count=1).deck
    review(api, deck_cards(deck)[0].pk, "knew")

    assert api.delete(f"/api/temporary-decks/{deck.pk}/").status_code == 204
    assert not TemporaryDeck.objects.exists()
    assert Review.objects.count() == 1


def test_non_si_cancella_il_mazzo_di_un_altro(api, three_notes):
    other = create_temporary_deck(get_user_model().objects.create_user("altro"), notes=["MCP"], count=1).deck

    assert api.delete(f"/api/temporary-decks/{other.pk}/").status_code == 404
    assert TemporaryDeck.objects.filter(pk=other.pk).exists()
