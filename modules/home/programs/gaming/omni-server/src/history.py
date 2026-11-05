"""Stat history in SQLite, written by the monitor and read by the Dashboard's graphs:
5 s samples for a day, one minute averages for 30 days."""

import os
import sqlite3
import time

FIELDS = ("cpu", "rss", "heap", "tps", "mspt", "players")
RAW_KEEP = 86400
MINUTE_KEEP = 30 * 86400
RANGES = {"5m": 300, "1h": 3600, "24h": 86400, "7d": 7 * 86400, "30d": 30 * 86400}
POINTS = 300


def connect(file):
    os.makedirs(os.path.dirname(file), exist_ok=True)
    db = sqlite3.connect(file, timeout=5)
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA synchronous=NORMAL")
    columns = ", ".join(f"{f} REAL" for f in FIELDS)
    db.execute(f"CREATE TABLE IF NOT EXISTS raw (ts INTEGER PRIMARY KEY, {columns})")
    db.execute(f"CREATE TABLE IF NOT EXISTS minute (ts INTEGER PRIMARY KEY, {columns})")
    return db


def insert(db, sample, now=None):
    now = int(now or time.time())
    values = [sample.get(f) for f in FIELDS]
    marks = ", ".join("?" * (len(FIELDS) + 1))
    db.execute(f"INSERT OR REPLACE INTO raw VALUES ({marks})", [now, *values])
    db.commit()


def roll_up(db, now=None):
    """Average finished minutes into `minute` and prune; the monitor calls this each minute."""
    now = int(now or time.time())
    last = db.execute("SELECT COALESCE(MAX(ts), 0) FROM minute").fetchone()[0]
    averages = ", ".join(f"AVG({f})" for f in FIELDS)
    db.execute(
        f"INSERT OR REPLACE INTO minute SELECT ts / 60 * 60, {averages} FROM raw "
        "WHERE ts >= ? AND ts < ? GROUP BY ts / 60",
        (last + 60 if last else 0, now // 60 * 60),
    )
    db.execute("DELETE FROM raw WHERE ts < ?", (now - RAW_KEEP,))
    db.execute("DELETE FROM minute WHERE ts < ?", (now - MINUTE_KEEP,))
    db.commit()


def series(file, field, range_name, now=None):
    """Up to POINTS [ts, value] pairs, oldest first; a gap is where the server was off."""
    if field not in FIELDS or range_name not in RANGES or not os.path.exists(file):
        return []
    now = int(now or time.time())
    span = RANGES[range_name]
    db = sqlite3.connect(f"file:{file}?mode=ro", uri=True, timeout=5)
    try:
        table = "raw" if span <= RAW_KEEP else "minute"
        step = max(span // POINTS, 5 if table == "raw" else 60)
        rows = db.execute(
            f"SELECT ts / ? * ?, AVG({field}) FROM {table} WHERE ts >= ? AND {field} IS NOT NULL "
            "GROUP BY ts / ? ORDER BY 1",
            (step, step, now - span, step),
        ).fetchall()
    finally:
        db.close()
    return [[ts, round(value, 3)] for ts, value in rows]
