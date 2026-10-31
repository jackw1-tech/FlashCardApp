from collections.abc import Callable
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path

from django.db import transaction
from django.utils import timezone

from apps.catalog import repositories
from apps.catalog.models import Card, Deck
from apps.catalog.services.parser import NOTE_PREFIX, ParsedCard, parse_note
from shared import cache


class ImportAborted(Exception):
    pass


@dataclass(frozen=True)
class ImportProblem:
    filename: str
    line_number: int | None
    message: str


@dataclass
class ImportReport:
    notes: int = 0
    cards: int = 0
    created: int = 0
    updated: int = 0
    archived: int = 0
    restored: int = 0
    problems: list[ImportProblem] = field(default_factory=list)


def find_notes(root: Path) -> list[Path]:
    return sorted(
        path
        for path in root.rglob(f"{NOTE_PREFIX}*.md")
        if not any(part.startswith(".") for part in path.relative_to(root).parts)
    )


def file_modified_at(path: Path) -> datetime:
    return datetime.fromtimestamp(path.stat().st_mtime, tz=UTC)


@transaction.atomic
def import_vault(
    root: Path,
    modified_at: Callable[[Path], datetime] = file_modified_at,
    max_archived_ratio: float | None = None,
) -> ImportReport:
    report = ImportReport()
    parsed = _parse_vault(root, report, modified_at)
    report.cards = len(parsed)
    existing = repositories.cards_by_key()
    by_content: dict[tuple[str, str, str], list[Card]] = {}
    for old in existing.values():
        if old.archived_at is None:
            by_content.setdefault((old.note_title, old.kind, " ".join(old.front.split())), []).append(old)
    claimed: set[int] = set()
    now = timezone.now()
    decks: dict[str, Deck] = {}

    to_create: list[Card] = []
    to_update: list[Card] = []
    for key, (deck_slug, title, modified_at, new) in parsed.items():
        card = existing.get(key)
        if card is None:
            candidates = [
                candidate
                for candidate in by_content.get((title, new.kind, " ".join(new.front.split())), [])
                if candidate.pk not in claimed
            ]
            card = candidates[0] if len(candidates) == 1 else None
        if card is None:
            if deck_slug not in decks:
                decks[deck_slug] = repositories.get_or_create_deck(deck_slug)
            to_create.append(
                Card(
                    key=key,
                    deck=decks[deck_slug],
                    note_title=title,
                    kind=new.kind,
                    front=new.front,
                    back=new.back,
                    line_number=new.line_number,
                    note_modified_at=modified_at,
                )
            )
            continue

        claimed.add(card.pk)
        if deck_slug not in decks:
            decks[deck_slug] = repositories.get_or_create_deck(deck_slug)

        content_changed = (card.kind, card.front, card.back) != (new.kind, new.front, new.back)
        restored = card.archived_at is not None
        moved = card.line_number != new.line_number
        regrouped = card.key != key or card.deck_id != decks[deck_slug].pk
        if not (content_changed or restored or moved or regrouped or card.note_modified_at != modified_at):
            continue
        if restored:
            report.restored += 1
        elif content_changed:
            report.updated += 1
        card.key, card.deck = key, decks[deck_slug]
        card.kind, card.front, card.back, card.line_number = new.kind, new.front, new.back, new.line_number
        card.note_modified_at = modified_at
        card.archived_at = None
        card.updated_at = now
        to_update.append(card)

    retained = {card.pk for card in to_update}
    retained.update(existing[key].pk for key in parsed.keys() & existing.keys())
    stale = [card for card in existing.values() if card.pk not in retained and card.archived_at is None]
    active = sum(1 for card in existing.values() if card.archived_at is None)
    if max_archived_ratio is not None and active and len(stale) / active > max_archived_ratio:
        raise ImportAborted(
            f"L'import archivierebbe {len(stale)} card su {active} attive ({len(stale) / active:.0%}): "
            f"controlla che il Vault sia completo (commit e push?) o rilancia con --force."
        )

    repositories.create_cards(to_create)
    repositories.update_cards(
        to_update,
        ["key", "deck", "kind", "front", "back", "line_number", "note_modified_at", "archived_at", "updated_at"],
    )
    if stale:
        repositories.archive_cards(stale, now)

    report.created = len(to_create)
    report.archived = len(stale)
    if to_create or to_update or stale:
        cache.bump_catalog_version()
    return report


def _parse_vault(
    root: Path, report: ImportReport, modified_at: Callable[[Path], datetime]
) -> dict[str, tuple[str, str, datetime, ParsedCard]]:
    cards: dict[str, tuple[str, str, datetime, ParsedCard]] = {}
    for path in find_notes(root):
        report.notes += 1
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            report.problems.append(ImportProblem(path.name, None, "file non in UTF-8: saltato"))
            continue
        note_modified_at = modified_at(path)
        note = parse_note(text, path.name)
        report.problems += [ImportProblem(path.name, p.line_number, p.message) for p in note.problems]
        for card in note.cards:
            if card.key in cards:
                report.problems.append(ImportProblem(path.name, card.line_number, "card già presente in un'altra nota"))
                continue
            cards[card.key] = (note.deck_slug, note.title, note_modified_at, card)
    return cards
