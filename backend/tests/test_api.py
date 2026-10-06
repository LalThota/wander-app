import os
import sys
import tempfile

os.environ["WANDER_DB"] = os.path.join(tempfile.mkdtemp(), "test.db")
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from fastapi.testclient import TestClient

from main import app

CID = "abcdef1234567890"


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c


def test_health(client):
    assert client.get("/api/health").json() == {"status": "ok"}


def test_list_and_filter(client):
    all_ = client.get("/api/destinations").json()
    assert len(all_) == 8
    assert isinstance(all_[0]["peaks"], bool)
    assert all_[0]["layers"][0].startswith("#")
    beach = client.get("/api/destinations", params={"mood": "beach"}).json()
    assert {d["mood"] for d in beach} == {"beach"}
    found = client.get("/api/destinations", params={"q": "kyoto"}).json()
    assert [d["id"] for d in found] == ["kyoto"]
    assert client.get("/api/destinations", params={"mood": "space"}).status_code == 422


def test_detail_and_estimate(client):
    assert client.get("/api/destinations/bali").json()["name"] == "Bali"
    assert client.get("/api/destinations/nope").status_code == 404
    est = client.get("/api/destinations/bali/estimate", params={"days": 5}).json()
    assert est["total"] == 5 * 6500 + 28000
    assert client.get("/api/destinations/bali/estimate", params={"days": 0}).status_code == 422


def test_trip_lifecycle(client):
    assert client.get("/api/trips", params={"client_id": CID}).json() == []
    body = {"client_id": CID, "destination_id": "bali", "days": 7,
            "packed": ["Sarong", "Sunscreen", "Not a real item", "Sarong"]}
    saved = client.put("/api/trips", json=body).json()
    assert saved["total"] == 7 * 6500 + 28000
    assert saved["packed"] == ["Sunscreen", "Sarong"]

    body["days"] = 3
    updated = client.put("/api/trips", json=body).json()
    assert updated["days"] == 3
    trips = client.get("/api/trips", params={"client_id": CID}).json()
    assert len(trips) == 1

    # another device never sees this trip
    assert client.get("/api/trips", params={"client_id": "zzzzzzzz9999"}).json() == []

    assert client.delete("/api/trips/bali", params={"client_id": CID}).status_code == 204
    assert client.get("/api/trips", params={"client_id": CID}).json() == []


def test_validation(client):
    bad = {"client_id": "short", "destination_id": "bali", "days": 3, "packed": []}
    assert client.put("/api/trips", json=bad).status_code == 422
    ghost = {"client_id": CID, "destination_id": "atlantis", "days": 3, "packed": []}
    assert client.put("/api/trips", json=ghost).status_code == 404
    toolong = {"client_id": CID, "destination_id": "bali", "days": 999, "packed": []}
    assert client.put("/api/trips", json=toolong).status_code == 422
