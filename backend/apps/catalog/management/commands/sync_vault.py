from django.core.management.base import BaseCommand, CommandError

from apps.catalog.management.commands.import_vault import write_report
from apps.catalog.services.importer import ImportAborted
from apps.catalog.services.vault_git import VaultSyncError
from apps.catalog.services.vault_sync import VaultNotConfigured, VaultSyncInProgress, sync_vault


class Command(BaseCommand):
    help = "Aggiorna il clone del Vault da GitHub (VAULT_GIT_URL) e importa le note flashcard (ADR 0014)."

    def add_arguments(self, parser):
        parser.add_argument("--force", action="store_true", help="importa anche se archivierebbe molte card")
        parser.add_argument("--embed", action="store_true", help="dopo l'import calcola gli embedding (ADR 0013)")

    def handle(self, *args, force: bool, embed: bool, **options):
        try:
            result = sync_vault(embed=embed, force=force, progress=lambda line: self.stdout.write(f"  {line}"))
        except VaultNotConfigured as exc:
            raise CommandError("Imposta VAULT_GIT_URL (e VAULT_GIT_TOKEN se il repo è privato) nel .env") from exc
        except VaultSyncInProgress as exc:
            raise CommandError("Una sincronizzazione del Vault è già in corso.") from exc
        except (VaultSyncError, ImportAborted) as exc:
            raise CommandError(str(exc)) from exc
        self.stdout.write(f"Vault {result.branch}@{result.commit}: {result.imported.notes} note flashcard")
        write_report(self.stdout, self.style, "Import del Vault", result.imported)
        if result.embedding_error:
            raise CommandError(f"Import fatto, embedding no: {result.embedding_error}")
        if embed:
            self.stdout.write(
                f"Embedding calcolati: {result.embeddings.embedded}, già aggiornati: {result.embeddings.up_to_date}"
            )
