-- =====================================================================
-- 06_complex_queries.sql
-- Minimal 10 query kompleks (JOIN 2+ tabel, subquery, aggregate,
-- GROUP BY, HAVING, CASE WHEN, window function)
-- Dipakai untuk BAB Analitik & Pelaporan
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Distribusi IPK per angkatan menggunakan CASE WHEN + COUNT
-- ---------------------------------------------------------------------
SELECT
    a.tahun_masuk AS angkatan,
    CASE
        WHEN r.ipk >= 3.51 THEN 'Cumlaude (>=3.51)'
        WHEN r.ipk >= 3.01 THEN 'Sangat Memuaskan (3.01-3.50)'
        WHEN r.ipk >= 2.51 THEN 'Memuaskan (2.51-3.00)'
        ELSE 'Perlu Perhatian (<2.51)'
    END AS kategori_ipk,
    COUNT(*) AS jumlah_mahasiswa
FROM mahasiswa m
JOIN angkatan a ON a.id_angkatan = m.id_angkatan
JOIN LATERAL (
    SELECT ipk FROM ringkasan_ip ri
    WHERE ri.nim = m.nim ORDER BY ri.id_tahun_akademik DESC LIMIT 1
) r ON true
GROUP BY a.tahun_masuk, kategori_ipk
ORDER BY a.tahun_masuk, kategori_ipk;


-- ---------------------------------------------------------------------
-- 2. Mata kuliah dengan rata-rata nilai terendah (GROUP BY + AVG + ORDER BY)
-- ---------------------------------------------------------------------
SELECT
    mk.kode_mk,
    mk.nama_mk,
    ROUND(AVG(n.nilai_angka), 2) AS rata_rata_nilai,
    COUNT(n.id_nilai) AS jumlah_peserta_dinilai
FROM nilai n
JOIN krs k          ON k.id_krs = n.id_krs
JOIN jadwal_kuliah j ON j.id_jadwal = k.id_jadwal
JOIN mata_kuliah mk  ON mk.kode_mk = j.kode_mk
GROUP BY mk.kode_mk, mk.nama_mk
ORDER BY rata_rata_nilai ASC;


-- ---------------------------------------------------------------------
-- 3. Dosen dengan beban mengajar terbanyak per semester (JOIN + COUNT)
-- ---------------------------------------------------------------------
SELECT
    d.nama AS nama_dosen,
    ta.tahun_ajaran,
    ta.semester,
    COUNT(DISTINCT j.id_jadwal) AS jumlah_kelas_diampu,
    SUM(mk.sks) AS total_sks_mengajar
FROM jadwal_kuliah j
JOIN dosen d           ON d.id_dosen = j.id_dosen
JOIN mata_kuliah mk    ON mk.kode_mk = j.kode_mk
JOIN tahun_akademik ta ON ta.id_tahun_akademik = j.id_tahun_akademik
GROUP BY d.nama, ta.tahun_ajaran, ta.semester
ORDER BY ta.tahun_ajaran, ta.semester, total_sks_mengajar DESC;


-- ---------------------------------------------------------------------
-- 4. Tren IPK rata-rata program studi dari tahun ke tahun
-- ---------------------------------------------------------------------
SELECT
    ps.nama_prodi,
    ta.tahun_ajaran,
    ROUND(AVG(ri.ipk), 2) AS rata_rata_ipk_prodi
FROM ringkasan_ip ri
JOIN mahasiswa m       ON m.nim = ri.nim
JOIN program_studi ps  ON ps.id_prodi = m.id_prodi
JOIN tahun_akademik ta ON ta.id_tahun_akademik = ri.id_tahun_akademik
GROUP BY ps.nama_prodi, ta.tahun_ajaran
ORDER BY ps.nama_prodi, ta.tahun_ajaran;


-- ---------------------------------------------------------------------
-- 5. Mahasiswa dengan IPS < 2.00 semester aktif (indikasi berisiko DO)
-- ---------------------------------------------------------------------
SELECT
    m.nim,
    m.nama,
    ta.tahun_ajaran,
    ta.semester,
    ri.ips
FROM ringkasan_ip ri
JOIN mahasiswa m       ON m.nim = ri.nim
JOIN tahun_akademik ta ON ta.id_tahun_akademik = ri.id_tahun_akademik
WHERE ri.ips < 2.00
  AND ri.ips > 0
ORDER BY ri.ips ASC;


-- ---------------------------------------------------------------------
-- 6. Distribusi nilai (A/B/C/D/E) per mata kuliah (aggregate)
-- ---------------------------------------------------------------------
SELECT
    mk.kode_mk,
    mk.nama_mk,
    COUNT(*) FILTER (WHERE n.nilai_huruf LIKE 'A%') AS jumlah_A,
    COUNT(*) FILTER (WHERE n.nilai_huruf LIKE 'B%') AS jumlah_B,
    COUNT(*) FILTER (WHERE n.nilai_huruf LIKE 'C%') AS jumlah_C,
    COUNT(*) FILTER (WHERE n.nilai_huruf = 'D')     AS jumlah_D,
    COUNT(*) FILTER (WHERE n.nilai_huruf = 'E')     AS jumlah_E
FROM nilai n
JOIN krs k          ON k.id_krs = n.id_krs
JOIN jadwal_kuliah j ON j.id_jadwal = k.id_jadwal
JOIN mata_kuliah mk  ON mk.kode_mk = j.kode_mk
GROUP BY mk.kode_mk, mk.nama_mk
ORDER BY mk.kode_mk;


-- ---------------------------------------------------------------------
-- 7. Top 3 mahasiswa IPK tertinggi per angkatan (WINDOW FUNCTION RANK)
-- ---------------------------------------------------------------------
SELECT *
FROM (
    SELECT
        a.tahun_masuk AS angkatan,
        m.nim,
        m.nama,
        r.ipk,
        RANK() OVER (PARTITION BY a.tahun_masuk ORDER BY r.ipk DESC) AS peringkat
    FROM mahasiswa m
    JOIN angkatan a ON a.id_angkatan = m.id_angkatan
    JOIN LATERAL (
        SELECT ipk FROM ringkasan_ip ri
        WHERE ri.nim = m.nim ORDER BY ri.id_tahun_akademik DESC LIMIT 1
    ) r ON true
) ranked
WHERE peringkat <= 3
ORDER BY angkatan, peringkat;


-- ---------------------------------------------------------------------
-- 8. Mahasiswa yang mengambil MK padahal ada prasyarat belum lulus
--    (query audit -- seharusnya kosong karena sudah dicegah trigger)
--    Menggunakan NOT EXISTS (subquery bertingkat)
-- ---------------------------------------------------------------------
SELECT
    m.nim,
    m.nama,
    mk.kode_mk AS mk_diambil,
    pm.kode_mk_prasyarat AS prasyarat_belum_lulus
FROM krs k
JOIN mahasiswa m       ON m.nim = k.nim
JOIN jadwal_kuliah j    ON j.id_jadwal = k.id_jadwal
JOIN mata_kuliah mk     ON mk.kode_mk = j.kode_mk
JOIN prasyarat_mk pm    ON pm.kode_mk = mk.kode_mk
WHERE k.status_krs = 'Aktif'
  AND NOT EXISTS (
        SELECT 1
        FROM krs k2
        JOIN jadwal_kuliah j2 ON j2.id_jadwal = k2.id_jadwal
        JOIN nilai n2          ON n2.id_krs = k2.id_krs
        WHERE k2.nim = m.nim
          AND j2.kode_mk = pm.kode_mk_prasyarat
          AND n2.nilai_huruf NOT IN ('D', 'E')
  );


-- ---------------------------------------------------------------------
-- 9. Penerima beasiswa dengan IPK di bawah syarat minimum 3.00
--    (subquery + JOIN, untuk validasi kelayakan beasiswa)
-- ---------------------------------------------------------------------
SELECT
    m.nim,
    m.nama,
    b.nama_beasiswa,
    r.ipk
FROM penerima_beasiswa pb
JOIN mahasiswa m ON m.nim = pb.nim
JOIN beasiswa b  ON b.id_beasiswa = pb.id_beasiswa
JOIN LATERAL (
    SELECT ipk FROM ringkasan_ip ri
    WHERE ri.nim = m.nim ORDER BY ri.id_tahun_akademik DESC LIMIT 1
) r ON true
WHERE pb.status = 'Aktif'
  AND r.ipk < 3.00;


-- ---------------------------------------------------------------------
-- 10. Rekap SKS lulus & mata kuliah yang sudah diambil per mahasiswa
--     (aggregate + GROUP BY + HAVING)
-- ---------------------------------------------------------------------
SELECT
    m.nim,
    m.nama,
    COUNT(n.id_nilai) AS jumlah_mk_selesai,
    SUM(mk.sks) FILTER (WHERE n.nilai_huruf NOT IN ('D','E')) AS total_sks_lulus
FROM krs k
JOIN mahasiswa m     ON m.nim = k.nim
JOIN jadwal_kuliah j  ON j.id_jadwal = k.id_jadwal
JOIN mata_kuliah mk   ON mk.kode_mk = j.kode_mk
JOIN nilai n          ON n.id_krs = k.id_krs
GROUP BY m.nim, m.nama
HAVING SUM(mk.sks) FILTER (WHERE n.nilai_huruf NOT IN ('D','E')) > 0
ORDER BY total_sks_lulus DESC;


-- ---------------------------------------------------------------------
-- 11. Ruang kelas paling sering dipakai (COUNT + GROUP BY + ORDER BY)
-- ---------------------------------------------------------------------
SELECT
    rk.nama_ruang,
    rk.gedung,
    COUNT(j.id_jadwal) AS jumlah_jadwal_terpakai
FROM jadwal_kuliah j
JOIN ruang_kelas rk ON rk.id_ruang = j.id_ruang
GROUP BY rk.nama_ruang, rk.gedung
ORDER BY jumlah_jadwal_terpakai DESC;


-- ---------------------------------------------------------------------
-- 12. Predikat kelulusan (simulasi) berdasarkan IPK memakai CASE WHEN
--     (dipakai untuk cetak transkrip / prediksi predikat)
-- ---------------------------------------------------------------------
SELECT
    m.nim,
    m.nama,
    r.ipk,
    CASE
        WHEN r.ipk >= 3.51 THEN 'Cum Laude'
        WHEN r.ipk >= 3.01 THEN 'Sangat Memuaskan'
        WHEN r.ipk >= 2.76 THEN 'Memuaskan'
        ELSE 'Cukup'
    END AS predikat
FROM mahasiswa m
JOIN LATERAL (
    SELECT ipk FROM ringkasan_ip ri
    WHERE ri.nim = m.nim ORDER BY ri.id_tahun_akademik DESC LIMIT 1
) r ON true
ORDER BY r.ipk DESC;

-- Selesai query kompleks (12 query, melebihi minimal 10).
