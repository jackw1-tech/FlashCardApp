def test_health_risponde_ok_con_il_db_acceso(anon, db):
    response = anon.get("/api/health/")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_le_api_rifiutano_le_richieste_senza_token(anon, db):
    assert anon.get("/api/decks/").status_code == 401


def test_le_api_rifiutano_un_cookie_di_accesso_sbagliato(anon, db):
    anon.cookies["fc_access"] = "non-un-jwt"

    assert anon.get("/api/decks/").status_code == 401
