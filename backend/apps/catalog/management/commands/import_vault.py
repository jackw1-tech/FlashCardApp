from pathlib import Path

from django.core.management.base import BaseCommand, CommandError

from apps.catalog.services.importer import ImportReport, import_vault


class Command(BaseCommand):
    help = "Importa le note 'Flashcard -> *.md' da una cartella del vault Obsidian."

    def add_arguments(self, parser):
        parser.add_argument("path", type=Path, help="cartella del vault (non serve che sia un repo git)")

    def handle(self, *args, path: Path, **options):
        if not path.is_dir():
            raise CommandError(f"{path} non è una cartella")

        report = import_vault(path)
        write_report(self.stdout, self.style, f"Import da {path}", report)


def write_report(stdout, style, heading: str, report: ImportReport) -> None:
    stdout.write(f"{heading}: {report.notes} note")
    stdout.write(f"  create: {report.created}")
    stdout.write(f"  aggiornate: {report.updated}")
    stdout.write(f"  archiviate: {report.archived}")
    stdout.write(f"  ripristinate: {report.restored}")
    if report.problems:
        stdout.write(style.WARNING(f"Problemi ({len(report.problems)}):"))
        for problem in report.problems:
            where = f"{problem.filename}:{problem.line_number}" if problem.line_number else problem.filename
            stdout.write(f"  {where}  {problem.message}")

