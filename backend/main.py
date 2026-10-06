"""Wander API: destinations, cost estimates and saved trips.

Run:  uvicorn main:app --reload --host 0.0.0.0 --port 8000
Docs: http://localhost:8000/docs
"""
import json
import os
import sqlite3
import time
from contextlib import asynccontextmanager, contextmanager
from typing import Annotated, Optional

from fastapi import FastAPI, HTTPException, Query, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from seed import DESTINATIONS

MOODS = {"beach", "mountain", "culture"}

SCHEMA = """
CREATE TABLE IF NOT EXISTS destinations (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, country TEXT NOT NULL,
    tagline TEXT NOT NULL, season TEXT NOT NULL, flight_time TEXT NOT NULL,
    temp INTEGER NOT NULL, per_day INTEGER NOT NULL, flight INTEGER NOT NULL,
    mood TEXT NOT NULL, peaks INTEGER NOT NULL,
    sky_top TEXT NOT NULL, sky_bottom TEXT NOT NULL, sun TEXT NOT NULL,
    layers TEXT NOT NULL, pack TEXT NOT NULL, sort_order INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS trips (
    client_id TEXT NOT NULL, destination_id TEXT NOT NULL,
    days INTEGER NOT NULL, packed TEXT NOT NULL, total INTEGER NOT NULL,
    updated_at REAL NOT NULL,
    PRIMARY KEY (client_id, destination_id)
);
"""


def db_path() -> str:
    default = os.path.join(os.path.dirname(os.path.abspath(__file__)), "wander.db")
    return os.environ.get("WANDER_DB", default)


@contextmanager
def db():
    conn = sqlite3.connect(db_path())
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def init_db() -> None:
    with db() as conn:
        conn.executescript(SCHEMA)
        for order, d in enumerate(DESTINATIONS):
            conn.execute(
                """INSERT OR REPLACE INTO destinations
                   (id, name, country, tagline, season, flight_time, temp, per_day,
                    flight, mood, peaks, sky_top, sky_bottom, sun, layers, pack, sort_order)
                   VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (d["id"], d["name"], d["country"], d["tagline"], d["season"],
                 d["flight_time"], d["temp"], d["per_day"], d["flight"], d["mood"],
                 int(d["peaks"]), d["sky_top"], d["sky_bottom"], d["sun"],
                 json.dumps(d["layers"]), json.dumps(d["pack"]), order),
            )


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


app = FastAPI(title="Wander API", version="1.0.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
)

ClientId = Annotated[
    str, Query(min_length=8, max_length=64, pattern=r"^[A-Za-z0-9_-]+$")
]


class TripIn(BaseModel):
    client_id: str = Field(min_length=8, max_length=64, pattern=r"^[A-Za-z0-9_-]+$")
    destination_id: str = Field(min_length=1, max_length=64)
    days: int = Field(ge=1, le=60)
    packed: list[str] = Field(default_factory=list, max_length=50)


def destination_out(r: sqlite3.Row) -> dict:
    return {
        "id": r["id"], "name": r["name"], "country": r["country"],
        "tagline": r["tagline"], "season": r["season"],
        "flight_time": r["flight_time"], "temp": r["temp"],
        "per_day": r["per_day"], "flight": r["flight"], "mood": r["mood"],
        "peaks": bool(r["peaks"]), "sky_top": r["sky_top"],
        "sky_bottom": r["sky_bottom"], "sun": r["sun"],
        "layers": json.loads(r["layers"]), "pack": json.loads(r["pack"]),
    }


def trip_out(r: sqlite3.Row) -> dict:
    return {
        "destination_id": r["destination_id"], "days": r["days"],
        "packed": json.loads(r["packed"]), "total": r["total"],
        "updated_at": r["updated_at"],
    }


def get_destination(conn: sqlite3.Connection, dest_id: str) -> sqlite3.Row:
    row = conn.execute("SELECT * FROM destinations WHERE id = ?", (dest_id,)).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Destination not found")
    return row


@app.get("/api/health")
def health() -> dict:
    return {"status": "ok"}


@app.get("/api/destinations")
def list_destinations(
    mood: Optional[str] = None, q: Optional[str] = Query(default=None, max_length=80)
) -> list[dict]:
    if mood is not None and mood not in MOODS:
        raise HTTPException(status_code=422, detail=f"mood must be one of {sorted(MOODS)}")
    sql, params = "SELECT * FROM destinations WHERE 1=1", []
    if mood:
        sql += " AND mood = ?"
        params.append(mood)
    if q and q.strip():
        sql += " AND lower(name || ' ' || country || ' ' || tagline) LIKE ?"
        params.append(f"%{q.strip().lower()}%")
    sql += " ORDER BY sort_order"
    with db() as conn:
        return [destination_out(r) for r in conn.execute(sql, params).fetchall()]


@app.get("/api/destinations/{dest_id}")
def one_destination(dest_id: str) -> dict:
    with db() as conn:
        return destination_out(get_destination(conn, dest_id))


@app.get("/api/destinations/{dest_id}/estimate")
def estimate(dest_id: str, days: int = Query(ge=1, le=60)) -> dict:
    with db() as conn:
        d = get_destination(conn, dest_id)
    return {
        "days": days, "per_day": d["per_day"], "flight": d["flight"],
        "total": days * d["per_day"] + d["flight"],
    }


@app.get("/api/trips")
def list_trips(client_id: ClientId) -> list[dict]:
    with db() as conn:
        rows = conn.execute(
            "SELECT * FROM trips WHERE client_id = ? ORDER BY updated_at DESC",
            (client_id,),
        ).fetchall()
    return [trip_out(r) for r in rows]


@app.put("/api/trips")
def save_trip(body: TripIn) -> dict:
    with db() as conn:
        d = get_destination(conn, body.destination_id)
        allowed = json.loads(d["pack"])
        # keep only real pack items, no duplicates, original order
        packed = [i for i in allowed if i in set(body.packed)]
        total = body.days * d["per_day"] + d["flight"]
        conn.execute(
            """INSERT INTO trips (client_id, destination_id, days, packed, total, updated_at)
               VALUES (?,?,?,?,?,?)
               ON CONFLICT(client_id, destination_id) DO UPDATE SET
                 days=excluded.days, packed=excluded.packed,
                 total=excluded.total, updated_at=excluded.updated_at""",
            (body.client_id, body.destination_id, body.days,
             json.dumps(packed), total, time.time()),
        )
        row = conn.execute(
            "SELECT * FROM trips WHERE client_id = ? AND destination_id = ?",
            (body.client_id, body.destination_id),
        ).fetchone()
    return trip_out(row)


@app.delete("/api/trips/{destination_id}", status_code=204)
def delete_trip(destination_id: str, client_id: ClientId) -> Response:
    with db() as conn:
        conn.execute(
            "DELETE FROM trips WHERE client_id = ? AND destination_id = ?",
            (client_id, destination_id),
        )
    return Response(status_code=204)
