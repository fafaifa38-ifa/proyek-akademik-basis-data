-- =====================================================================
-- 05_transaksi_demo.sql
-- Demonstrasi skenario transaksi BEGIN - COMMIT - ROLLBACK
-- Jalankan baris per baris (blok per blok) di pgAdmin Query Tool,
-- lalu screenshot hasilnya untuk laporan BAB 5 (Pengujian).
-- =====================================================================

-- =====================================================================
-- SKENARIO 1: BERHASIL (COMMIT)
-- Mahasiswa 2024210014 mengambil KRS untuk mata kuliah SI102
-- (SI102 tidak punya prasyarat, jadi seharusnya berhasil)
-- =====================================================================
BEGIN;

INSERT INTO krs (nim, id_jadwal, id_tahun_akademik)
VALUES ('2024210014', 2, 3);   -- id_jadwal 2 = SI102 kelas A semester aktif

-- cek hasil sebelum commit
SELECT * FROM krs WHERE nim = '2024210014';

COMMIT;
-- Setelah COMMIT, data permanen tersimpan.


-- =====================================================================
-- SKENARIO 2: GAGAL (ROLLBACK otomatis oleh trigger validasi prasyarat)
-- Mahasiswa 2024210014 mencoba mengambil SI401 (Analisis & Perancangan
-- Sistem Informasi), padahal belum lulus prasyaratnya (SI301 & SI202).
-- Trigger trg_validasi_prasyarat akan menolak dengan RAISE EXCEPTION,
-- yang otomatis membatalkan transaksi (implicit ROLLBACK di PostgreSQL).
-- =====================================================================
BEGIN;

INSERT INTO krs (nim, id_jadwal, id_tahun_akademik)
VALUES ('2024210014', 6, 3);   -- id_jadwal 6 = SI401 kelas A semester aktif
-- >>> Akan muncul ERROR:
-- "Mahasiswa 2024210014 belum lulus mata kuliah prasyarat SI301 untuk mengambil SI401"
-- Transaksi otomatis batal, tidak ada data yang masuk ke tabel krs.

ROLLBACK;  -- jalankan eksplisit jika belum otomatis ter-abort


-- =====================================================================
-- SKENARIO 3: ROLLBACK MANUAL
-- Simulasi kesalahan input nilai yang ingin dibatalkan secara manual
-- sebelum di-COMMIT.
-- =====================================================================
BEGIN;

-- cari id_krs milik mahasiswa 2024210011 pada MK SI101 semester aktif
-- (memakai subquery, jadi tidak perlu tebak ID secara manual)
INSERT INTO nilai (id_krs, nilai_angka)
SELECT k.id_krs, 40   -- misal salah ketik 40 padahal maksud 90
FROM krs k
JOIN jadwal_kuliah j ON j.id_jadwal = k.id_jadwal
WHERE k.nim = '2024210011' AND j.kode_mk = 'SI101' AND k.id_tahun_akademik = 3;

-- cek dulu hasilnya sebelum dibatalkan
SELECT * FROM nilai n
JOIN krs k ON k.id_krs = n.id_krs
WHERE k.nim = '2024210011';

-- setelah disadari salah, batalkan seluruh transaksi
ROLLBACK;
-- Data nilai yang salah tadi TIDAK tersimpan ke database.


-- =====================================================================
-- SKENARIO 4: TRANSAKSI ATOMIK MULTI-TABEL
-- Proses "selesai input nilai akhir kelas" yang melibatkan lebih dari
-- satu operasi sekaligus: insert nilai + panggil stored procedure
-- hitung IP. Semua harus berhasil bersama atau gagal bersama.
-- =====================================================================
BEGIN;

INSERT INTO nilai (id_krs, nilai_angka)
SELECT k.id_krs, 88   -- nilai SI102 untuk mhs 2024210011
FROM krs k
JOIN jadwal_kuliah j ON j.id_jadwal = k.id_jadwal
WHERE k.nim = '2024210011' AND j.kode_mk = 'SI102' AND k.id_tahun_akademik = 3;

CALL sp_hitung_ip('2024210011', 3);

-- verifikasi ringkasan IP ter-update
SELECT * FROM ringkasan_ip WHERE nim = '2024210011';

COMMIT;

-- Selesai demo transaksi.
