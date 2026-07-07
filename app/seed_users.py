"""
seed_users.py
Jalankan sekali setelah data dummy (02_dummy_data.sql) dimasukkan ke
database, untuk mengisi password_hash yang valid (bcrypt/werkzeug)
pada tabel users.

Cara pakai:
    cd app
    pip install -r requirements.txt --break-system-packages   # jika perlu
    python seed_users.py

Akun demo yang akan aktif setelah ini (password sama untuk semua = "password123"):
    admin        / password123   (role: admin)
    kaprodi      / password123   (role: kaprodi)
    dosen.ahmad  / password123   (role: dosen -> Dr. Ahmad Fauzi)
    dosen.siti   / password123   (role: dosen -> Siti Nurhaliza)
    2024210011   / password123   (role: mahasiswa -> Krisna Aditya)
    2022210003   / password123   (role: mahasiswa -> Candra Wibowo)
"""
from werkzeug.security import generate_password_hash
from db import get_connection

DEFAULT_PASSWORD = "password123"

def main():
    hashed = generate_password_hash(DEFAULT_PASSWORD)
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("UPDATE users SET password_hash = %s WHERE password_hash = 'to_be_generated'", (hashed,))
            print(f"Berhasil update {cur.rowcount} akun dengan password default: {DEFAULT_PASSWORD}")
        conn.commit()
    finally:
        conn.close()

if __name__ == "__main__":
    main()
