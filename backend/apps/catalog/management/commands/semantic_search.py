from django.core.management.base import BaseCommand, CommandError

from apps.catalog.services import semantic
from apps.catalog.services.embeddings import EmbeddingsUnavailable


class Command(BaseCommand):
    help = "Prova la ricerca semantica e mostra le similarità: serve a tarare SEMANTIC_MIN_SIMILARITY."

    def add_arguments(self, parser):
        parser.add_argument("query")
        parser.add_argument("--limit", type=int, default=15)

    def handle(self, *args, query: str, limit: int, **options):
        try:
            matches = semantic.search_cards(query, limit)
        except EmbeddingsUnavailable as exc:
            raise CommandError(str(exc)) from exc
        for match in matches:
            self.stdout.write(f"{match.similarity:.3f}  [{match.card.note_title}]  {match.card.front[:80]}")
