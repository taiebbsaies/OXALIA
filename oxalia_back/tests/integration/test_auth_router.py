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


@pytest.mark.asyncio
async def test_link_phone_and_conflict(client):
    email = f"doc_{uuid.uuid4().hex}@test.com"
    password = "StrongPassw0rd!"
    await client.post(
        "/auth/register",
        json={"email": email, "password": password, "full_name": "Dr Test"},
    )
    token = (await client.post("/auth/login", json={"email": email, "password": password})).json()[
        "access_token"
    ]
    headers = {"Authorization": f"Bearer {token}"}

    resp = await client.patch(
        "/auth/me/phone", json={"phone_number": "+21655111222"}, headers=headers
    )
    assert resp.status_code == 200
    assert resp.json()["phone_number"] == "21655111222"

    email2 = f"doc_{uuid.uuid4().hex}@test.com"
    await client.post(
        "/auth/register",
        json={"email": email2, "password": password, "full_name": "Dr Other"},
    )
    token2 = (
        await client.post("/auth/login", json={"email": email2, "password": password})
    ).json()["access_token"]
    conflict = await client.patch(
        "/auth/me/phone",
        json={"phone_number": "+21655111222"},
        headers={"Authorization": f"Bearer {token2}"},
    )
    assert conflict.status_code == 409
