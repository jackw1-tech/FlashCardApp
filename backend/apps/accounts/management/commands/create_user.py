from getpass import getpass

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = "Crea un utente dell'app (o ne cambia la password). Non c'è registrazione dall'app."

    def add_arguments(self, parser):
        parser.add_argument("username")
        parser.add_argument("--admin", action="store_true", help="abilita anche l'accesso all'admin")

    def handle(self, *args, username: str, admin: bool, **options):
        password = getpass("Password: ")
        if len(password) < 8:
            raise CommandError("La password deve avere almeno 8 caratteri.")
        if getpass("Ripeti la password: ") != password:
            raise CommandError("Le password non coincidono.")
        user, created = get_user_model().objects.get_or_create(username=username)
        user.set_password(password)
        if admin:
            user.is_staff = user.is_superuser = True
        user.save()
        self.stdout.write(f"Utente {'creato' if created else 'aggiornato'}: {username}")
