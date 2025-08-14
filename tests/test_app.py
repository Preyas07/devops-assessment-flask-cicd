import os
from app import app

def test_index():
    os.environ["GIT_SHA"] = "testsha"
    client = app.test_client()
    resp = client.get("/")
    assert resp.status_code == 200
    assert "testsha" in resp.data.decode()

def test_healthz():
    client = app.test_client()
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.json["status"] == "ok"
