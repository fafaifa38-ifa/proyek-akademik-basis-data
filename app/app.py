"""
app.py - Sistem Analitik Akademik & Prestasi Mahasiswa
Aplikasi MVP berbasis Flask + PostgreSQL.

Fitur MVP yang diimplementasikan:
- Login multi-role (mahasiswa, dosen, kaprodi, admin)
- Portal mahasiswa: KRS, nilai, jadwal, transkrip
- Portal dosen: daftar kelas, input nilai
- Dashboard kaprodi: statistik mahasiswa aktif & IPK rata-rata per angkatan
"""
import os
from functools import wraps
from flask import Flask, render_template, request, redirect, url_for, session, flash
from werkzeug.security import check_password_hash
from dotenv import load_dotenv

import db

load_dotenv()

app = Flask(__name__)
app.secret_key = os.environ.get("SECRET_KEY", "dev-secret-key-ganti-ini")


# ---------------------------------------------------------------------
# Helper: decorator login & role
# ---------------------------------------------------------------------
def login_required(role=None):
    def decorator(f):
        @wraps(f)
        def wrapped(*args, **kwargs):
            if "user" not in session:
                flash("Silakan login terlebih dahulu.", "warning")
                return redirect(url_for("login"))
            if role and session["user"]["role"] != role:
                flash("Anda tidak memiliki akses ke halaman ini.", "danger")
                return redirect(url_for("index"))
            return f(*args, **kwargs)
        return wrapped
    return decorator


def get_id_tahun_akademik_aktif():
    row = db.query_one("SELECT id_tahun_akademik FROM tahun_akademik WHERE is_aktif = true LIMIT 1")
    return row["id_tahun_akademik"] if row else None


# ---------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------
@app.route("/")
def index():
    if "user" not in session:
        return redirect(url_for("login"))
    role = session["user"]["role"]
    if role == "mahasiswa":
        return redirect(url_for("mhs_dashboard"))
    if role == "dosen":
        return redirect(url_for("dosen_dashboard"))
    if role in ("kaprodi", "admin"):
        return redirect(url_for("kaprodi_dashboard"))
    return redirect(url_for("login"))


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")

        user = db.query_one("SELECT * FROM users WHERE username = %s", (username,))
        if user and user["password_hash"] != "to_be_generated" and check_password_hash(user["password_hash"], password):
            session["user"] = {
                "id_user": user["id_user"],
                "username": user["username"],
                "role": user["role"],
                "nim": user["nim"],
                "id_dosen": user["id_dosen"],
            }
            flash(f"Selamat datang, {username}!", "success")
            return redirect(url_for("index"))
        flash("Username atau password salah.", "danger")
    return render_template("login.html")


@app.route("/logout")
def logout():
    session.clear()
    flash("Anda telah logout.", "info")
    return redirect(url_for("login"))


# ---------------------------------------------------------------------
# PORTAL MAHASISWA
# ---------------------------------------------------------------------
@app.route("/mahasiswa/dashboard")
@login_required(role="mahasiswa")
def mhs_dashboard():
    nim = session["user"]["nim"]
    mhs = db.query_one(
        """
        SELECT m.*, k.nama_kurikulum
        FROM mahasiswa m
        JOIN angkatan a ON a.id_angkatan = m.id_angkatan
        LEFT JOIN kurikulum k ON k.id_kurikulum = a.id_kurikulum
        WHERE m.nim = %s
        """,
        (nim,)
    )
    ip_terakhir = db.query_one(
        "SELECT * FROM ringkasan_ip WHERE nim = %s ORDER BY id_tahun_akademik DESC LIMIT 1",
        (nim,)
    )
    beban_studi = db.query_all(
        "SELECT * FROM view_beban_studi_semester WHERE nim = %s ORDER BY id_tahun_akademik DESC",
        (nim,)
    )
    return render_template("mhs_dashboard.html", mhs=mhs, ip=ip_terakhir, beban_studi=beban_studi)


@app.route("/mahasiswa/jadwal")
@login_required(role="mahasiswa")
def mhs_jadwal():
    nim = session["user"]["nim"]
    jadwal = db.query_all(
        "SELECT * FROM view_jadwal_mahasiswa WHERE nim = %s ORDER BY hari, jam_mulai",
        (nim,)
    )
    return render_template("jadwal.html", jadwal=jadwal)


@app.route("/mahasiswa/krs", methods=["GET", "POST"])
@login_required(role="mahasiswa")
def mhs_krs():
    nim = session["user"]["nim"]
    id_ta_aktif = get_id_tahun_akademik_aktif()

    if request.method == "POST":
        id_jadwal = request.form.get("id_jadwal")
        try:
            db.execute(
                "INSERT INTO krs (nim, id_jadwal, id_tahun_akademik) VALUES (%s, %s, %s)",
                (nim, id_jadwal, id_ta_aktif)
            )
            flash("Mata kuliah berhasil ditambahkan ke KRS.", "success")
        except Exception as e:
            # trigger trg_validasi_prasyarat akan RAISE EXCEPTION di sini
            # jika prasyarat belum lulus, atau UNIQUE constraint jika duplikat
            flash(f"Gagal menambahkan KRS: {e}", "danger")
        return redirect(url_for("mhs_krs"))

    krs_diambil = db.query_all(
        """
        SELECT k.id_krs, mk.kode_mk, mk.nama_mk, mk.sks, j.kelas, j.hari, j.jam_mulai
        FROM krs k
        JOIN jadwal_kuliah j ON j.id_jadwal = k.id_jadwal
        JOIN mata_kuliah mk ON mk.kode_mk = j.kode_mk
        WHERE k.nim = %s AND k.id_tahun_akademik = %s AND k.status_krs = 'Aktif'
        ORDER BY j.hari, j.jam_mulai
        """,
        (nim, id_ta_aktif)
    )
    mk_belum_diambil = db.query_all(
        """
        SELECT j.id_jadwal, mk.kode_mk, mk.nama_mk, mk.sks, j.kelas, j.hari, j.jam_mulai
        FROM jadwal_kuliah j
        JOIN mata_kuliah mk ON mk.kode_mk = j.kode_mk
        WHERE j.id_tahun_akademik = %s
          AND j.id_jadwal NOT IN (
              SELECT id_jadwal FROM krs WHERE nim = %s AND status_krs = 'Aktif'
          )
        ORDER BY mk.kode_mk
        """,
        (id_ta_aktif, nim)
    )
    return render_template("krs.html", krs_diambil=krs_diambil, mk_tersedia=mk_belum_diambil)


@app.route("/mahasiswa/kurikulum")
@login_required(role="mahasiswa")
def mhs_kurikulum():
    nim = session["user"]["nim"]
    mhs = db.query_one(
        """
        SELECT m.nim, m.nama, a.tahun_masuk, k.nama_kurikulum
        FROM mahasiswa m
        JOIN angkatan a ON a.id_angkatan = m.id_angkatan
        LEFT JOIN kurikulum k ON k.id_kurikulum = a.id_kurikulum
        WHERE m.nim = %s
        """,
        (nim,)
    )
    struktur = db.query_all(
        """
        SELECT DISTINCT
            vsk.semester_ke, vsk.kode_mk, vsk.nama_mk, vsk.sks,
            vsk.sifat, vsk.nama_kurikulum
        FROM mahasiswa m
        JOIN angkatan a          ON a.id_angkatan = m.id_angkatan
        JOIN view_struktur_kurikulum vsk ON vsk.id_kurikulum = a.id_kurikulum
        WHERE m.nim = %s
        ORDER BY vsk.semester_ke, vsk.kode_mk
        """,
        (nim,)
    )
    return render_template("kurikulum.html", mhs=mhs, struktur=struktur)


@app.route("/mahasiswa/nilai")
@login_required(role="mahasiswa")
def mhs_nilai():
    nim = session["user"]["nim"]
    nilai = db.query_all(
        "SELECT * FROM view_transkrip_mahasiswa WHERE nim = %s ORDER BY tahun_ajaran, semester",
        (nim,)
    )
    return render_template("nilai.html", nilai=nilai)


@app.route("/mahasiswa/transkrip")
@login_required(role="mahasiswa")
def mhs_transkrip():
    nim = session["user"]["nim"]
    mhs = db.query_one("SELECT * FROM mahasiswa WHERE nim = %s", (nim,))
    transkrip = db.query_all(
        "SELECT * FROM view_transkrip_mahasiswa WHERE nim = %s AND nilai_huruf IS NOT NULL ORDER BY tahun_ajaran, semester",
        (nim,)
    )
    ip_terakhir = db.query_one(
        "SELECT * FROM ringkasan_ip WHERE nim = %s ORDER BY id_tahun_akademik DESC LIMIT 1",
        (nim,)
    )
    return render_template("transkrip.html", mhs=mhs, transkrip=transkrip, ip=ip_terakhir)


# ---------------------------------------------------------------------
# PORTAL DOSEN
# ---------------------------------------------------------------------
@app.route("/dosen/dashboard")
@login_required(role="dosen")
def dosen_dashboard():
    id_dosen = session["user"]["id_dosen"]
    kelas = db.query_all(
        "SELECT * FROM view_daftar_kelas_dosen WHERE id_dosen = %s ORDER BY tahun_ajaran DESC, kode_mk",
        (id_dosen,)
    )
    return render_template("dosen_dashboard.html", kelas=kelas)


@app.route("/dosen/kelas/<int:id_jadwal>/nilai", methods=["GET", "POST"])
@login_required(role="dosen")
def dosen_input_nilai(id_jadwal):
    id_dosen = session["user"]["id_dosen"]
    # pastikan kelas ini memang diampu dosen yang login
    jadwal = db.query_one(
        "SELECT j.*, mk.nama_mk FROM jadwal_kuliah j JOIN mata_kuliah mk ON mk.kode_mk = j.kode_mk "
        "WHERE j.id_jadwal = %s AND j.id_dosen = %s",
        (id_jadwal, id_dosen)
    )
    if not jadwal:
        flash("Anda tidak memiliki akses ke kelas ini.", "danger")
        return redirect(url_for("dosen_dashboard"))

    if request.method == "POST":
        id_krs = request.form.get("id_krs")
        nilai_angka = request.form.get("nilai_angka")
        try:
            existing = db.query_one("SELECT id_nilai FROM nilai WHERE id_krs = %s", (id_krs,))
            if existing:
                db.execute("UPDATE nilai SET nilai_angka = %s WHERE id_krs = %s", (nilai_angka, id_krs))
            else:
                db.execute("INSERT INTO nilai (id_krs, nilai_angka) VALUES (%s, %s)", (id_krs, nilai_angka))
            flash("Nilai berhasil disimpan.", "success")
        except Exception as e:
            flash(f"Gagal menyimpan nilai: {e}", "danger")
        return redirect(url_for("dosen_input_nilai", id_jadwal=id_jadwal))

    peserta = db.query_all(
        """
        SELECT k.id_krs, m.nim, m.nama, n.nilai_angka, n.nilai_huruf
        FROM krs k
        JOIN mahasiswa m ON m.nim = k.nim
        LEFT JOIN nilai n ON n.id_krs = k.id_krs
        WHERE k.id_jadwal = %s AND k.status_krs = 'Aktif'
        ORDER BY m.nama
        """,
        (id_jadwal,)
    )
    return render_template("input_nilai.html", jadwal=jadwal, peserta=peserta)


# ---------------------------------------------------------------------
# DASHBOARD KAPRODI / ADMIN
# ---------------------------------------------------------------------
@app.route("/kaprodi/dashboard")
@login_required()
def kaprodi_dashboard():
    if session["user"]["role"] not in ("kaprodi", "admin"):
        flash("Anda tidak memiliki akses ke halaman ini.", "danger")
        return redirect(url_for("index"))

    statistik = db.query_all("SELECT * FROM view_dashboard_kaprodi")
    total_mhs_aktif = db.query_one("SELECT COUNT(*) AS total FROM mahasiswa WHERE status_mahasiswa = 'Aktif'")
    rata_ipk_kampus = db.query_one(
        """
        SELECT ROUND(AVG(r.ipk)::numeric, 2) AS rata_ipk
        FROM mahasiswa m
        JOIN LATERAL (
            SELECT ipk FROM ringkasan_ip ri WHERE ri.nim = m.nim
            ORDER BY ri.id_tahun_akademik DESC LIMIT 1
        ) r ON true
        """
    )
    mhs_ips_rendah = db.query_all(
        """
        SELECT m.nim, m.nama, ta.tahun_ajaran, ta.semester, ri.ips
        FROM ringkasan_ip ri
        JOIN mahasiswa m ON m.nim = ri.nim
        JOIN tahun_akademik ta ON ta.id_tahun_akademik = ri.id_tahun_akademik
        WHERE ri.ips < 2.00 AND ri.ips > 0
        ORDER BY ri.ips ASC
        """
    )
    return render_template(
        "kaprodi_dashboard.html",
        statistik=statistik,
        total_mhs_aktif=total_mhs_aktif,
        rata_ipk_kampus=rata_ipk_kampus,
        mhs_ips_rendah=mhs_ips_rendah,
    )


if __name__ == "__main__":
    app.run(debug=True, port=5000)
