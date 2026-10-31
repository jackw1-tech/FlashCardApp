from apps.catalog.services.parser import card_key, parse_note

FILENAME = "Flashcard -> Canvas.md"


def note(body: str, tags: str = "  - flashcards/cg") -> str:
    return f"---\ntags:\n{tags}\n---\n\n{body}\n"


def problem_lines(parsed) -> list[int | None]:
    return [p.line_number for p in parsed.problems]


def test_mazzo_e_titolo_vengono_da_tag_e_nome_file():
    parsed = parse_note(note("Uno?::1"), FILENAME)

    assert (parsed.deck_slug, parsed.title) == ("cg", "Canvas")


def test_la_chiave_ignora_gli_spazi_e_il_mazzo_ma_cambia_con_domanda_e_nota():
    base = card_key("cg", "Canvas", "Cos'è un  canvas?")

    assert card_key("cg", "Canvas", "  Cos'è un canvas? ") == base
    assert card_key("cg", "Canvas", "Cos'è il canvas?") != base
    assert card_key("cg", "WebGL", "Cos'è un canvas?") != base
    assert card_key("dss/fondamenti", "Canvas", "Cos'è un canvas?") == base


def test_numero_di_riga_relativo_al_file():
    parsed = parse_note(note("Uno?::1"), FILENAME)

    assert parsed.cards[0].line_number == 6


def test_basic_separa_sul_primo_doppio_due_punti_fuori_dal_codice_inline():
    parsed = parse_note(note("Cosa fa `x :: xs` in Scala?::Aggiunge `x` in testa: `x :: xs`."), FILENAME)

    card = parsed.cards[0]
    assert (card.kind, card.front, card.back) == ("basic", "Cosa fa `x :: xs` in Scala?", "Aggiunge `x` in testa: `x :: xs`.")


def test_il_triplo_due_punti_diventa_una_card_basic_nel_verso_diretto():
    parsed = parse_note(note("WebGL:::API grafica del browser"), FILENAME)

    assert [(c.kind, c.front, c.back) for c in parsed.cards] == [("basic", "WebGL", "API grafica del browser")]


def test_multiline_con_risposta_su_tre_righe():
    parsed = parse_note(note("Come si dimensiona un canvas?\n?\nCon width\ne height,\nnon con il CSS."), FILENAME)

    card = parsed.cards[0]
    assert card.kind == "multiline"
    assert card.front == "Come si dimensiona un canvas?"
    assert card.back == "Con width\ne height,\nnon con il CSS."


def test_multiline_con_blocco_di_codice_nella_domanda():
    body = "Quanto vale `f()`?\n```scala\ndef f() = 1 :: Nil\n\nval x = 2\n```\n?\n`List(1)`"

    parsed = parse_note(note(body), FILENAME)

    assert len(parsed.cards) == 1
    assert parsed.cards[0].front == "Quanto vale `f()`?\n```scala\ndef f() = 1 :: Nil\n\nval x = 2\n```"
    assert parsed.cards[0].back == "`List(1)`"


def test_le_card_separate_da_righe_vuote_restano_separate():
    parsed = parse_note(note("Prima\n?\nuno\n\nSeconda::due"), FILENAME)

    assert [c.kind for c in parsed.cards] == ["multiline", "basic"]


def test_cloze_con_due_lacune_produce_due_card():
    parsed = parse_note(note("Si usano adiacenze ==4-connected== e ==8-connected==."), FILENAME)

    first, second = parsed.cards
    assert first.front == "Si usano adiacenze [...] e 8-connected."
    assert first.back == "Si usano adiacenze **4-connected** e 8-connected."
    assert second.front == "Si usano adiacenze 4-connected e [...]."
    assert first.key != second.key
    assert {first.kind, second.kind} == {"cloze"}


def test_doppio_due_punti_in_blocchi_di_codice_e_tabelle_non_produce_card():
    body = "```\na::b\n```\n\n| a::b | c |\n|---|---|\n\nVera?::sì"

    parsed = parse_note(note(body), FILENAME)

    assert [c.front for c in parsed.cards] == ["Vera?"]
    assert parsed.problems == []


def test_titoli_e_prosa_non_producono_card():
    parsed = parse_note(note("## Sezione\nSolo testo descrittivo.\n\nUno?::1"), FILENAME)

    assert [c.front for c in parsed.cards] == ["Uno?"]


def test_nota_senza_tag_flashcards_viene_saltata():
    parsed = parse_note(note("Uno?::1", tags="  - lezione"), FILENAME)

    assert parsed.cards == []
    assert problem_lines(parsed) == [None]
    assert "flashcards/" in parsed.problems[0].message


def test_la_gerarchia_accetta_al_massimo_mazzo_e_sottomazzo():
    nested = parse_note(note("Uno?::1", tags="  - flashcards/dss/fondamenti"), FILENAME)
    too_deep = parse_note(note("Uno?::1", tags="  - flashcards/dss/fondamenti/base"), FILENAME)

    assert nested.deck_slug == "dss/fondamenti"
    assert len(nested.cards) == 1
    assert too_deep.cards == []
    assert "<sottomazzo>" in too_deep.problems[0].message


def test_frontmatter_assente_o_malformato_viene_segnalato():
    assert parse_note("Uno?::1\n", FILENAME).problems
    assert parse_note("---\ntags: [unclosed\n---\nUno?::1\n", FILENAME).problems


def test_lato_vuoto_di_una_basic_viene_segnalato():
    parsed = parse_note(note("::senza domanda\nSenza risposta?::"), FILENAME)

    assert parsed.cards == []
    assert problem_lines(parsed) == [6, 7]


def test_punto_interrogativo_senza_domanda_o_senza_risposta_viene_segnalato():
    parsed = parse_note(note("?\nrisposta orfana\n\nDomanda orfana\n?"), FILENAME)

    assert parsed.cards == []
    assert problem_lines(parsed) == [6, 10]


def test_domanda_duplicata_nella_stessa_nota_tiene_la_prima():
    parsed = parse_note(note("Uno?::1\nUno?::uno"), FILENAME)

    assert [c.back for c in parsed.cards] == ["1"]
    assert problem_lines(parsed) == [7]


def test_il_formato_inverso_non_e_supportato():
    parsed = parse_note(note("Domanda\n??\nRisposta"), FILENAME)

    assert parsed.cards == []
    assert problem_lines(parsed) == [7]
