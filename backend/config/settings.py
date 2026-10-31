import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent


def env_bool(name: str, default: bool = False) -> bool:
    return os.environ.get(name, str(default)).lower() in {"1", "true", "yes"}


SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
DEBUG = env_bool("DJANGO_DEBUG")
ALLOWED_HOSTS = [h for h in os.environ.get("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",") if h]
CSRF_TRUSTED_ORIGINS = [o for o in os.environ.get("DJANGO_CSRF_TRUSTED_ORIGINS", "").split(",") if o]
ADMIN_URL = os.environ.get("DJANGO_ADMIN_URL", "admin/")

SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
if not DEBUG:
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SECURE_HSTS_SECONDS = int(os.environ.get("DJANGO_HSTS_SECONDS", "0"))
    SECURE_HSTS_INCLUDE_SUBDOMAINS = env_bool("DJANGO_HSTS_INCLUDE_SUBDOMAINS")

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {"console": {"class": "logging.StreamHandler"}},
    "root": {"handlers": ["console"], "level": os.environ.get("DJANGO_LOG_LEVEL", "INFO")},
}

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "corsheaders",
    "rest_framework",
    "shared",
    "apps.accounts",
    "apps.catalog",
    "apps.study",
    "apps.assistant",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "shared.middleware.ReadReplicaMiddleware",
    "shared.middleware.ApiCsrfHeaderMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("POSTGRES_DB", "flashcards"),
        "USER": os.environ.get("POSTGRES_USER", "flashcards"),
        "PASSWORD": os.environ.get("POSTGRES_PASSWORD", ""),
        "HOST": os.environ.get("POSTGRES_HOST", "localhost"),
        "PORT": os.environ.get("POSTGRES_PORT", "5432"),
        "OPTIONS": {"connect_timeout": 3},
        "CONN_MAX_AGE": int(os.environ.get("DJANGO_CONN_MAX_AGE", "60")),
        "CONN_HEALTH_CHECKS": True,
    }
}

READ_REPLICA_MODE = os.environ.get("READ_REPLICA_MODE", "off")
if READ_REPLICA_MODE not in {"off", "always", "lsn"}:
    raise ValueError(f"READ_REPLICA_MODE non valido: {READ_REPLICA_MODE!r}")
REPLICA_DB_ALIASES = []
for number, replica_host in enumerate(filter(None, os.environ.get("POSTGRES_REPLICA_HOSTS", "").split(",")), start=1):
    DATABASES[f"replica{number}"] = {**DATABASES["default"], "HOST": replica_host, "TEST": {"MIRROR": "default"}}
    REPLICA_DB_ALIASES.append(f"replica{number}")
DATABASE_ROUTERS = ["shared.db_router.PrimaryReplicaRouter"]

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
]

LANGUAGE_CODE = "it"
TIME_ZONE = "UTC"
STUDY_TIME_ZONE = os.environ.get("STUDY_TIME_ZONE", "Europe/Rome")
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = Path(os.environ.get("DJANGO_STATIC_ROOT", "/static"))

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": ["apps.accounts.authentication.CookieJWTAuthentication"],
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.IsAuthenticated"],
}

REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379/0")

JWT_SIGNING_KEY = os.environ.get("JWT_SIGNING_KEY", SECRET_KEY)
ACCESS_TOKEN_LIFETIME_SECONDS = int(os.environ.get("ACCESS_TOKEN_LIFETIME_SECONDS", str(7 * 24 * 3600)))
REFRESH_TOKEN_LIFETIME_SECONDS = int(os.environ.get("REFRESH_TOKEN_LIFETIME_SECONDS", str(30 * 24 * 3600)))
AUTH_COOKIE_SECURE = env_bool("AUTH_COOKIE_SECURE", True)
AUTH_COOKIE_SAMESITE = os.environ.get("AUTH_COOKIE_SAMESITE", "Lax")
LOGIN_RATE_LIMIT = int(os.environ.get("LOGIN_RATE_LIMIT", "5"))
LOGIN_RATE_WINDOW_SECONDS = int(os.environ.get("LOGIN_RATE_WINDOW_SECONDS", "60"))
CSRF_HEADER_NAME_API = "X-Requested-With"

CORS_ALLOWED_ORIGINS = [o for o in os.environ.get("CORS_ALLOWED_ORIGINS", "").split(",") if o]
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_HEADERS = ["content-type", "x-requested-with"]
CORS_EXPOSE_HEADERS = ["x-read-from"]
CORS_PREFLIGHT_MAX_AGE = 86400

MCP_TOKEN = os.environ.get("MCP_TOKEN", "")
MCP_USERNAME = os.environ.get("MCP_USERNAME", "")
MCP_PUBLIC_URL = os.environ.get("MCP_PUBLIC_URL", "http://localhost:8001/mcp")
MCP_ISSUER_URL = os.environ.get("MCP_ISSUER_URL", "http://localhost:8000")
MCP_INTERNAL_URL = os.environ.get("MCP_INTERNAL_URL", "http://mcp:8001/mcp")
MCP_ALLOWED_HOSTS = [h for h in os.environ.get("MCP_ALLOWED_HOSTS", "localhost:*,127.0.0.1:*,mcp:*").split(",") if h]

ASSISTANT_MODEL = os.environ.get("ASSISTANT_MODEL", "claude-opus-5-5")
ASSISTANT_EFFORT = os.environ.get("ASSISTANT_EFFORT", "medium")

VOYAGE_API_KEY = os.environ.get("VOYAGE_API_KEY", "")
EMBEDDINGS_MODEL = os.environ.get("EMBEDDINGS_MODEL", "voyage-4")
EMBEDDINGS_DIMENSIONS = 1024
SEMANTIC_MIN_SIMILARITY = float(os.environ.get("SEMANTIC_MIN_SIMILARITY", "0.45"))

VAULT_GIT_URL = os.environ.get("VAULT_GIT_URL", "")
VAULT_GIT_BRANCH = os.environ.get("VAULT_GIT_BRANCH", "main")
VAULT_GIT_TOKEN = os.environ.get("VAULT_GIT_TOKEN", "")
VAULT_GIT_DIR = os.environ.get("VAULT_GIT_DIR", "/var/lib/vault/repo")

