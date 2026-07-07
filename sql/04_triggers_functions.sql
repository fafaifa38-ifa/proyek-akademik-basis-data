-- =====================================================================
-- 04_triggers_functions.sql
-- Trigger, Stored Procedure/Function
-- =====================================================================
-- FUNCTION 1: fn_konversi_nilai(nilai_angka)
-- Mengonversi nilai angka -> nilai huruf & bobot (skala 0-4)
-- Dipakai oleh trigger nilai
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_konversi_nilai(p_nilai_angka NUMERIC)
RETURNS TABLE(huruf VARCHAR, bobot NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT
        CASE
            WHEN p_nilai_angka >= 85 THEN 'A'
            WHEN p_nilai_angka >= 80 THEN 'A-'
            WHEN p_nilai_angka >= 75 THEN 'B+'
            WHEN p_nilai_angka >= 70 THEN 'B'
            WHEN p_nilai_angka >= 65 THEN 'B-'
            WHEN p_nilai_angka >= 60 THEN 'C+'
            WHEN p_nilai_angka >= 55 THEN 'C'
            WHEN p_nilai_angka >= 40 THEN 'D'
            ELSE 'E'
        END::VARCHAR AS huruf,
        CASE
            WHEN p_nilai_angka >= 85 THEN 4.00
            WHEN p_nilai_angka >= 80 THEN 3.70
            WHEN p_nilai_angka >= 75 THEN 3.30
            WHEN p_nilai_angka >= 70 THEN 3.00
            WHEN p_nilai_angka >= 65 THEN 2.70
            WHEN p_nilai_angka >= 60 THEN 2.30
            WHEN p_nilai_angka >= 55 THEN 2.00
            WHEN p_nilai_angka >= 40 THEN 1.00
            ELSE 0.00
        END::NUMERIC AS bobot;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- =====================================================================
-- FUNCTION 2 (STORED PROCEDURE): sp_hitung_ip(p_nim, p_id_tahun_akademik)
-- Menghitung IPS semester tsb dan IPK kumulatif s/d semester tsb,
-- lalu menyimpan/mengupdate hasilnya ke tabel ringkasan_ip.
-- Ini adalah stored procedure wajib sesuai requirement SQL proyek.
-- =====================================================================
CREATE OR REPLACE PROCEDURE sp_hitung_ip(p_nim VARCHAR, p_id_tahun_akademik INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ips           NUMERIC(4,2);
    v_sks_semester  INT;
    v_ipk           NUMERIC(4,2);
    v_sks_lulus     INT;
BEGIN
    -- IPS semester berjalan: hanya mata kuliah pada tahun_akademik tsb yang sudah dinilai
    SELECT
        COALESCE(ROUND(SUM(mk.sks * n.bobot) / NULLIF(SUM(mk.sks), 0), 2), 0),
        COALESCE(SUM(mk.sks), 0)
    INTO v_ips, v_sks_semester
    FROM krs k
    JOIN jadwal_kuliah j ON j.id_jadwal = k.id_jadwal
    JOIN mata_kuliah mk  ON mk.kode_mk = j.kode_mk
    JOIN nilai n         ON n.id_krs = k.id_krs
    WHERE k.nim = p_nim
      AND k.id_tahun_akademik = p_id_tahun_akademik
      AND k.status_krs = 'Aktif';

    -- IPK kumulatif: seluruh mata kuliah yang sudah dinilai dari semua semester
    SELECT
        COALESCE(ROUND(SUM(mk.sks * n.bobot) / NULLIF(SUM(mk.sks), 0), 2), 0),
        COALESCE(SUM(mk.sks) FILTER (WHERE n.nilai_huruf NOT IN ('D','E')), 0)
    INTO v_ipk, v_sks_lulus
    FROM krs k
    JOIN jadwal_kuliah j ON j.id_jadwal = k.id_jadwal
    JOIN mata_kuliah mk  ON mk.kode_mk = j.kode_mk
    JOIN nilai n         ON n.id_krs = k.id_krs
    WHERE k.nim = p_nim
      AND k.status_krs = 'Aktif';

    INSERT INTO ringkasan_ip (nim, id_tahun_akademik, ips, sks_semester, ipk, total_sks_lulus, updated_at)
    VALUES (p_nim, p_id_tahun_akademik, v_ips, v_sks_semester, v_ipk, v_sks_lulus, now())
    ON CONFLICT (nim, id_tahun_akademik)
    DO UPDATE SET
        ips = EXCLUDED.ips,
        sks_semester = EXCLUDED.sks_semester,
        ipk = EXCLUDED.ipk,
        total_sks_lulus = EXCLUDED.total_sks_lulus,
        updated_at = now();
END;
$$;


-- =====================================================================
-- TRIGGER 1: trg_konversi_dan_hitung_ip
-- - Saat baris nilai di-INSERT/UPDATE: otomatis isi nilai_huruf & bobot,
--   lalu panggil sp_hitung_ip untuk mahasiswa & tahun akademik terkait.
-- Ini mengimplementasikan requirement:
-- "TRIGGER: hitung ulang IPK di tabel ringkasan setiap INSERT nilai"
-- =====================================================================
CREATE OR REPLACE FUNCTION trg_fn_konversi_dan_hitung_ip()
RETURNS TRIGGER AS $$
DECLARE
    v_nim VARCHAR;
    v_id_tahun_akademik INT;
    v_konversi RECORD;
BEGIN
    -- konversi nilai angka -> huruf & bobot
    SELECT * INTO v_konversi FROM fn_konversi_nilai(NEW.nilai_angka);
    NEW.nilai_huruf := v_konversi.huruf;
    NEW.bobot        := v_konversi.bobot;

    -- cari nim & tahun akademik dari krs terkait
    SELECT k.nim, k.id_tahun_akademik
    INTO v_nim, v_id_tahun_akademik
    FROM krs k
    WHERE k.id_krs = NEW.id_krs;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_konversi_nilai ON nilai;
CREATE TRIGGER trg_konversi_nilai
    BEFORE INSERT OR UPDATE OF nilai_angka ON nilai
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_konversi_dan_hitung_ip();


-- Trigger AFTER: panggil sp_hitung_ip setelah baris nilai benar-benar tersimpan
CREATE OR REPLACE FUNCTION trg_fn_after_nilai_hitung_ip()
RETURNS TRIGGER AS $$
DECLARE
    v_nim VARCHAR;
    v_id_tahun_akademik INT;
BEGIN
    SELECT k.nim, k.id_tahun_akademik
    INTO v_nim, v_id_tahun_akademik
    FROM krs k
    WHERE k.id_krs = NEW.id_krs;

    CALL sp_hitung_ip(v_nim, v_id_tahun_akademik);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_after_nilai_hitung_ip ON nilai;
CREATE TRIGGER trg_after_nilai_hitung_ip
    AFTER INSERT OR UPDATE OF nilai_angka ON nilai
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_after_nilai_hitung_ip();


-- =====================================================================
-- TRIGGER 2: trg_validasi_prasyarat
-- Requirement: "TRIGGER: validasi prasyarat MK saat INSERT ke tabel KRS"
-- Menolak (RAISE EXCEPTION) jika mahasiswa mengambil MK yang prasyaratnya
-- belum lulus (nilai_huruf bukan D/E, dan sudah ada nilai).
-- =====================================================================
CREATE OR REPLACE FUNCTION trg_fn_validasi_prasyarat()
RETURNS TRIGGER AS $$
DECLARE
    v_kode_mk VARCHAR;
    v_prasyarat_belum_lulus VARCHAR;
BEGIN
    -- ambil kode_mk dari jadwal yang mau diambil
    SELECT j.kode_mk INTO v_kode_mk
    FROM jadwal_kuliah j
    WHERE j.id_jadwal = NEW.id_jadwal;

    -- cek semua prasyarat mata kuliah tsb
    SELECT pm.kode_mk_prasyarat INTO v_prasyarat_belum_lulus
    FROM prasyarat_mk pm
    WHERE pm.kode_mk = v_kode_mk
      AND NOT EXISTS (
            SELECT 1
            FROM krs k2
            JOIN jadwal_kuliah j2 ON j2.id_jadwal = k2.id_jadwal
            JOIN nilai n2          ON n2.id_krs = k2.id_krs
            WHERE k2.nim = NEW.nim
              AND j2.kode_mk = pm.kode_mk_prasyarat
              AND k2.status_krs = 'Aktif'
              AND n2.nilai_huruf NOT IN ('D', 'E')
      )
    LIMIT 1;

    IF v_prasyarat_belum_lulus IS NOT NULL THEN
        RAISE EXCEPTION 'Mahasiswa % belum lulus mata kuliah prasyarat % untuk mengambil %',
            NEW.nim, v_prasyarat_belum_lulus, v_kode_mk;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validasi_prasyarat ON krs;
CREATE TRIGGER trg_validasi_prasyarat
    BEFORE INSERT ON krs
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_validasi_prasyarat();


-- =====================================================================
-- Backfill: hitung ulang ringkasan_ip untuk semua data dummy yang sudah
-- ada nilainya (karena trigger AFTER hanya berlaku untuk INSERT baru
-- setelah trigger ini dibuat, sedangkan data dummy sudah dimasukkan
-- lebih dulu di 02_dummy_data.sql)
-- =====================================================================
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT DISTINCT k.nim, k.id_tahun_akademik
        FROM krs k
        JOIN nilai n ON n.id_krs = k.id_krs
    LOOP
        CALL sp_hitung_ip(r.nim, r.id_tahun_akademik);
    END LOOP;
END $$;

-- Selesai triggers & functions.
