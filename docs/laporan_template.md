# LAPORAN PROYEK AKHIR BASIS DATA
## Sistem Analitik Akademik & Prestasi Mahasiswa

**Kelompok:** (isi nama kelompok)
**Anggota:**
1. (Nama - NIM)
2. (Nama - NIM)
3. (Nama - NIM)

**Program Studi:** Sistem Informasi
**Universitas:** Universitas Muhammadiyah Jember
**Dosen Pembimbing:** (isi nama dosen)

---

## BAB 1 — PENDAHULUAN

### 1.1 Latar Belakang
(Jelaskan mengapa lembaga pendidikan butuh sistem pengelolaan data
akademik dan analitik prestasi mahasiswa yang terintegrasi. Bahas
masalah yang muncul jika masih manual: rekap nilai lambat, IPK dihitung
manual, sulit deteksi mahasiswa berisiko drop out, dll.)

### 1.2 Tujuan
- Merancang basis data akademik yang ternormalisasi hingga 3NF.
- Membangun aplikasi MVP yang terhubung langsung ke basis data nyata.
- Menghasilkan laporan analitik akademik berbasis query SQL.

### 1.3 Ruang Lingkup
(Jelaskan batasan proyek: fitur MVP yang dikerjakan, fitur bonus yang
dikerjakan/tidak, exclude apa saja — misal tidak ada integrasi SSO
kampus, dsb.)

### 1.4 Definisi MVP
MVP dalam proyek ini berarti: aplikasi terhubung ke database PostgreSQL
nyata, operasi CRUD (KRS, nilai, jadwal) berjalan, laporan menampilkan
data real dari query SQL, dan seluruh objek database (view, trigger,
stored procedure) aktif digunakan oleh aplikasi.

---

## BAB 2 — ANALISIS KEBUTUHAN

### 2.1 Kebutuhan Fungsional (berdasarkan fitur MVP)
| Kode | Kebutuhan | Aktor |
|------|-----------|-------|
| F01  | Mahasiswa dapat login dan melihat dashboard IPK/IPS | Mahasiswa |
| F02  | Mahasiswa dapat melihat jadwal kuliah semester aktif | Mahasiswa |
| F03  | Mahasiswa dapat mengambil KRS dengan validasi prasyarat otomatis | Mahasiswa |
| F04  | Mahasiswa dapat melihat nilai & transkrip sementara | Mahasiswa |
| F05  | Dosen dapat melihat daftar kelas yang diampu | Dosen |
| F06  | Dosen dapat input/update nilai mahasiswa | Dosen |
| F07  | IPS dan IPK dihitung otomatis setiap nilai diinput | Sistem |
| F08  | Kaprodi dapat melihat statistik mahasiswa aktif & IPK rata-rata per angkatan | Kaprodi |
| F09  | Mahasiswa dapat melihat struktur kurikulum (daftar MK per semester) sesuai kurikulum angkatannya | Mahasiswa |

(Tambahkan kebutuhan non-fungsional: keamanan login/password hashing,
response time, dll.)

### 2.2 Kebutuhan Fitur Bonus (jika dikerjakan)
(Sesuaikan dengan fitur bonus yang kelompok kalian pilih untuk
dikerjakan, misal: alert IPS < 2.00, cetak KHS PDF, grafik distribusi IPK.)

---

## BAB 3 — DESAIN BASIS DATA

### 3.1 Entity Relationship Diagram (ERD)
(Tempel screenshot/export ERD dari dbdiagram.io di sini — file sumber
ada di `erd/erd.dbml`.)

### 3.2 Kamus Data
(Salin struktur tiap tabel dari `sql/01_ddl.sql`. Contoh format:)

**Tabel: mahasiswa**
| Kolom | Tipe Data | Constraint | Keterangan |
|-------|-----------|------------|------------|
| nim | VARCHAR(15) | PRIMARY KEY | Nomor Induk Mahasiswa |
| nama | VARCHAR(100) | NOT NULL | Nama lengkap |
| id_prodi | INT | FK -> program_studi | Program studi mahasiswa |
| id_angkatan | INT | FK -> angkatan | Angkatan masuk |
| status_mahasiswa | VARCHAR(20) | CHECK (Aktif/Cuti/Lulus/DO) | Status akademik |

(Lengkapi untuk seluruh 18 tabel, termasuk `kurikulum` dan `kurikulum_mk`.)

### 3.3 Normalisasi
**1NF:** Semua atribut bernilai atomik (contoh: alamat disimpan sebagai
teks tunggal, tidak ada kolom berulang seperti nilai1, nilai2, dst —
histori nilai justru dipisah ke tabel `nilai` yang terhubung ke `krs`).

**2NF:** Semua tabel transaksi (krs, nilai, jadwal_kuliah) memiliki
primary key tunggal (surrogate key `id_...`) sehingga tidak ada
dependensi parsial pada composite key, kecuali tabel relasi
many-to-many `prasyarat_mk` yang memang menggunakan composite key murni.

**3NF:** Tidak ada atribut non-key yang bergantung pada atribut
non-key lain. Ada dua pengecualian yang SENGAJA didenormalisasi secara
terkontrol (jelaskan ini ke dosen sebagai keputusan desain, bukan
kesalahan):
1. `nilai_huruf` dan `bobot` di tabel `nilai` sebenarnya turunan dari
   `nilai_angka` — dijaga konsisten otomatis lewat TRIGGER
   `trg_konversi_nilai`, tidak pernah diinput manual oleh user.
2. `krs.id_tahun_akademik` secara teori bisa didapat dari
   `krs.id_jadwal -> jadwal_kuliah.id_tahun_akademik` (join 1 langkah),
   tapi kolom ini tetap disimpan ulang di tabel `krs` supaya query
   filter "KRS semester ini" tidak perlu JOIN ke `jadwal_kuliah` setiap
   saat — mempercepat query yang sering dipanggil aplikasi (dashboard,
   dan filter KRS). Konsistensinya dijaga oleh aplikasi: setiap INSERT
   ke `krs`, nilai `id_tahun_akademik` selalu diambil dari
   `jadwal_kuliah` yang sama (lihat `app.py` fungsi `mhs_krs`).

### 3.4 Relasi Antar Tabel
(Jelaskan kardinalitas: 1 mahasiswa - N krs, 1 jadwal_kuliah - N krs,
1 krs - 1 nilai, dst. Bisa disalin dari deskripsi `ref:` di file
`erd/erd.dbml`.)

---

## BAB 4 — IMPLEMENTASI

### 4.1 DDL (Data Definition Language)
(Ringkas penjelasan tabel — lampirkan full script di Lampiran, sumber:
`sql/01_ddl.sql`.)

### 4.2 View
Dijelaskan 5 view yang digunakan aplikasi (`sql/03_views.sql`):
1. `view_transkrip_mahasiswa` — dipakai halaman transkrip & nilai
2. `view_beban_studi_semester` — dipakai dashboard mahasiswa
3. `view_dashboard_kaprodi` — dipakai dashboard kaprodi
4. `view_jadwal_mahasiswa` — dipakai halaman jadwal
5. `view_daftar_kelas_dosen` — dipakai dashboard dosen

### 4.3 Trigger
1. **trg_konversi_nilai** — BEFORE INSERT/UPDATE pada tabel `nilai`,
   otomatis mengonversi nilai angka menjadi nilai huruf & bobot.
2. **trg_after_nilai_hitung_ip** — AFTER INSERT/UPDATE pada tabel
   `nilai`, memanggil stored procedure `sp_hitung_ip` untuk memperbarui
   IPS & IPK mahasiswa secara otomatis.
3. **trg_validasi_prasyarat** — BEFORE INSERT pada tabel `krs`, menolak
   pengambilan mata kuliah jika prasyaratnya belum lulus.

(Sertakan screenshot demonstrasi: sebelum & sesudah trigger berjalan.)

### 4.4 Stored Procedure / Function
1. `fn_konversi_nilai(nilai_angka)` — function konversi ke huruf & bobot.
2. `sp_hitung_ip(nim, id_tahun_akademik)` — procedure hitung IPS & IPK.

### 4.5 Transaksi
(Jelaskan skenario `sql/05_transaksi_demo.sql`: 1 skenario sukses
COMMIT, 1 skenario gagal karena trigger menolak (implicit rollback),
1 skenario rollback manual.)

### 4.6 Tangkapan Layar Aplikasi
(Tempel screenshot tiap halaman: login, dashboard mahasiswa, KRS,
nilai, transkrip, dashboard dosen, input nilai, dashboard kaprodi.)

---

## BAB 5 — PENGUJIAN

Contoh format test case (lengkapi minimal 1 per fitur MVP):

| No | Fitur | Input | Aksi | Output yang Diharapkan | Hasil |
|----|-------|-------|------|--------------------------|-------|
| 1 | Login | username=2024210011, password=password123 | Klik login | Masuk ke dashboard mahasiswa | ✅ Sesuai |
| 2 | Ambil KRS (gagal) | Mahasiswa ambil SI401 tanpa lulus SI301/SI202 | Klik "Ambil" | Muncul pesan error, KRS tidak tersimpan | ✅ Sesuai |
| 3 | Ambil KRS (berhasil) | Mahasiswa ambil MK tanpa prasyarat | Klik "Ambil" | KRS tersimpan, tabel diperbarui | ✅ Sesuai |
| 4 | Input nilai | Dosen input nilai_angka=85 | Klik "Simpan" | nilai_huruf otomatis "A", IPK ter-update | ✅ Sesuai |
| ... | | | | | |

---

## BAB 6 — KESIMPULAN DAN SARAN

### 6.1 Capaian MVP
(Rangkum fitur MVP yang berhasil diimplementasikan 100%.)

### 6.2 Fitur Bonus yang Diimplementasikan
(Sebutkan bonus yang sempat dikerjakan, jika ada.)

### 6.3 Refleksi & Kendala
(Ceritakan kendala teknis yang dihadapi tim dan cara mengatasinya —
misal: masalah koneksi database saat deploy, debugging trigger, dsb.)

### 6.4 Saran Pengembangan
(Contoh: integrasi notifikasi email, export PDF resmi, dsb.)

---

## LAMPIRAN

- Lampiran A — Script SQL Lengkap (lihat folder `sql/`)
- Lampiran B — ER Diagram ukuran penuh (export dari dbdiagram.io)
- Lampiran C — Link repository GitHub: (isi link)
- Lampiran D — URL Aplikasi Online: (isi link deploy)
- Lampiran E — Akun Demo: (isi kredensial demo)
