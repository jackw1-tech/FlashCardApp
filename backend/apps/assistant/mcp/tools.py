from mcp.server.mcpserver.exceptions import ToolError

from apps.catalog import repositories as catalog
from apps.catalog.services import semantic
from apps.catalog.services.embeddings import EmbeddingsUnavailable
from apps.study import services as study
from apps.study.services import temporary_decks

SAMPLE_QUESTIONS = 2
SAMPLE_LENGTH = 120


def find_topics(user, query: list[str] | None = None) -> dict:
    if query:
        return _search_topics(query)
    samples = catalog.first_fronts_by_note(SAMPLE_QUESTIONS)
    return {
        "decks": [
            {
                "slug": deck.slug,
                "name": deck.name,
                "subdecks": [
                    {
                        "slug": subdeck.slug,
                        "name": subdeck.name,
                        "notes": [
                            {
                                "title": note.title,
                                "cards": note.total_cards,
                                "unseen": note.unseen_cards,
                                "sample_questions": [q[:SAMPLE_LENGTH] for q in samples.get(note.title, [])],
                            }
                            for note in study.notes(user, subdeck.slug)
                        ],
                    }
                    for subdeck in deck.subdecks
                ],
                "notes": [
                    {
                        "title": note.title,
                        "cards": note.total_cards,
                        "unseen": note.unseen_cards,
                        "sample_questions": [q[:SAMPLE_LENGTH] for q in samples.get(note.title, [])],
                    }
                    for note in study.notes(user, deck.slug)
                ],
            }
            for deck in study.overview(user).decks
        ]
    }


def _search_topics(queries: list[str]) -> dict:
    try:
        found = semantic.search_notes(queries)
        missing = semantic.missing_embeddings()
    except EmbeddingsUnavailable as exc:
        raise ToolError(f"{exc} Chiama flashcards_find_topics senza `query` e abbina tu i titoli.") from exc
    return {
        "matches": {
            query: [{"title": m.title, "deck": m.deck_slug, "similarity": m.similarity} for m in matches]
            for query, matches in found.items()
        },
        "cards_not_indexed": missing,
    }


def preview_temporary_deck(user, **filters) -> dict:
    preview = _translate_errors(temporary_decks.preview_temporary_deck, user, **filters)
    draft = preview.draft
    return {
        "draft_id": draft.pk,
        "name": draft.name,
        "total": len(draft.card_ids),
        "by_note": [{"note": n.note, "taken": n.taken, "available": n.available} for n in preview.by_note],
        "adjustments": preview.adjustments,
        "draft_expires_at": draft.expires_at.isoformat(),
    }


def create_temporary_deck(user, draft_id: int, name: str | None) -> dict:
    created = _translate_errors(temporary_decks.create_from_draft, user, draft_id, name)
    deck = created.deck
    return {
        "temporary_deck_id": deck.pk,
        "name": deck.name,
        "total": deck.entries.count(),
        "by_note": [{"note": n.note, "taken": n.taken, "available": n.available} for n in created.by_note],
        "adjustments": created.adjustments,
        "expires_at": deck.expires_at.isoformat(),
    }


def _translate_errors(service, *args, **kwargs):
    try:
        return service(*args, **kwargs)
    except temporary_decks.NoCards as exc:
        raise ToolError(f"Nessun mazzo creato. {exc} Dillo all'utente.") from exc
    except temporary_decks.TemporaryDeckNotFound as exc:
        raise ToolError(
            f"Mazzo provvisorio {exc} non trovato. Usa flashcards_list_temporary_decks per trovare quello giusto."
        ) from exc
    except temporary_decks.DraftNotFound as exc:
        raise ToolError(
            f"Anteprima {exc} inesistente o scaduta (vale 30 minuti). Rifai flashcards_preview_temporary_deck."
        ) from exc
    except EmbeddingsUnavailable as exc:
        raise ToolError(f"{exc} Rifai l'anteprima senza `about`, usando `notes`.") from exc
    except ValueError as exc:
        raise ToolError(f"Parametri non validi: {exc}.") from exc


def list_temporary_decks(user, limit: int) -> dict:
    return {
        "temporary_decks": [
            {
                "id": deck.id,
                "name": deck.name,
                "created_at": deck.created_at.isoformat(),
                "expires_at": deck.expires_at.isoformat(),
                "expired": deck.expired,
                "total": deck.total,
                "done": deck.done,
                "missed": deck.missed,
            }
            for deck in temporary_decks.list_temporary_decks(user, limit)
        ]
    }
