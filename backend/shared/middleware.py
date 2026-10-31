from django.conf import settings
from django.db import DEFAULT_DB_ALIAS
from django.http import JsonResponse

from shared.db_router import replica_reads
from shared.read_consistency import ReadPolicy, remember_seen

SAFE_METHODS = {"GET", "HEAD", "OPTIONS"}


class ApiCsrfHeaderMiddleware:

    def __init__(self, get_response):
        self.get_response = get_response
        self.header = "HTTP_" + settings.CSRF_HEADER_NAME_API.upper().replace("-", "_")

    def __call__(self, request):
        if request.path.startswith("/api/") and request.method not in SAFE_METHODS and not request.META.get(self.header):
            return JsonResponse(
                {"detail": f"Header {settings.CSRF_HEADER_NAME_API} mancante."},
                status=403,
            )
        return self.get_response(request)


def reads_from_replica(request) -> bool:
    return (
        settings.READ_REPLICA_MODE in {"always", "lsn"}
        and request.method in SAFE_METHODS
        and request.path.startswith("/api/")
        and not request.path.startswith("/api/auth/")
    )


class ReadReplicaMiddleware:

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        policy = (
            ReadPolicy(request, check_marker=settings.READ_REPLICA_MODE == "lsn") if reads_from_replica(request) else None
        )
        with replica_reads(policy):
            response = self.get_response(request)
        replica = policy.alias if policy is not None and policy.decided else None
        response["X-Read-From"] = replica or "primary"
        if response.status_code < 400:
            if self._wrote(request):
                remember_seen(request.user, DEFAULT_DB_ALIAS)
            elif policy is not None:
                policy.remember_seen()
        return response

    @staticmethod
    def _wrote(request) -> bool:
        user = getattr(request, "user", None)
        return (
            settings.READ_REPLICA_MODE == "lsn"
            and request.method not in SAFE_METHODS
            and request.path.startswith("/api/")
            and user is not None
            and user.is_authenticated
        )

