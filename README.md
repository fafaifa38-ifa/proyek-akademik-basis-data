# Sistem Analitik Akademik & Prestasi Mahasiswa

Proyek Akhir Mata Kuliah Basis Data — Program Studi Sistem Informasi,
Universitas Muhammadiyah Jember.

Stack: **PostgreSQL** (database) + **Flask/Python** (aplikasi web) + **Bootstrap** (tampilan).

---

## 📁 Struktur Folder

```
proyek-akademik/
├── erd/
│   └── erd.dbml                  -> import ke dbdiagram.io untuk lihat ERD
├── sql/
│   ├── 01_ddl.sql                -> buat semua tabel, constraint, index
│   ├── 02_dummy_data.sql         -> isi data dummy realistis
│   ├── 03_views.sql              -> 5 VIEW (min. requirement: 3)
│   ├── 04_triggers_functions.sql -> trigger + stored procedure/function
│   ├── 05_transaksi_demo.sql     -> demo BEGIN-COMMIT-ROLLBACK
│   └── 06_complex_queries.sql    -> 12 query kompleks (min. requirement: 10)
├── app/
│   ├── app.py                    -> aplikasi Flask (routing utama)
│   ├── db.py                     -> koneksi ke PostgreSQL
│   ├── seed_users.py             -> generate password akun demo
│   ├── requirements.txt
│   ├── .env.example
│   ├── .gitignore
│   ├── Procfile                  -> untuk deploy ke Render/Railway
│   └── templates/                -> halaman HTML (Jinja2 + Bootstrap)
└── docs/
    ├── laporan_template.md       -> kerangka laporan (BAB 1-6 + lampiran)
    └── checklist_deliverable.md  -> checklist sebelum submit
```

---

## 🚀 TAHAP PENGERJAAN (urutan yang disarankan)

### Tahap 1 — ERD (Hari 1)
1. Buka [dbdiagram.io](https://dbdiagram.io) → New Diagram.
2. Hapus semua isi editor bawaan, lalu **copy-paste seluruh isi file
   `erd/erd.dbml`** ke editor tersebut.
3. ERD akan otomatis tergambar lengkap dengan relasi & kardinalitas.
4. Export sebagai PNG/PDF (menu Export) untuk dilampirkan di laporan.
5. Diskusikan dengan tim: apakah entitas ini sudah sesuai kebutuhan
   kelompok kalian? Boleh disesuaikan (tambah/kurang kolom) sebelum
   lanjut ke tahap DDL.

### Tahap 2 — Setup Database di pgAdmin (Hari 1-2)
1. Buka pgAdmin → klik kanan **Databases** → **Create** → **Database**.
2. Beri nama misalnya `db_akademik` → Save.
3. Klik kanan database `db_akademik` → **Query Tool**.
4. Buka file `sql/01_ddl.sql`, copy semua isi, paste ke Query Tool, klik
   **Execute (F5)**. Pastikan tidak ada error — semua tabel akan
   terbentuk (cek di panel kiri: Schemas → public → Tables).
5. Lakukan hal yang sama untuk `sql/02_dummy_data.sql`.
6. Lakukan hal yang sama untuk `sql/03_views.sql`.
7. Lakukan hal yang sama untuk `sql/04_triggers_functions.sql`.
   File ini juga otomatis menghitung ulang IPK/IPS untuk data dummy
   yang sudah ada (backfill).
8. **Verifikasi**: jalankan `SELECT * FROM ringkasan_ip;` — harus ada
   data IPK/IPS yang terisi.

### Tahap 3 — Uji Trigger & Transaksi (Hari 3-4)
1. Buka `sql/05_transaksi_demo.sql`, jalankan blok per blok (per
   `BEGIN...COMMIT`/`ROLLBACK`) sambil di-screenshot untuk laporan BAB 5.
2. Buka `sql/06_complex_queries.sql`, jalankan satu per satu, screenshot
   hasilnya untuk laporan BAB 6/Analitik.

### Tahap 4 — Jalankan Aplikasi MVP (Hari 5-7)
1. Install Python 3.10+ jika belum ada.
2. Buka terminal, masuk ke folder `app/`:
   ```bash
   cd app
   python -m venv venv
   source venv/bin/activate        # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```
3. Copy `.env.example` menjadi `.env`, lalu isi `DATABASE_URL` sesuai
   koneksi PostgreSQL lokal kalian, contoh:
   ```
   DATABASE_URL=postgresql://postgres:password_kamu@localhost:5432/db_akademik
   ```
4. Generate password akun demo (WAJIB dijalankan sekali):
   ```bash
   python seed_users.py
   ```
5. Jalankan aplikasi:
   ```bash
   python app.py
   ```
6. Buka browser: `http://localhost:5000`
7. Login dengan salah satu akun demo (password semua = `password123`):
   - `admin` / `kaprodi` → dashboard statistik
   - `dosen.ahmad` / `dosen.siti` → input nilai
   - `2024210011` / `2022210003` → portal mahasiswa (KRS, nilai, transkrip, kurikulum)
8. **Uji semua fitur MVP** dan catat hasilnya sebagai test case di
   laporan BAB 5 (Pengujian).

### Tahap 5 — Laporan Analitik & Teknis (Hari 8-9)
1. Gunakan `docs/laporan_template.md` sebagai kerangka.
2. Lengkapi ERD (export dari dbdiagram.io), kamus data (dari
   `01_ddl.sql`), penjelasan trigger/procedure (dari
   `04_triggers_functions.sql`), dan hasil query (dari
   `06_complex_queries.sql`).
3. Convert ke PDF (LibreOffice Writer / MS Word) sesuai format yang
   diminta dosen.

### Tahap 6 — Deployment Online (WAJIB sebelum presentasi)
1. Ikuti panduan **Opsi A: Python (Flask) + PostgreSQL** di file PDF
   ketentuan proyek (Render untuk backend + Neon untuk database).
   Ringkasannya:
   - Buat database PostgreSQL gratis di [neon.tech](https://neon.tech),
     jalankan seluruh file `sql/*.sql` di SQL Editor Neon (urutan sama
     seperti Tahap 2).
   - Push folder `app/` ke GitHub (pastikan `.env` **tidak** ikut
     ter-push — sudah diatur di `.gitignore`).
   - Deploy ke [render.com](https://render.com), tambahkan Environment
     Variable `DATABASE_URL` dan `SECRET_KEY` sesuai punya kalian.
   - Setelah deploy sukses, jalankan `seed_users.py` sekali (bisa lewat
     Render Shell atau jalankan lokal dengan `DATABASE_URL` yang sama
     menunjuk ke Neon).
2. Catat URL publik yang didapat, cantumkan di README dan laporan.

### Tahap 7 — Presentasi & Demo (Hari 10)
1. Siapkan alur demo: login tiap role → tunjukkan fitur MVP → tunjukkan
   trigger bekerja (coba ambil KRS tanpa lulus prasyarat → harus
   ditolak) → tunjukkan dashboard analitik.
2. Semua anggota tim harus paham struktur database dan bisa menjelaskan
   minimal 1 trigger dan 1 stored procedure.

---

## 🔑 Akun Demo

| Username      | Password    | Role      | Keterangan             |
|---------------|-------------|-----------|-------------------------|
| admin         | password123 | admin     | Akses dashboard kaprodi |
| kaprodi       | password123 | kaprodi   | Dashboard statistik     |
| dosen.ahmad   | password123 | dosen     | Dr. Ahmad Fauzi         |
| dosen.siti    | password123 | dosen     | Siti Nurhaliza          |
| 2024210011    | password123 | mahasiswa | Krisna Aditya           |
| 2022210003    | password123 | mahasiswa | Candra Wibowo           |

---

## 🧩 Ringkasan Objek Database

- **18 tabel** (16 tabel inti + `kurikulum` + `kurikulum_mk`), ternormalisasi hingga 3NF
- **6 VIEW**: `view_transkrip_mahasiswa`, `view_beban_studi_semester`,
  `view_dashboard_kaprodi`, `view_jadwal_mahasiswa`, `view_daftar_kelas_dosen`,
  `view_struktur_kurikulum`
- **Fitur tambahan**: halaman "Struktur Kurikulum" di portal mahasiswa —
  menampilkan daftar mata kuliah per semester sesuai kurikulum yang
  diikuti angkatan mahasiswa tersebut (lihat `app/templates/kurikulum.html`)
- **3 TRIGGER**: konversi nilai otomatis, hitung ulang IPK otomatis,
  validasi prasyarat mata kuliah
- **2 Stored Procedure/Function**: `sp_hitung_ip()`, `fn_konversi_nilai()`
- **12 query kompleks** siap pakai (JOIN, subquery, aggregate, CASE WHEN,
  window function `RANK()`)
- **Transaksi** BEGIN-COMMIT-ROLLBACK terdemonstrasi di `05_transaksi_demo.sql`

---

## ⚠️ Catatan Penting

- Jangan lupa jalankan `seed_users.py` setelah import data dummy, atau
  login tidak akan berfungsi (password masih `to_be_generated`).
- Semua kredensial database HARUS lewat environment variable, jangan
  hardcode — lihat `.gitignore` dan `.env.example`.
- Sesuaikan nama tim, NIM anggota, dan dosen pembimbing di
  `docs/laporan_template.md` sebelum submit.
