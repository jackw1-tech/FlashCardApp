from django.conf import settings
from django.contrib import admin
from django.urls import include, path

from shared.api import health

urlpatterns = [
    path(settings.ADMIN_URL, admin.site.urls),
    path("api/health/", health, name="health"),
    path("api/", include("apps.accounts.api.urls")),
    path("api/", include("apps.study.api.urls")),
    path("api/", include("apps.catalog.api.urls")),
    path("api/", include("apps.assistant.api.urls")),
]
