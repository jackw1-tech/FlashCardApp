from rest_framework import status
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.request import Request
from rest_framework.response import Response

from apps.accounts.api.cookies import ACCESS_COOKIE, REFRESH_COOKIE, clear_session_cookies, set_session_cookies
from apps.accounts.api.serializers import LoginSerializer, SessionSerializer
from apps.accounts.services import auth


def _session_response(issued: auth.IssuedSession) -> Response:
    response = Response(SessionSerializer(issued).data)
    set_session_cookies(response, issued.access.value, issued.refresh)
    return response


def _unauthenticated(detail: str, code: int = status.HTTP_401_UNAUTHORIZED) -> Response:
    response = Response({"detail": detail}, status=code)
    clear_session_cookies(response)
    return response


@api_view(["POST"])
@authentication_classes([])
@permission_classes([])
def login(request: Request) -> Response:
    payload = LoginSerializer(data=request.data)
    payload.is_valid(raise_exception=True)
    try:
        issued = auth.login(**payload.validated_data, ip=request.META.get("REMOTE_ADDR", ""))
    except auth.TooManyAttempts:
        return Response({"detail": "Troppi tentativi. Riprova tra un minuto."}, status=status.HTTP_429_TOO_MANY_REQUESTS)
    except auth.InvalidCredentials:
        return Response({"detail": "Username o password non validi."}, status=status.HTTP_401_UNAUTHORIZED)
    return _session_response(issued)


@api_view(["GET"])
@authentication_classes([])
@permission_classes([])
def session(request: Request) -> Response:
    try:
        issued = auth.session(request.COOKIES.get(ACCESS_COOKIE), request.COOKIES.get(REFRESH_COOKIE))
    except auth.RefreshInProgress:
        return Response({"detail": "Rinnovo in corso, riprova."}, status=status.HTTP_409_CONFLICT)
    except auth.NotAuthenticated:
        return _unauthenticated("Nessuna sessione valida.")
    return _session_response(issued)


@api_view(["POST"])
@authentication_classes([])
@permission_classes([])
def logout(request: Request) -> Response:
    auth.logout(request.COOKIES.get(ACCESS_COOKIE), request.COOKIES.get(REFRESH_COOKIE))
    response = Response(status=status.HTTP_204_NO_CONTENT)
    clear_session_cookies(response)
    return response
