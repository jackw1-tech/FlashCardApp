from uuid import UUID

from django.db import transaction
from django.db.models import Count, Max, Min, Q

from apps.catalog import repositories as catalog
from apps.study import repositories
from apps.study.models import Outcome, StudySession

MAX_REVIEWS = 1000


class EmptySession(Exception):
    pass


@transaction.atomic
def save_session(
    user,
    *,
    client_id: UUID,
    review_ids: list[int],
    deck_slug: str | None = None,
    note_title: str | None = None,
    temporary_deck_id: int | None = None,
) -> tuple[StudySession, bool]:
    existing = repositories.get_session(user, client_id)
    if existing is not None:
        return existing, False

    reviews = repositories.valid_reviews(user).filter(pk__in=review_ids[:MAX_REVIEWS])
    summary = reviews.aggregate(
        total=Count("id"),
        knew=Count("id", filter=Q(outcome=Outcome.KNEW)),
        started=Min("created_at"),
        ended=Max("created_at"),
    )
    if summary["total"] == 0:
        raise EmptySession()

    session = repositories.create_session(
        user,
        client_id=client_id,
        deck=catalog.get_deck(deck_slug) if deck_slug else None,
        note_title=note_title or "",
        temporary_deck=repositories.get_temporary_deck(user, temporary_deck_id) if temporary_deck_id else None,
        started_at=summary["started"],
        ended_at=summary["ended"],
        knew=summary["knew"],
        didnt_know=summary["total"] - summary["knew"],
        reviews=list(reviews),
    )
    return session, True


def recent_sessions(user, limit: int = 20) -> list[StudySession]:
    return repositories.recent_sessions(user, limit)
