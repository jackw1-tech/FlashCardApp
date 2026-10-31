from django.utils import timezone

from apps.catalog import repositories
from apps.catalog.models import CardReport


class CardNotFound(Exception):
    pass


class ReportNotFound(Exception):
    pass


def report_card(user, card_id: int, reason: str, comment: str) -> CardReport:
    card = repositories.get_active_card(card_id)
    if card is None:
        raise CardNotFound(card_id)
    return repositories.create_report(user, card, reason, comment)


def open_reports(user) -> list[CardReport]:
    return list(repositories.open_reports(user))


def resolve_report(user, report_id: int) -> CardReport:
    report = repositories.get_report(user, report_id)
    if report is None:
        raise ReportNotFound(report_id)
    return repositories.resolve_report(report, timezone.now())
