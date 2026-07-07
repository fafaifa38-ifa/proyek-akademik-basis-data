-- =====================================================================
-- 01_ddl.sql
-- Sistem Analitik Akademik & Prestasi Mahasiswa
-- =====================================================================

-- =====================================================================
-- 1. program_studi
-- =====================================================================
CREATE TABLE program_studi (
    id_prodi        SERIAL PRIMARY KEY,
    kode_prodi      VARCHAR(10) UNIQUE NOT NULL,
    nama_prodi      VARCHAR(100) NOT NULL,
    jenjang         VARCHAR(10) NOT NULL CHECK (jenjang IN ('D3','S1','S2')),
    akreditasi      VARCHAR(5)
);

-- =====================================================================
-- 2. kurikulum
-- 1 program studi bisa punya beberapa versi kurikulum dari tahun ke tahun
-- =====================================================================
CREATE TABLE kurikulum (
    id_kurikulum    SERIAL PRIMARY KEY,
    id_prodi        INT NOT NULL REFERENCES program_studi(id_prodi),
    nama_kurikulum  VARCHAR(50) NOT NULL,   -- contoh: 'Kurikulum 2023'
    tahun_berlaku   INT NOT NULL,
    is_aktif        BOOLEAN DEFAULT true
);

-- =====================================================================
-- 3. angkatan
-- id_kurikulum: kurikulum yang diikuti angkatan ini (boleh NULL jika
-- belum ditetapkan)
-- =====================================================================
CREATE TABLE angkatan (
    id_angkatan     SERIAL PRIMARY KEY,
    tahun_masuk     INT UNIQUE NOT NULL CHECK (tahun_masuk BETWEEN 2000 AND 2100),
    id_kurikulum    INT REFERENCES kurikulum(id_kurikulum)
);

-- =====================================================================
-- 4. mahasiswa
-- =====================================================================
CREATE TABLE mahasiswa (
    nim                 VARCHAR(15) PRIMARY KEY,
    nama                VARCHAR(100) NOT NULL,
    id_prodi            INT NOT NULL REFERENCES program_studi(id_prodi),
    id_angkatan         INT NOT NULL REFERENCES angkatan(id_angkatan),
    jenis_kelamin       CHAR(1) CHECK (jenis_kelamin IN ('L','P')),
    tanggal_lahir       DATE,
    alamat              TEXT,
    email               VARCHAR(100) UNIQUE,
    no_hp               VARCHAR(20),
    status_mahasiswa    VARCHAR(20) NOT NULL DEFAULT 'Aktif'
                         CHECK (status_mahasiswa IN ('Aktif','Cuti','Lulus','DO')),
    created_at          TIMESTAMP DEFAULT now()
);

-- =====================================================================
-- 5. dosen
-- =====================================================================
CREATE TABLE dosen (
    id_dosen        SERIAL PRIMARY KEY,
    nidn            VARCHAR(20) UNIQUE NOT NULL,
    nama            VARCHAR(100) NOT NULL,
    id_prodi        INT REFERENCES program_studi(id_prodi),
    email           VARCHAR(100) UNIQUE,
    no_hp           VARCHAR(20)
);

-- =====================================================================
-- 6. tahun_akademik
-- =====================================================================
CREATE TABLE tahun_akademik (
    id_tahun_akademik  SERIAL PRIMARY KEY,
    tahun_ajaran        VARCHAR(9) NOT NULL,      -- contoh '2024/2025'
    semester             VARCHAR(6) NOT NULL CHECK (semester IN ('Ganjil','Genap')),
    is_aktif             BOOLEAN DEFAULT false,
    UNIQUE (tahun_ajaran, semester)
);

-- =====================================================================
-- 7. mata_kuliah
-- =====================================================================
CREATE TABLE mata_kuliah (
    kode_mk         VARCHAR(10) PRIMARY KEY,
    nama_mk         VARCHAR(100) NOT NULL,
    sks             INT NOT NULL CHECK (sks > 0),
    id_prodi        INT REFERENCES program_studi(id_prodi),
    semester_ke     INT CHECK (semester_ke BETWEEN 1 AND 14)
);

-- =====================================================================
-- 8. kurikulum_mk (relasi many-to-many kurikulum -> mata_kuliah, dengan
-- atribut tambahan semester_ke & sifat yang spesifik per versi kurikulum)
-- =====================================================================
CREATE TABLE kurikulum_mk (
    id_kurikulum    INT NOT NULL REFERENCES kurikulum(id_kurikulum) ON DELETE CASCADE,
    kode_mk         VARCHAR(10) NOT NULL REFERENCES mata_kuliah(kode_mk) ON DELETE CASCADE,
    semester_ke     INT NOT NULL CHECK (semester_ke BETWEEN 1 AND 14),
    sifat           VARCHAR(10) DEFAULT 'Wajib' CHECK (sifat IN ('Wajib','Pilihan')),
    PRIMARY KEY (id_kurikulum, kode_mk)
);

-- =====================================================================
-- 9. prasyarat_mk (relasi many-to-many mata kuliah -> mata kuliah)
-- =====================================================================
CREATE TABLE prasyarat_mk (
    kode_mk             VARCHAR(10) REFERENCES mata_kuliah(kode_mk) ON DELETE CASCADE,
    kode_mk_prasyarat   VARCHAR(10) REFERENCES mata_kuliah(kode_mk) ON DELETE CASCADE,
    PRIMARY KEY (kode_mk, kode_mk_prasyarat),
    CHECK (kode_mk <> kode_mk_prasyarat)
);

-- =====================================================================
-- 10. ruang_kelas
-- =====================================================================
CREATE TABLE ruang_kelas (
    id_ruang        SERIAL PRIMARY KEY,
    nama_ruang      VARCHAR(20) UNIQUE NOT NULL,
    gedung          VARCHAR(50),
    kapasitas       INT CHECK (kapasitas > 0)
);

-- =====================================================================
-- 11. jadwal_kuliah
-- =====================================================================
CREATE TABLE jadwal_kuliah (
    id_jadwal           SERIAL PRIMARY KEY,
    kode_mk              VARCHAR(10) NOT NULL REFERENCES mata_kuliah(kode_mk),
    id_dosen             INT NOT NULL REFERENCES dosen(id_dosen),
    id_ruang             INT REFERENCES ruang_kelas(id_ruang),
    id_tahun_akademik    INT NOT NULL REFERENCES tahun_akademik(id_tahun_akademik),
    kelas                VARCHAR(5) NOT NULL,
    hari                 VARCHAR(10),
    jam_mulai            TIME,
    jam_selesai          TIME,
    kuota                INT DEFAULT 40,
    UNIQUE (kode_mk, kelas, id_tahun_akademik),
    CHECK (jam_selesai > jam_mulai)
);

-- =====================================================================
-- 12. krs (kartu rencana studi -- baris = 1 mahasiswa ambil 1 kelas)
-- =====================================================================
CREATE TABLE krs (
    id_krs               SERIAL PRIMARY KEY,
    nim                   VARCHAR(15) NOT NULL REFERENCES mahasiswa(nim),
    id_jadwal             INT NOT NULL REFERENCES jadwal_kuliah(id_jadwal),
    id_tahun_akademik     INT NOT NULL REFERENCES tahun_akademik(id_tahun_akademik),
    tanggal_input         TIMESTAMP DEFAULT now(),
    status_krs            VARCHAR(20) DEFAULT 'Aktif' CHECK (status_krs IN ('Aktif','Batal')),
    UNIQUE (nim, id_jadwal)
);

-- =====================================================================
-- 13. nilai (1 KRS punya maksimal 1 nilai)
-- =====================================================================
CREATE TABLE nilai (
    id_nilai        SERIAL PRIMARY KEY,
    id_krs           INT NOT NULL UNIQUE REFERENCES krs(id_krs),
    nilai_angka      NUMERIC(5,2) CHECK (nilai_angka BETWEEN 0 AND 100),
    nilai_huruf      VARCHAR(2),
    bobot            NUMERIC(3,2),
    tanggal_input    TIMESTAMP DEFAULT now()
);

-- =====================================================================
-- 14. ringkasan_ip (tabel ringkasan, di-update otomatis oleh TRIGGER)
-- =====================================================================
CREATE TABLE ringkasan_ip (
    nim                  VARCHAR(15) REFERENCES mahasiswa(nim),
    id_tahun_akademik    INT REFERENCES tahun_akademik(id_tahun_akademik),
    ips                   NUMERIC(4,2) DEFAULT 0,
    sks_semester           INT DEFAULT 0,
    ipk                   NUMERIC(4,2) DEFAULT 0,
    total_sks_lulus       INT DEFAULT 0,
    updated_at            TIMESTAMP DEFAULT now(),
    PRIMARY KEY (nim, id_tahun_akademik)
);

-- =====================================================================
-- 15. beasiswa
-- =====================================================================
CREATE TABLE beasiswa (
    id_beasiswa      SERIAL PRIMARY KEY,
    nama_beasiswa    VARCHAR(100) NOT NULL,
    sumber           VARCHAR(50),
    nominal          NUMERIC(12,2)
);

-- =====================================================================
-- 16. penerima_beasiswa
-- =====================================================================
CREATE TABLE penerima_beasiswa (
    id_penerima          SERIAL PRIMARY KEY,
    nim                   VARCHAR(15) NOT NULL REFERENCES mahasiswa(nim),
    id_beasiswa           INT NOT NULL REFERENCES beasiswa(id_beasiswa),
    id_tahun_akademik     INT NOT NULL REFERENCES tahun_akademik(id_tahun_akademik),
    status                VARCHAR(20) DEFAULT 'Aktif',
    UNIQUE (nim, id_beasiswa, id_tahun_akademik)
);

-- =====================================================================
-- 17. prestasi_non_akademik
-- =====================================================================
CREATE TABLE prestasi_non_akademik (
    id_prestasi      SERIAL PRIMARY KEY,
    nim               VARCHAR(15) NOT NULL REFERENCES mahasiswa(nim),
    nama_prestasi     VARCHAR(150) NOT NULL,
    tingkat           VARCHAR(30) CHECK (tingkat IN ('Lokal','Nasional','Internasional')),
    tahun             INT,
    keterangan        TEXT
);

-- =====================================================================
-- 18. users (autentikasi aplikasi)
-- =====================================================================
CREATE TABLE users (
    id_user          SERIAL PRIMARY KEY,
    username          VARCHAR(50) UNIQUE NOT NULL,
    password_hash     VARCHAR(255) NOT NULL,
    role              VARCHAR(20) NOT NULL CHECK (role IN ('admin','mahasiswa','dosen','kaprodi')),
    nim               VARCHAR(15) REFERENCES mahasiswa(nim),
    id_dosen          INT REFERENCES dosen(id_dosen)
);

-- =====================================================================
-- INDEX tambahan (selain yang otomatis terbentuk dari PK/UNIQUE)
-- =====================================================================
CREATE INDEX idx_mahasiswa_prodi        ON mahasiswa(id_prodi);
CREATE INDEX idx_mahasiswa_angkatan     ON mahasiswa(id_angkatan);
CREATE INDEX idx_angkatan_kurikulum     ON angkatan(id_kurikulum);
CREATE INDEX idx_kurikulum_prodi        ON kurikulum(id_prodi);
CREATE INDEX idx_kurikulum_mk_kurikulum ON kurikulum_mk(id_kurikulum);
CREATE INDEX idx_kurikulum_mk_mk        ON kurikulum_mk(kode_mk);
CREATE INDEX idx_jadwal_mk              ON jadwal_kuliah(kode_mk);
CREATE INDEX idx_jadwal_dosen           ON jadwal_kuliah(id_dosen);
CREATE INDEX idx_jadwal_tahun           ON jadwal_kuliah(id_tahun_akademik);
CREATE INDEX idx_krs_nim                ON krs(nim);
CREATE INDEX idx_krs_jadwal             ON krs(id_jadwal);
CREATE INDEX idx_krs_tahun              ON krs(id_tahun_akademik);
CREATE INDEX idx_nilai_krs              ON nilai(id_krs);
CREATE INDEX idx_ringkasan_nim          ON ringkasan_ip(nim);
CREATE INDEX idx_prestasi_nim           ON prestasi_non_akademik(nim);

-- Selesai DDL (18 tabel: 16 tabel inti + kurikulum + kurikulum_mk)
