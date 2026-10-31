from django.urls import path

from apps.accounts.api import views

urlpatterns = [
    path("auth/login/", views.login, name="auth-login"),
    path("auth/session/", views.session, name="auth-session"),
    path("auth/logout/", views.logout, name="auth-logout"),
]
