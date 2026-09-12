from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
import os
from uuid import uuid4

from fastapi.testclient import TestClient
import pytest
from pymongo import MongoClient

from app.config import Settings
from app.main import create_app
from app.models import GrantInput
from app.seed import DEMO_USER, PEER
from app.store import Store, now

TOKEN = "test-only-token-not-for-real-use"
EVENT = "33333333-3333-4333-8333-333333333333"


@pytest.fixture
def setup():
    database = "karma_test_" + uuid4().hex
    uri = os.environ["TEST_MONGO_URI"]
    settings = Settings(enabled=True, mongo_uri=uri, database=database, demo_auth=True,
        demo_token=TOKEN, seed=True, ifm=False, elevenlabs=False)
    client = MongoClient(uri, tz_aware=True)
    with TestClient(create_app(settings)) as api:
        api.headers["Authorization"] = "Bearer " + TOKEN
        yield api, client[database], settings
    client.drop_database(database)
    client.close()


def gift(api, key="gift-key-0001", amount=25, **extra):
    return api.post("/v1/grants", headers={"Idempotency-Key": key}, json={
        "to": PEER, "amount": amount, "category": "teaching", "reason": "Helped explain the assignment", **extra})


def test_disabled_never_connects(monkeypatch):
    def forbidden(*args, **kwargs):
        raise AssertionError("Disabled backend touched MongoDB")
    monkeypatch.setattr("app.main.MongoClient", forbidden)
    with TestClient(create_app(Settings(enabled=False))) as api:
        assert api.get("/health/live").status_code == 200
        assert api.get("/health/ready").json()["status"] == "disabled"
        for path in ["/v1/me", "/v1/catalog", "/v1/recap"]:
            assert api.get(path).status_code == 503
        assert api.post("/v1/grants", json={}).status_code == 503


def test_auth_and_reads(setup):
    api, db, _ = setup
    assert api.get("/health/ready").status_code == 200
    assert api.get("/v1/me", headers={"Authorization": "Bearer wrong"}).status_code == 401
    assert api.get("/v1/me").json()["wallet"] == 1500
    assert "wallet" not in api.get("/v1/students").json()[0]
    assert len(api.get("/v1/catalog").json()) == 7
    assert len(api.get("/v1/me/badges").json()) == 6


def test_giving_and_idempotency(setup):
    api, db, _ = setup
    first = gift(api)
    assert first.status_code == 201
    assert first.json()["wallet"] == 1475
    assert first.json()["allowanceRemaining"] == 475
    assert db.students.find_one({"_id": PEER})["wallet"] == 1525
    assert gift(api).json() == first.json()
    assert db.grants.count_documents({}) == 1
    assert db.ledger.count_documents({}) == 2
    assert gift(api, amount=30).status_code == 409
    assert api.get("/v1/me/badges").json()[0]["earned"]


def test_validation_and_limits(setup):
    api, db, _ = setup
    for amount in [0, -1, 101, 1.5, True]:
        assert gift(api, amount=amount).status_code == 422
    assert gift(api, reason="   tiny   ").status_code == 422
    assert gift(api, to=DEMO_USER).status_code == 400
    assert gift(api, to="missing-user").status_code == 404
    assert db.grants.count_documents({}) == 0
    for n in range(3):
        assert gift(api, key=f"repeat-key-{n}").status_code == 201
    assert gift(api, key="repeat-key-4").status_code == 409
    assert api.get("/v1/me").json()["wallet"] == 1425
    db.students.update_one({"_id": DEMO_USER}, {"$set": {"wallet": 5}})
    assert gift(api, key="insufficient").status_code == 409


def test_month_rollover_does_not_mint_wallet(setup):
    api, db, _ = setup
    db.students.update_one({"_id": DEMO_USER}, {"$set": {
        "wallet": 99, "allowanceRemaining": 0, "allowanceMonth": "2000-01"}})
    result = api.get("/v1/me").json()
    assert result["wallet"] == 99 and result["allowanceRemaining"] == 500
    db.students.update_one({"_id": DEMO_USER}, {"$set": {"allowanceRemaining": 5}})
    assert gift(api, amount=10).status_code == 409


def test_concurrent_retry_exactly_once(setup):
    _, db, _ = setup
    store = Store(db)
    data = GrantInput(to=PEER, amount=100, category="kindness", reason="Helped carry the groceries")
    with ThreadPoolExecutor(max_workers=5) as executor:
        results = list(executor.map(lambda _: store.give(DEMO_USER, data, "same-request-key"), range(5)))
    assert all(r == results[0] for r in results)
    assert db.grants.count_documents({}) == 1
    assert db.students.find_one({"_id": DEMO_USER})["wallet"] == 1400


def test_redemption_price_stock_rollback(setup):
    api, db, _ = setup
    def redeem(payload, key="redeem-key-1"):
        return api.post("/v1/redemptions", json=payload, headers={"Idempotency-Key": key})
    assert redeem({"optionID": "cmu-store", "amount": 1}).status_code == 422
    result = redeem({"optionID": "cmu-store"})
    assert result.status_code == 201 and result.json()["cost"] == 1250
    assert redeem({"optionID": "cmu-store"}).json() == result.json()
    db.catalog.update_one({"_id": "dining-block"}, {"$set": {"remaining": 1}})
    assert redeem({"optionID": "dining-block"}, "another-key").status_code == 409
    assert db.catalog.find_one({"_id": "dining-block"})["remaining"] == 1
    donation = redeem({"optionID": "cmu-pantry", "amount": 50}, "donation-key")
    assert donation.status_code == 201 and donation.json()["claimCode"] is None


def test_checkin_once_time_and_location(setup):
    api, db, _ = setup
    path = f"/v1/events/{EVENT}/check-in"
    headers = {"Idempotency-Key": "check-in-key"}
    assert api.post(path, json={"latitude": 0, "longitude": 0}, headers=headers).status_code == 409
    assert api.post(path, json={"latitude": 40}, headers=headers).status_code == 422
    first = api.post(path, json={}, headers=headers)
    assert first.status_code == 200
    assert api.post(path, json={}, headers=headers).json() == first.json()
    assert api.post(path, json={}, headers={"Idempotency-Key": "second-checkin"}).status_code == 409
    assert api.get("/v1/me").json()["wallet"] == 1600
    assert db.checkins.count_documents({}) == 1


def test_provider_flags_and_private_recap(setup, monkeypatch):
    api, db, _ = setup
    def no_network(*args, **kwargs):
        raise AssertionError("Provider flag allowed network access")
    monkeypatch.setattr("httpx.post", no_network)
    assert gift(api, isPublic=False).status_code == 201
    digest = api.get("/v1/recap").json()
    assert digest["source"] == "sample" and "0 public recognitions" in digest["body"][0]
    assert api.post("/v1/transcriptions", files={"file": ("test.m4a", b"test", "audio/mp4")}).status_code == 503
    assert db.recaps.count_documents({}) == 0


def test_ifm_cache_and_failure_fallback(setup, monkeypatch):
    import httpx
    api, db, settings = setup
    settings.ifm = True
    settings.ifm_key = "test-key"
    requests = []
    def generate(url, **kwargs):
        requests.append(kwargs)
        assert url == "https://api.ifm.ai/v1/chat/completions"
        assert kwargs["json"]["model"] == "IFM/K2-Horizon-375B-A23B"
        return httpx.Response(200, request=httpx.Request("POST", url), json={"choices": [{
            "finish_reason": "stop", "message": {"content": '{"headline":"Campus support this week","body":["One.","Two.","Three."],"mostHelpfulAndrewID":"invented","mostHelpfulNote":"Unsupported"}'}}]})
    monkeypatch.setattr("httpx.post", generate)
    first = api.get("/v1/recap").json()
    assert first["source"] == "live" and not first["isCached"]
    assert first["mostHelpfulAndrewID"] is None
    settings.ifm = False
    assert api.get("/v1/recap").json()["isCached"]
    assert len(requests) == 1
    db.recaps.delete_many({})
    settings.ifm = True
    def fail(*args, **kwargs):
        raise httpx.ConnectError("offline")
    monkeypatch.setattr("httpx.post", fail)
    assert api.get("/v1/recap").json()["source"] == "sample"
    assert db.recaps.count_documents({}) == 0


def test_private_grants_not_visible_to_uninvolved_user(setup):
    api, db, _ = setup
    db.grants.insert_one({"_id": str(uuid4()), "from": PEER, "to": "someone-else",
        "amount": 10, "category": "kindness", "reason": "PRIVATE_SENTINEL", "isPublic": False, "createdAt": now()})
    assert api.get("/v1/grants").json() == []
    assert "PRIVATE_SENTINEL" not in api.get("/v1/recap").text


def test_concurrent_distinct_gifts_obey_balance(setup):
    _, db, _ = setup
    db.students.update_one({"_id": DEMO_USER}, {"$set": {"wallet": 100}})
    from fastapi import HTTPException
    def send(index):
        try:
            Store(db).give(DEMO_USER, GrantInput(to=PEER, amount=100, category="kindness",
                reason="Thanks for the helpful feedback"), f"distinct-key-{index}")
            return 201
        except HTTPException as error:
            return error.status_code
    with ThreadPoolExecutor(max_workers=3) as executor:
        results = list(executor.map(send, range(3)))
    assert sorted(results) == [201, 409, 409]
    assert db.students.find_one({"_id": DEMO_USER})["wallet"] == 0
    assert db.students.find_one({"_id": PEER})["wallet"] == 1600
