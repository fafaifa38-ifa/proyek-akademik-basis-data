# Sistem Analitik Akademik & Prestasi Mahasiswa

Proyek Akhir Mata Kuliah Basis Data
Program Studi Sistem Informasi — Universitas Muhammadiyah Jember

## Kelompok

| Nama | NIM |
|---|---|
| [Vandhora Hari Ayustin  1] | [2510671036] |
| [Kholifatur Rahmania Ramadhani 2] | [2510671033] |
| [Fike Ayu Wulandari 3] | [2510671045] |

Dosen Pembimbing: [Triawan Adi Cahyanto M.Kom]

## Deskripsi Proyek

Sistem informasi akademik yang mengelola data mahasiswa, KRS, nilai, jadwal
kuliah, dan kurikulum, dengan analitik prestasi mahasiswa (perhitungan IPS/IPK
otomatis, deteksi mahasiswa berisiko, statistik per angkatan). Aplikasi
terhubung langsung ke database PostgreSQL nyata — seluruh data yang
ditampilkan (nilai, jadwal, statistik) berasal dari query database, bukan
data statis.

## Fitur Utama (MVP)

- **Portal Mahasiswa**: login, lihat jadwal kuliah, ambil KRS (dengan validasi
  prasyarat mata kuliah otomatis), lihat nilai, cetak transkrip sementara,
  lihat struktur kurikulum per semester
- **Portal Dosen**: lihat daftar kelas yang diampu, input nilai mahasiswa
- **Dashboard Kaprodi**: statistik jumlah mahasiswa aktif, rata-rata IPK per
  angkatan, daftar mahasiswa berisiko (IPS < 2.00)
- Perhitungan IPS dan IPK **otomatis** setiap kali nilai diinput (via trigger
  database)

## Teknologi yang Digunakan

| Komponen | Teknologi |
|---|---|
| Database | PostgreSQL |
| Backend | Python (Flask) |
| Frontend | HTML, Bootstrap, Jinja2 |
| Hosting Database | Neon |
| Hosting Aplikasi | Render |

## Struktur Basis Data

- 18 tabel, ternormalisasi hingga 3NF
- 6 View, 3 Trigger, 2 Stored Procedure/Function
- Transaksi (BEGIN-COMMIT-ROLLBACK) dan 12 query analitik kompleks
- ERD & script SQL lengkap tersedia di folder `erd/` dan `sql/`

## Cara Menjalankan Secara Lokal

1. Clone repository ini
2. Buat database PostgreSQL, jalankan script di folder `sql/` secara berurutan
   (01 → 02 → 03 → 04)
3. Masuk ke folder `app/`, buat virtual environment, lalu:
   pip install -r requerements.txt
4. Copy `.env.example` menjadi `.env`, isi `DATABASE_URL` sesuai database kamu
5. Jalankan `python seed_users.py` (sekali saja, untuk mengaktifkan password akun demo)
6. Jalankan `python app.py`, buka `http://127.0.0.1:5000`

## Akses Sistem Online

**URL Aplikasi:** [ISI URL RENDER, contoh: https://si-akademik.onrender.com]

> Catatan: aplikasi di-hosting menggunakan tier gratis Render, sehingga
> mungkin butuh waktu 30–50 detik untuk merespons pada akses pertama setelah
> tidak ada aktivitas (server dalam kondisi "tidur"). Silakan tunggu sejenak
> dan reload halaman.

**Akun Demo untuk Dosen:**

| Role | Username | Password |
|---|---|---|
| Admin | admin | password123 |
| Kaprodi | kaprodi | password123 |
| Dosen | dosen.ahmad | password123 |
| Mahasiswa | 2024210011 | password123 |

## Link Terkait

- Repository GitHub: [ISI LINK REPO INI]
- Laporan Lengkap (PDF): [ISI LINK/NAMA FILE LAPORAN]
- ERD: folder `erd/erd.dbml` (dapat dibuka di dbdiagram.io)

## Struktur Folder Repository
├── erd/          -> desain ERD (format DBML)
├── sql/          -> seluruh script SQL (DDL, dummy data, view, trigger, query)
├── app/          -> source code aplikasi Flask
└── docs/         -> dokumen pendukung laporan