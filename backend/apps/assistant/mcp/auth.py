import hmac
from datetime import timedelta

import jwt
from django.conf import settings
from django.utils import timezone
from mcp.server.auth.provider import AccessToken

SCOPES = ["flashcards:read", "decks:write"]
ALGORITHM = "HS256"
TOKEN_TYPE = "mcp"
TOKEN_LIFETIME = timedelta(minutes=5)


def issue_token(user) -> str:
    now = timezone.now()
    claims = {
        "sub": user.get_username(),
        "aud": settings.MCP_PUBLIC_URL,
        "typ": TOKEN_TYPE,
        "scope": " ".join(SCOPES),
        "iat": now,
        "exp": now + TOKEN_LIFETIME,
    }
    return jwt.encode(claims, settings.JWT_SIGNING_KEY, algorithm=ALGORITHM)


class StaticTokenVerifier:

    async def verify_token(self, token: str) -> AccessToken | None:
        expected = settings.MCP_TOKEN
        if expected and hmac.compare_digest(token.encode(), expected.encode()):
            return self._access(token, "static-token", settings.MCP_USERNAME)
        try:
            claims = jwt.decode(
                token, settings.JWT_SIGNING_KEY, algorithms=[ALGORITHM], audience=settings.MCP_PUBLIC_URL
            )
        except jwt.PyJWTError:
            return None
        if claims.get("typ") != TOKEN_TYPE or not claims.get("sub"):
            return None
        return self._access(token, "app-chat", claims["sub"])

    def _access(self, token: str, client_id: str, username: str) -> AccessToken:
        return AccessToken(
            token=token, client_id=client_id, scopes=SCOPES, subject=username, resource=settings.MCP_PUBLIC_URL
        )
