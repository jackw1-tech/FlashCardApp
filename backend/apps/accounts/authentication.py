from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed

from apps.accounts.api.cookies import ACCESS_COOKIE
from apps.accounts.services import auth


class CookieJWTAuthentication(BaseAuthentication):

    def authenticate(self, request):
        value = request.COOKIES.get(ACCESS_COOKIE)
        if not value:
            return None
        try:
            return auth.authenticate_access(value)
        except auth.NotAuthenticated:
            raise AuthenticationFailed("Sessione non valida o scaduta.")

    def authenticate_header(self, request) -> str:
        return 'Cookie realm="api"'
