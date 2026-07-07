-- =====================================================================
-- 03_views.sql
-- Minimal 3 VIEW yang aktif dipakai aplikasi/laporan
-- =====================================================================

-- =====================================================================
-- VIEW 1: view_transkrip_mahasiswa
-- Dipakai fitur "Cetak transkrip nilai sementara" (portal mahasiswa)
-- =====================================================================
CREATE OR REPLACE VIEW view_transkrip_mahasiswa AS
SELECT
    m.nim,
    m.nama                              AS nama_mahasiswa,
    ta.tahun_ajaran,
    ta.semester,
    mk.kode_mk,
    mk.nama_mk,
    mk.sks,
    n.nilai_angka,
    n.nilai_huruf,
    n.bobot,
    (mk.sks * n.bobot)                  AS mutu
FROM krs k
JOIN mahasiswa m        ON m.nim = k.nim
JOIN jadwal_kuliah j     ON j.id_jadwal = k.id_jadwal
JOIN mata_kuliah mk      ON mk.kode_mk = j.kode_mk
JOIN tahun_akademik ta   ON ta.id_tahun_akademik = k.id_tahun_akademik
LEFT JOIN nilai n        ON n.id_krs = k.id_krs
WHERE k.status_krs = 'Aktif'
ORDER BY m.nim, ta.tahun_ajaran, ta.semester;

-- =====================================================================
-- VIEW 2: view_beban_studi_semester
-- Dipakai fitur "rekap beban studi per semester" (dashboard mahasiswa/kaprodi)
-- =====================================================================
CREATE OR REPLACE VIEW view_beban_studi_semester AS
SELECT
    m.nim,
    m.nama                  AS nama_mahasiswa,
    ta.id_tahun_akademik,
    ta.tahun_ajaran,
    ta.semester,
    COUNT(k.id_krs)          AS jumlah_mk_diambil,
    SUM(mk.sks)              AS total_sks_diambil
FROM krs k
JOIN mahasiswa m       ON m.nim = k.nim
JOIN jadwal_kuliah j   ON j.id_jadwal = k.id_jadwal
JOIN mata_kuliah mk    ON mk.kode_mk = j.kode_mk
JOIN tahun_akademik ta ON ta.id_tahun_akademik = k.id_tahun_akademik
WHERE k.status_krs = 'Aktif'
GROUP BY m.nim, m.nama, ta.id_tahun_akademik, ta.tahun_ajaran, ta.semester;

-- =====================================================================
-- VIEW 3: view_dashboard_kaprodi
-- Dipakai fitur "Dashboard ketua prodi: statistik mahasiswa aktif,
-- IPK rata-rata per angkatan"
-- =====================================================================
CREATE OR REPLACE VIEW view_dashboard_kaprodi AS
SELECT
    ps.nama_prodi,
    a.tahun_masuk                                   AS angkatan,
    COUNT(DISTINCT m.nim) FILTER (WHERE m.status_mahasiswa = 'Aktif') AS jumlah_mhs_aktif,
    ROUND(AVG(r.ipk)::numeric, 2)                   AS rata_rata_ipk
FROM mahasiswa m
JOIN program_studi ps ON ps.id_prodi = m.id_prodi
JOIN angkatan a        ON a.id_angkatan = m.id_angkatan
LEFT JOIN LATERAL (
    -- ambil baris ringkasan_ip terbaru per mahasiswa
    SELECT ri.ipk
    FROM ringkasan_ip ri
    WHERE ri.nim = m.nim
    ORDER BY ri.id_tahun_akademik DESC
    LIMIT 1
) r ON true
GROUP BY ps.nama_prodi, a.tahun_masuk
ORDER BY ps.nama_prodi, a.tahun_masuk;

-- =====================================================================
-- VIEW 4 (tambahan): view_jadwal_mahasiswa
-- Dipakai fitur "Portal mahasiswa: lihat jadwal kuliah"
-- =====================================================================
CREATE OR REPLACE VIEW view_jadwal_mahasiswa AS
SELECT
    k.nim,
    j.id_jadwal,
    mk.kode_mk,
    mk.nama_mk,
    mk.sks,
    d.nama          AS nama_dosen,
    rk.nama_ruang,
    j.kelas,
    j.hari,
    j.jam_mulai,
    j.jam_selesai,
    ta.tahun_ajaran,
    ta.semester
FROM krs k
JOIN jadwal_kuliah j    ON j.id_jadwal = k.id_jadwal
JOIN mata_kuliah mk     ON mk.kode_mk = j.kode_mk
JOIN dosen d            ON d.id_dosen = j.id_dosen
LEFT JOIN ruang_kelas rk ON rk.id_ruang = j.id_ruang
JOIN tahun_akademik ta  ON ta.id_tahun_akademik = j.id_tahun_akademik
WHERE k.status_krs = 'Aktif';

-- =====================================================================
-- VIEW 5 (tambahan): view_daftar_kelas_dosen
-- Dipakai fitur "Portal dosen: lihat daftar kelas"
-- =====================================================================
CREATE OR REPLACE VIEW view_daftar_kelas_dosen AS
SELECT
    j.id_jadwal,
    d.id_dosen,
    d.nama            AS nama_dosen,
    mk.kode_mk,
    mk.nama_mk,
    j.kelas,
    ta.tahun_ajaran,
    ta.semester,
    COUNT(k.id_krs)   AS jumlah_peserta,
    COUNT(n.id_nilai) AS jumlah_sudah_dinilai
FROM jadwal_kuliah j
JOIN dosen d           ON d.id_dosen = j.id_dosen
JOIN mata_kuliah mk    ON mk.kode_mk = j.kode_mk
JOIN tahun_akademik ta ON ta.id_tahun_akademik = j.id_tahun_akademik
LEFT JOIN krs k        ON k.id_jadwal = j.id_jadwal AND k.status_krs = 'Aktif'
LEFT JOIN nilai n      ON n.id_krs = k.id_krs
GROUP BY j.id_jadwal, d.id_dosen, d.nama, mk.kode_mk, mk.nama_mk, j.kelas, ta.tahun_ajaran, ta.semester;

-- =====================================================================
-- VIEW 6 (tambahan): view_struktur_kurikulum
-- Dipakai fitur "Portal mahasiswa: lihat struktur kurikulum angkatannya"
-- =====================================================================
CREATE OR REPLACE VIEW view_struktur_kurikulum AS
SELECT
    k.id_kurikulum,
    k.nama_kurikulum,
    ps.nama_prodi,
    a.tahun_masuk           AS angkatan,
    km.semester_ke,
    km.kode_mk,
    mk.nama_mk,
    mk.sks,
    km.sifat
FROM kurikulum_mk km
JOIN kurikulum k        ON k.id_kurikulum = km.id_kurikulum
JOIN mata_kuliah mk      ON mk.kode_mk = km.kode_mk
JOIN program_studi ps    ON ps.id_prodi = k.id_prodi
LEFT JOIN angkatan a     ON a.id_kurikulum = k.id_kurikulum
ORDER BY k.id_kurikulum, km.semester_ke, km.kode_mk;

-- Selesai views.
