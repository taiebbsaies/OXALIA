import uuid

import pytest


@pytest.mark.asyncio
async def test_register_and_login(client):
    email = f"doc_{uuid.uuid4().hex}@test.com"
    password = "StrongPassw0rd!"

    resp = await client.post(
        "/auth/register",
        json={"email": email, "password": password, "full_name": "Dr Test"},
    )
    assert resp.status_code == 201
    assert resp.json()["email"] == email
    assert resp.json()["role"] == "clinician"

    resp = await client.post(
        "/auth/login",
        json={"email": email, "password": password},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert "access_token" in body
    assert "refresh_token" in body
    assert body["token_type"] == "bearer"
