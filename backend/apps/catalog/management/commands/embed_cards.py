from django.core.management.base import BaseCommand, CommandError

from apps.catalog.services.embeddings import EmbeddingsUnavailable, embed_cards


class Command(BaseCommand):
    help = "Calcola gli embedding mancanti o vecchi delle card attive (da lanciare dopo import_vault)."

    def handle(self, *args, **options):
        try:
            report = embed_cards(progress=lambda line: self.stdout.write(f"  {line}"))
        except EmbeddingsUnavailable as exc:
            raise CommandError(str(exc)) from exc
        self.stdout.write(f"Embedding calcolati: {report.embedded}, già aggiornati: {report.up_to_date}")
