"""
db.py - modul koneksi database PostgreSQL
Menggunakan psycopg2 dengan RealDictCursor supaya hasil query
berbentuk dict (mudah dipakai di template Jinja2).
"""
import os
import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql://postgres:password@localhost:5432/db_akademik")


def get_connection():
    """Membuka koneksi baru ke PostgreSQL. Ditutup manual oleh pemanggil."""
    conn = psycopg2.connect(DATABASE_URL, cursor_factory=psycopg2.extras.RealDictCursor)
    return conn


def query_all(sql, params=None):
    """Jalankan SELECT, kembalikan semua baris sebagai list of dict."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            rows = cur.fetchall()
        return rows
    finally:
        conn.close()


def query_one(sql, params=None):
    """Jalankan SELECT, kembalikan satu baris (atau None)."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            row = cur.fetchone()
        return row
    finally:
        conn.close()


def execute(sql, params=None):
    """Jalankan INSERT/UPDATE/DELETE/CALL. Otomatis commit.
    Jika terjadi error (misal trigger RAISE EXCEPTION saat validasi
    prasyarat), otomatis rollback dan exception dilempar ke pemanggil
    supaya bisa ditangkap dan ditampilkan sebagai pesan error di UI."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
