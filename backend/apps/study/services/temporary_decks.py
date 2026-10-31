import difflib
from dataclasses import asdict, dataclass
from datetime import datetime, time, timedelta
from zoneinfo import ZoneInfo

from django.conf import settings
from django.db import transaction
from django.db.models import Exists, OuterRef, QuerySet
from django.utils import timezone

from apps.catalog import repositories as catalog
from apps.catalog.models import Card
from apps.catalog.services import semantic
from apps.study import repositories
from apps.study.models import TemporaryDeck, TemporaryDeckDraft

DEFAULT_COUNT = 20
MAX_COUNT = 200
MAX_DAYS = 365
ORDERS = ("least_recent", "worst_first")
SIMILAR_TITLES = 3
DRAFT_TTL = timedelta(minutes=30)


class TemporaryDeckNotFound(Exception):
    pass


class NoCards(Exception):
    pass


class DraftNotFound(Exception):
    pass


@dataclass(frozen=True)
class NoteTaken:
    note: str | None
    taken: int
    available: int


@dataclass(frozen=True)
class CreatedTemporaryDeck:
    deck: TemporaryDeck
    by_note: list[NoteTaken]
    adjustments: list[str]


@dataclass(frozen=True)
class Selection:
    cards: list[Card]
    name: str
    by_note: list[NoteTaken]
    adjustments: list[str]


@dataclass(frozen=True)
class Preview:
    draft: TemporaryDeckDraft
    by_note: list[NoteTaken]
    adjustments: list[str]


@dataclass(frozen=True)
class TemporaryDeckSummary:
    id: int
    name: str
    created_at: datetime
    expires_at: datetime
    expired: bool
    total: int
    done: int
    missed: int


@transaction.atomic
def create_temporary_deck(user, **filters) -> CreatedTemporaryDeck:
    selection = select_cards(user, **filters)
    deck = repositories.create_temporary_deck(user, selection.name, _deck_expiry(), selection.cards)
    return CreatedTemporaryDeck(deck, selection.by_note, selection.adjustments)


@transaction.atomic
def preview_temporary_deck(user, **filters) -> Preview:
    selection = select_cards(user, **filters)
    draft = repositories.create_draft(
        user,
        name=selection.name,
        card_ids=[card.pk for card in selection.cards],
        by_note=[asdict(n) for n in selection.by_note],
        adjustments=selection.adjustments,
        expires_at=timezone.now() + DRAFT_TTL,
    )
    return Preview(draft, selection.by_note, selection.adjustments)


@transaction.atomic
def create_from_draft(user, draft_id: int, name: str | None = None) -> CreatedTemporaryDeck:
    draft = repositories.get_draft_for_update(user, draft_id)
    if draft is None:
        raise DraftNotFound(draft_id)
    by_note = [NoteTaken(**n) for n in draft.by_note]
    if draft.temporary_deck is not None:
        return CreatedTemporaryDeck(draft.temporary_deck, by_note, draft.adjustments)
    if draft.expires_at <= timezone.now():
        raise DraftNotFound(draft_id)

    cards = repositories.active_cards_in_order(draft.card_ids)
    adjustments = list(draft.adjustments)
    if len(cards) < len(draft.card_ids):
        adjustments.append(
            f"{len(draft.card_ids) - len(cards)} card dell'anteprima sono state tolte dal vault nel frattempo."
        )
    if not cards:
        raise NoCards("Tutte le card dell'anteprima sono state tolte dal vault nel frattempo.")
    deck = repositories.create_temporary_deck(user, name or draft.name, _deck_expiry(), cards)
    repositories.mark_draft_used(draft, deck)
    return CreatedTemporaryDeck(deck, by_note, adjustments)


def select_cards(
    user,
    *,
    notes: list[str] | None = None,
    count: int | None = None,
    modified: str | None = None,
    missed_in_days: int | None = None,
    missed_in_deck: int | None = None,
    about: str | None = None,
    order: str = "least_recent",
    name: str | None = None,
) -> Selection:
    count = DEFAULT_COUNT if count is None else count
    _validate(count, modified, missed_in_days, order)
    tz = ZoneInfo(settings.STUDY_TIME_ZONE)
    now = timezone.now()
    adjustments: list[str] = []

    scope = catalog.active_cards()
    if modified == "today":
        scope = scope.filter(note_modified_at__gte=_start_of_day(now, tz))
    titles: list[str | None] = [None]
    if notes:
        titles, unknown = _resolve_titles(notes)
        adjustments += [_unknown_title_message(title) for title in unknown]
        if not titles:
            raise NoCards("Nessuna delle note richieste esiste. " + " ".join(adjustments))
        scope = scope.filter(note_title__in=titles)
    if about:
        scope = semantic.cards_about(scope, about)

    cards = scope
    since = now - timedelta(days=missed_in_days) if missed_in_days else None
    if since is not None:
        cards = cards.filter(Exists(repositories.missed_since(user, since).filter(card=OuterRef("pk"))))
    source = None
    if missed_in_deck is not None:
        source = repositories.get_temporary_deck(user, missed_in_deck)
        if source is None:
            raise TemporaryDeckNotFound(missed_in_deck)
        cards = cards.filter(pk__in=repositories.missed_cards(user, source).values("pk"))

    groups = [cards if title is None else cards.filter(note_title=title) for title in titles]
    available = [group.count() for group in groups]
    if sum(available) == 0:
        raise NoCards(_no_cards_reason(user, scope, modified, since, missed_in_days, source, about, now, tz))

    taken = split_equally(count, available)
    if notes:
        shares = split_equally(count, [count] * len(titles))
        adjustments += [
            f'"{title}" ha solo {n} card che rispettano i filtri: le mancanti sono andate alle altre note.'
            for title, n, share in zip(titles, available, shares)
            if n < share
        ]
    if sum(taken) < count:
        adjustments.append(f"Chieste {count} card, ne esistono {sum(taken)} che rispettano i filtri.")

    chosen: list[Card] = []
    for group, n in zip(groups, taken):
        chosen += repositories.order_for_study(user, group, order)[:n]
    return Selection(
        cards=chosen,
        name=name or _default_name(titles, modified, missed_in_days, source, about),
        by_note=[NoteTaken(title, n, a) for title, n, a in zip(titles, taken, available)],
        adjustments=adjustments,
    )


def list_temporary_decks(user, limit: int = 5, *, active_only: bool = False) -> list[TemporaryDeckSummary]:
    now = timezone.now()
    return [
        TemporaryDeckSummary(
            id=deck.pk,
            name=deck.name,
            created_at=deck.created_at,
            expires_at=deck.expires_at,
            expired=deck.expires_at <= now,
            total=deck.total,
            done=repositories.done_cards(user, deck).count(),
            missed=repositories.missed_cards(user, deck).count(),
        )
        for deck in repositories.recent_temporary_decks(user, limit, active_after=now if active_only else None)
    ]


@transaction.atomic
def delete_temporary_deck(user, pk: int) -> None:
    deck = repositories.get_temporary_deck(user, pk)
    if deck is None:
        raise TemporaryDeckNotFound(pk)
    repositories.delete_temporary_deck(deck)


def get_active_temporary_deck(user, pk: int) -> TemporaryDeck:
    deck = repositories.get_temporary_deck(user, pk)
    if deck is None or deck.expires_at <= timezone.now():
        raise TemporaryDeckNotFound(pk)
    return deck


def split_equally(count: int, available: list[int]) -> list[int]:
    taken = [0] * len(available)
    remaining = count
    open_groups = [i for i, n in enumerate(available) if n > 0]
    while remaining > 0 and open_groups:
        share, extra = divmod(remaining, len(open_groups))
        for position, i in enumerate(open_groups):
            give = min(share + (1 if position < extra else 0), available[i] - taken[i])
            taken[i] += give
            remaining -= give
        open_groups = [i for i in open_groups if taken[i] < available[i]]
    return taken


def _validate(count: int, modified: str | None, missed_in_days: int | None, order: str) -> None:
    if not 1 <= count <= MAX_COUNT:
        raise ValueError(f"count deve essere tra 1 e {MAX_COUNT}")
    if modified not in (None, "today"):
        raise ValueError('modified accetta solo "today"')
    if missed_in_days is not None and not 1 <= missed_in_days <= MAX_DAYS:
        raise ValueError(f"missed_in_days deve essere tra 1 e {MAX_DAYS}")
    if order not in ORDERS:
        raise ValueError(f"order deve essere uno di {', '.join(ORDERS)}")


def _resolve_titles(requested: list[str]) -> tuple[list[str], list[str]]:
    by_lower = {title.lower(): title for title in catalog.active_note_titles()}
    found: list[str] = []
    unknown: list[str] = []
    for title in requested:
        match = by_lower.get(title.strip().lower())
        if match is None:
            unknown.append(title)
        elif match not in found:
            found.append(match)
    return found, unknown


def similar_titles(title: str) -> list[str]:
    titles = catalog.active_note_titles()
    needle = title.strip().lower()
    containing = [t for t in titles if needle and needle in t.lower()]
    by_lower = {t.lower(): t for t in titles}
    close = [by_lower[t] for t in difflib.get_close_matches(needle, list(by_lower), n=SIMILAR_TITLES, cutoff=0.6)]
    return list(dict.fromkeys(containing + close))[:SIMILAR_TITLES]


def _unknown_title_message(title: str) -> str:
    similar = ", ".join(f'"{t}"' for t in similar_titles(title))
    hint = f" Simili: {similar}." if similar else ""
    return f'Nota "{title}" non trovata.{hint}'


def _no_cards_reason(
    user,
    scope: QuerySet[Card],
    modified: str | None,
    since: datetime | None,
    missed_in_days: int | None,
    source: TemporaryDeck | None,
    about: str | None,
    now: datetime,
    tz: ZoneInfo,
) -> str:
    if modified == "today" and not catalog.active_cards().filter(note_modified_at__gte=_start_of_day(now, tz)).exists():
        return "Oggi non è stata modificata nessuna nota."
    if about and not scope.exists():
        return (
            f'Nessuna card parla abbastanza di "{about}". Le card aggiunte da poco potrebbero non essere ancora '
            "indicizzate (embed_cards)."
        )
    if not scope.exists():
        return "Nessuna card rispetta i filtri richiesti."
    if since is not None:
        answered = repositories.answered_since(user, since).filter(card__in=scope).count()
        if answered == 0:
            return f"Negli ultimi {missed_in_days} giorni l'utente non ha ripassato nessuna di queste card."
        if not repositories.missed_since(user, since).filter(card__in=scope).exists():
            return f"Negli ultimi {missed_in_days} giorni l'utente ha risposto {answered} volte senza sbagliare."
    if source is not None:
        return f'Nel mazzo "{source.name}" non ci sono card sbagliate dopo la sua creazione.'
    return "Nessuna card rispetta tutti i filtri insieme."


def _default_name(
    titles: list[str | None],
    modified: str | None,
    missed_in_days: int | None,
    source: TemporaryDeck | None,
    about: str | None,
) -> str:
    named = [t for t in titles if t is not None]
    parts = []
    if named:
        parts.append(named[0] if len(named) == 1 else ", ".join(named[:-1]) + " e " + named[-1])
    if about:
        parts.append(about)
    if modified == "today":
        parts.append("note di oggi")
    if missed_in_days:
        parts.append(f"sbagliate negli ultimi {missed_in_days} giorni")
    if source is not None:
        parts.append(f'sbagliate in "{source.name}"')
    name = " · ".join(parts) or "Ripasso"
    return (name[0].upper() + name[1:])[:200]


def _start_of_day(now: datetime, tz: ZoneInfo) -> datetime:
    return datetime.combine(timezone.localdate(now, timezone=tz), time.min, tzinfo=tz)


def _deck_expiry() -> datetime:
    return _start_of_day(timezone.now(), ZoneInfo(settings.STUDY_TIME_ZONE)) + timedelta(days=1)
