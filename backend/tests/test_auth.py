from datetime import timedelta

import jwt
import pytest
import redis
from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import RefreshToken
from tests.conftest import CSRF_HEADER

PASSWORD = "una-password-lunga"


@pytest.fixture
def account(db):
    return get_user_model().objects.create_user("giacomo", password=PASSWORD)


@pytest.fixture
def browser() -> APIClient:
    client = APIClient()
    client.credentials(**CSRF_HEADER)
    return client


def login(client, username="giacomo", password=PASSWORD, ip="10.0.0.1"):
    return client.post("/api/auth/login/", {"username": username, "password": password}, format="json", REMOTE_ADDR=ip)


def session(client):
    return client.get("/api/auth/session/")


def test_il_login_imposta_due_cookie_httponly_e_restituisce_utente_e_scadenze(browser, account):
    response = login(browser)

    assert response.status_code == 200
    body = response.json()
    assert body["user"] == {"id": account.id, "username": "giacomo"}
    assert body["access_expires_at"] and body["refresh_expires_at"]

    access, refresh = response.cookies["fc_access"], response.cookies["fc_refresh"]
    assert access["httponly"] and refresh["httponly"]
    assert (access["path"], refresh["path"]) == ("/api", "/api/auth")
    assert access["samesite"] == refresh["samesite"] == "Lax"
    assert int(access["max-age"]) == settings.ACCESS_TOKEN_LIFETIME_SECONDS
    assert int(refresh["max-age"]) == settings.REFRESH_TOKEN_LIFETIME_SECONDS


def test_i_token_non_compaiono_nel_body(browser, account):
    body = login(browser).content.decode()

    assert browser.cookies["fc_access"].value not in body
    assert browser.cookies["fc_refresh"].value not in body


def test_credenziali_sbagliate_rispondono_401_senza_cookie(browser, account):
    response = login(browser, password="sbagliata")

    assert response.status_code == 401
    assert "fc_access" not in response.cookies


def test_dopo_il_login_le_api_funzionano_con_il_cookie(browser, account):
    login(browser)

    assert browser.get("/api/decks/").status_code == 200


def test_senza_cookie_le_api_rispondono_401(browser, account):
    assert browser.get("/api/decks/").status_code == 401


def test_un_access_scaduto_viene_rifiutato(browser, account):
    expired = jwt.encode(
        {"sub": str(account.id), "jti": "x", "exp": timezone.now() - timedelta(seconds=1), "typ": "access"},
        settings.JWT_SIGNING_KEY,
        algorithm="HS256",
    )
    browser.cookies["fc_access"] = expired

    assert browser.get("/api/decks/").status_code == 401


def test_un_utente_disattivato_non_entra_piu(browser, account):
    login(browser)
    account.is_active = False
    account.save()

    assert browser.get("/api/decks/").status_code == 401


def test_session_con_access_valido_restituisce_l_utente_senza_ruotare(browser, account):
    login(browser)
    refresh_before = browser.cookies["fc_refresh"].value

    response = session(browser)

    assert response.status_code == 200
    assert response.json()["user"]["username"] == "giacomo"
    assert response.json()["refresh_expires_at"] is None
    assert "fc_refresh" not in response.cookies
    assert browser.cookies["fc_refresh"].value == refresh_before


def test_session_con_access_scaduto_ruota_il_refresh_in_un_solo_round_trip(browser, account):
    login(browser)
    old_refresh = browser.cookies["fc_refresh"].value
    del browser.cookies["fc_access"]

    response = session(browser)

    assert response.status_code == 200
    assert response.json()["refresh_expires_at"] is not None
    assert response.cookies["fc_access"].value
    assert browser.cookies["fc_refresh"].value != old_refresh
    assert browser.get("/api/decks/").status_code == 200


def test_session_senza_cookie_risponde_401(browser, account):
    assert session(browser).status_code == 401


def test_session_e_una_richiesta_semplice_senza_header_personalizzati(account):
    client = APIClient()
    login_client = APIClient()
    login_client.credentials(**CSRF_HEADER)
    login(login_client)
    client.cookies = login_client.cookies

    assert session(client).status_code == 200


def test_riusare_un_refresh_gia_ruotato_revoca_tutta_la_famiglia(browser, account):
    login(browser)
    stolen = browser.cookies["fc_refresh"].value
    del browser.cookies["fc_access"]
    session(browser)
    legit_refresh = browser.cookies["fc_refresh"].value
    RefreshToken.objects.update(used_at=timezone.now() - timedelta(minutes=5))

    thief = APIClient()
    thief.cookies["fc_refresh"] = stolen
    assert session(thief).status_code == 401

    victim = APIClient()
    victim.cookies["fc_refresh"] = legit_refresh
    assert session(victim).status_code == 401
    assert not RefreshToken.objects.filter(revoked_at__isnull=True).exists()


def test_due_refresh_quasi_simultanei_non_revocano_la_famiglia(browser, account):
    login(browser)
    old_refresh = browser.cookies["fc_refresh"].value
    del browser.cookies["fc_access"]
    session(browser)

    other_tab = APIClient()
    other_tab.cookies["fc_refresh"] = old_refresh
    response = session(other_tab)

    assert response.status_code == 409
    assert RefreshToken.objects.filter(revoked_at__isnull=True).exists()


def test_un_refresh_scaduto_non_vale(browser, account):
    login(browser)
    del browser.cookies["fc_access"]
    RefreshToken.objects.update(expires_at=timezone.now() - timedelta(seconds=1))

    assert session(browser).status_code == 401


def test_il_logout_rende_subito_inutili_access_e_refresh(browser, account):
    login(browser)
    access, refresh = browser.cookies["fc_access"].value, browser.cookies["fc_refresh"].value

    response = browser.post("/api/auth/logout/")

    assert response.status_code == 204
    assert response.cookies["fc_access"]["max-age"] == 0
    replay = APIClient()
    replay.cookies["fc_access"] = access
    assert replay.get("/api/decks/").status_code == 401
    replay = APIClient()
    replay.cookies["fc_refresh"] = refresh
    assert session(replay).status_code == 401


def test_le_richieste_che_scrivono_senza_header_vengono_rifiutate(account):
    client = APIClient()

    assert client.post("/api/auth/login/", {"username": "giacomo", "password": PASSWORD}, format="json").status_code == 403


def test_le_get_non_richiedono_l_header(account):
    assert APIClient().get("/api/health/").status_code == 200


def test_dopo_troppi_tentativi_sbagliati_il_login_risponde_429(browser, account):
    for _ in range(settings.LOGIN_RATE_LIMIT):
        assert login(browser, password="sbagliata").status_code == 401

    assert login(browser).status_code == 429


def test_il_limite_vale_anche_per_username_da_ip_diversi(browser, account):
    for i in range(settings.LOGIN_RATE_LIMIT):
        login(browser, password="sbagliata", ip=f"10.0.1.{i}")

    assert login(browser, ip="10.0.9.9").status_code == 429


def test_un_login_riuscito_non_consuma_tentativi(browser, account):
    for _ in range(settings.LOGIN_RATE_LIMIT + 2):
        assert login(browser).status_code == 200


@pytest.fixture
def redis_down(monkeypatch):
    def broken(*args, **kwargs):
        raise redis.ConnectionError("Redis giù (simulato)")

    with monkeypatch.context() as patch:
        patch.setattr(redis.Redis, "execute_command", broken)
        patch.setattr(redis.client.Pipeline, "execute", broken)
        yield


def test_con_redis_giu_login_e_api_funzionano_ancora(browser, account, redis_down):
    assert login(browser).status_code == 200
    assert browser.get("/api/decks/").status_code == 200
