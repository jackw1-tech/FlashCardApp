from django.conf import settings
from rest_framework.response import Response

ACCESS_COOKIE = "fc_access"
REFRESH_COOKIE = "fc_refresh"
ACCESS_PATH = "/api"
REFRESH_PATH = "/api/auth"


def _common() -> dict:
    return {"httponly": True, "secure": settings.AUTH_COOKIE_SECURE, "samesite": settings.AUTH_COOKIE_SAMESITE}


def set_session_cookies(response: Response, access: str, refresh: str | None) -> None:
    response.set_cookie(
        ACCESS_COOKIE, access, max_age=settings.ACCESS_TOKEN_LIFETIME_SECONDS, path=ACCESS_PATH, **_common()
    )
    if refresh is not None:
        response.set_cookie(
            REFRESH_COOKIE, refresh, max_age=settings.REFRESH_TOKEN_LIFETIME_SECONDS, path=REFRESH_PATH, **_common()
        )


def clear_session_cookies(response: Response) -> None:
    response.delete_cookie(ACCESS_COOKIE, path=ACCESS_PATH, samesite=settings.AUTH_COOKIE_SAMESITE)
    response.delete_cookie(REFRESH_COOKIE, path=REFRESH_PATH, samesite=settings.AUTH_COOKIE_SAMESITE)
