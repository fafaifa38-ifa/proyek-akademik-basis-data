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

-- =====================================================================
-- 02_dummy_data.sql
-- Data dummy realistis untuk demo & pengujian
-- =====================================================================

-- 1. program_studi
INSERT INTO program_studi (kode_prodi, nama_prodi, jenjang, akreditasi) VALUES
('SI', 'Sistem Informasi', 'S1', 'B'),
('TI', 'Teknik Informatika', 'S1', 'A');

-- 2. kurikulum
-- id 1 = Kurikulum 2022 (SI, dipakai angkatan 2022), id 2 = Kurikulum 2023
-- (SI, dipakai angkatan 2023 & 2024, masih aktif)
INSERT INTO kurikulum (id_prodi, nama_kurikulum, tahun_berlaku, is_aktif) VALUES
(1, 'Kurikulum 2022', 2022, false),
(1, 'Kurikulum 2023', 2023, true);

-- 3. angkatan (angkatan 2022 pakai Kurikulum 2022 (id=1),
--    angkatan 2023 & 2024 pakai Kurikulum 2023 (id=2) yang masih aktif)
INSERT INTO angkatan (tahun_masuk, id_kurikulum) VALUES
(2022, 1), (2023, 2), (2024, 2);

-- 3. tahun_akademik
INSERT INTO tahun_akademik (tahun_ajaran, semester, is_aktif) VALUES
('2023/2024', 'Ganjil', false),
('2023/2024', 'Genap', false),
('2024/2025', 'Ganjil', true);

-- 4. dosen
INSERT INTO dosen (nidn, nama, id_prodi, email, no_hp) VALUES
('0001057001', 'Dr. Ahmad Fauzi, S.Kom., M.T.', 1, 'ahmad.fauzi@umj.ac.id', '081234500001'),
('0002057002', 'Siti Nurhaliza, S.T., M.Kom.', 1, 'siti.nurhaliza@umj.ac.id', '081234500002'),
('0003057003', 'Budi Santoso, S.Kom., M.Cs.', 2, 'budi.santoso@umj.ac.id', '081234500003'),
('0004057004', 'Rina Wijayanti, S.Kom., M.T.', 2, 'rina.wijayanti@umj.ac.id', '081234500004'),
('0005057005', 'Eko Prasetyo, S.T., M.Eng.', 1, 'eko.prasetyo@umj.ac.id', '081234500005');

-- 5. mata_kuliah (dengan rantai prasyarat)
INSERT INTO mata_kuliah (kode_mk, nama_mk, sks, id_prodi, semester_ke) VALUES
('SI101', 'Algoritma & Pemrograman Dasar', 3, 1, 1),
('SI102', 'Pengantar Basis Data', 3, 1, 1),
('SI201', 'Struktur Data', 3, 1, 2),
('SI202', 'Basis Data Lanjut', 3, 1, 2),
('SI301', 'Pemrograman Web', 3, 1, 3),
('SI302', 'Rekayasa Perangkat Lunak', 3, 1, 3),
('SI401', 'Analisis & Perancangan Sistem Informasi', 3, 1, 4),
('SI402', 'Data Warehouse & Business Intelligence', 3, 1, 4),
('MK901', 'Statistika', 2, 1, 1),
('MK902', 'Bahasa Inggris', 2, 1, 1);

INSERT INTO prasyarat_mk (kode_mk, kode_mk_prasyarat) VALUES
('SI201', 'SI101'),
('SI202', 'SI102'),
('SI301', 'SI201'),
('SI401', 'SI301'),
('SI401', 'SI202'),
('SI402', 'SI202');

-- 5b. kurikulum_mk (struktur kurikulum per semester)
-- Kurikulum 2022 (id_kurikulum=1) -- dipakai angkatan 2022
INSERT INTO kurikulum_mk (id_kurikulum, kode_mk, semester_ke, sifat) VALUES
(1, 'SI101', 1, 'Wajib'),
(1, 'SI102', 1, 'Wajib'),
(1, 'MK901', 1, 'Wajib'),
(1, 'MK902', 1, 'Wajib'),
(1, 'SI201', 2, 'Wajib'),
(1, 'SI202', 2, 'Wajib'),
(1, 'SI301', 3, 'Wajib'),
(1, 'SI302', 3, 'Wajib'),
(1, 'SI401', 4, 'Wajib'),
(1, 'SI402', 4, 'Pilihan');

-- Kurikulum 2023 (id_kurikulum=2) -- dipakai angkatan 2023 & 2024
-- (sedikit berbeda: SI402 dipindah jadi wajib, MK902 dipindah ke semester 2)
INSERT INTO kurikulum_mk (id_kurikulum, kode_mk, semester_ke, sifat) VALUES
(2, 'SI101', 1, 'Wajib'),
(2, 'SI102', 1, 'Wajib'),
(2, 'MK901', 1, 'Wajib'),
(2, 'SI201', 2, 'Wajib'),
(2, 'SI202', 2, 'Wajib'),
(2, 'MK902', 2, 'Wajib'),
(2, 'SI301', 3, 'Wajib'),
(2, 'SI302', 3, 'Wajib'),
(2, 'SI401', 4, 'Wajib'),
(2, 'SI402', 4, 'Wajib');

-- 6. ruang_kelas
INSERT INTO ruang_kelas (nama_ruang, gedung, kapasitas) VALUES
('R101', 'Gedung A', 40),
('R102', 'Gedung A', 40),
('LAB1', 'Gedung B', 30);

-- 7. mahasiswa (20 mahasiswa lintas angkatan)
INSERT INTO mahasiswa (nim, nama, id_prodi, id_angkatan, jenis_kelamin, tanggal_lahir, alamat, email, no_hp, status_mahasiswa) VALUES
('2022210001', 'Andi Saputra', 1, 1, 'L', '2004-03-11', 'Jl. Mawar No. 1, Jember', 'andi.saputra@student.umj.ac.id', '082210000001', 'Aktif'),
('2022210002', 'Bunga Lestari', 1, 1, 'P', '2004-05-22', 'Jl. Melati No. 2, Jember', 'bunga.lestari@student.umj.ac.id', '082210000002', 'Aktif'),
('2022210003', 'Candra Wibowo', 1, 1, 'L', '2004-01-15', 'Jl. Kenanga No. 3, Jember', 'candra.wibowo@student.umj.ac.id', '082210000003', 'Aktif'),
('2022210004', 'Dewi Anggraini', 1, 1, 'P', '2004-07-09', 'Jl. Anggrek No. 4, Jember', 'dewi.anggraini@student.umj.ac.id', '082210000004', 'Aktif'),
('2022210005', 'Eka Ramadhan', 1, 1, 'L', '2004-09-30', 'Jl. Dahlia No. 5, Jember', 'eka.ramadhan@student.umj.ac.id', '082210000005', 'Aktif'),
('2023210006', 'Fitriani Rahma', 1, 2, 'P', '2005-02-18', 'Jl. Flamboyan No. 6, Jember', 'fitriani.rahma@student.umj.ac.id', '082210000006', 'Aktif'),
('2023210007', 'Galih Pratama', 1, 2, 'L', '2005-04-25', 'Jl. Cempaka No. 7, Jember', 'galih.pratama@student.umj.ac.id', '082210000007', 'Aktif'),
('2023210008', 'Hana Salsabila', 1, 2, 'P', '2005-06-12', 'Jl. Teratai No. 8, Jember', 'hana.salsabila@student.umj.ac.id', '082210000008', 'Aktif'),
('2023210009', 'Irfan Maulana', 1, 2, 'L', '2005-08-03', 'Jl. Seroja No. 9, Jember', 'irfan.maulana@student.umj.ac.id', '082210000009', 'Aktif'),
('2023210010', 'Jasmine Putri', 1, 2, 'P', '2005-10-19', 'Jl. Bougenville No. 10, Jember', 'jasmine.putri@student.umj.ac.id', '082210000010', 'Aktif'),
('2024210011', 'Krisna Aditya', 1, 3, 'L', '2006-01-07', 'Jl. Kamboja No. 11, Jember', 'krisna.aditya@student.umj.ac.id', '082210000011', 'Aktif'),
('2024210012', 'Larasati Dewi', 1, 3, 'P', '2006-03-14', 'Jl. Sakura No. 12, Jember', 'larasati.dewi@student.umj.ac.id', '082210000012', 'Aktif'),
('2024210013', 'Muhammad Rizki', 1, 3, 'L', '2006-05-21', 'Jl. Tulip No. 13, Jember', 'muhammad.rizki@student.umj.ac.id', '082210000013', 'Aktif'),
('2024210014', 'Nadia Safitri', 1, 3, 'P', '2006-07-28', 'Jl. Lily No. 14, Jember', 'nadia.safitri@student.umj.ac.id', '082210000014', 'Aktif'),
('2024210015', 'Oscar Firmansyah', 1, 3, 'L', '2006-09-04', 'Jl. Aster No. 15, Jember', 'oscar.firmansyah@student.umj.ac.id', '082210000015', 'Aktif'),
('2022210016', 'Putri Ayu', 2, 1, 'P', '2004-02-17', 'Jl. Kenari No. 16, Jember', 'putri.ayu@student.umj.ac.id', '082210000016', 'Aktif'),
('2022210017', 'Qori Hidayat', 2, 1, 'L', '2004-04-23', 'Jl. Cendana No. 17, Jember', 'qori.hidayat@student.umj.ac.id', '082210000017', 'Aktif'),
('2023210018', 'Ratna Sari', 2, 2, 'P', '2005-06-29', 'Jl. Beringin No. 18, Jember', 'ratna.sari@student.umj.ac.id', '082210000018', 'Aktif'),
('2023210019', 'Surya Nugraha', 2, 2, 'L', '2005-08-05', 'Jl. Waru No. 19, Jember', 'surya.nugraha@student.umj.ac.id', '082210000019', 'Aktif'),
('2024210020', 'Tania Maharani', 2, 3, 'P', '2006-10-11', 'Jl. Trembesi No. 20, Jember', 'tania.maharani@student.umj.ac.id', '082210000020', 'Aktif');

-- 8. jadwal_kuliah (semester aktif: id_tahun_akademik = 3, 2024/2025 Ganjil)
INSERT INTO jadwal_kuliah (kode_mk, id_dosen, id_ruang, id_tahun_akademik, kelas, hari, jam_mulai, jam_selesai, kuota) VALUES
('SI101', 1, 1, 3, 'A', 'Senin', '08:00', '10:30', 40),
('SI102', 2, 2, 3, 'A', 'Senin', '10:30', '13:00', 40),
('SI201', 1, 1, 3, 'A', 'Selasa', '08:00', '10:30', 40),
('SI202', 2, 3, 3, 'A', 'Selasa', '10:30', '13:00', 40),
('SI301', 3, 3, 3, 'A', 'Rabu', '08:00', '10:30', 35),
('SI401', 4, 1, 3, 'A', 'Kamis', '08:00', '10:30', 35),
('MK901', 5, 2, 3, 'A', 'Jumat', '08:00', '09:40', 40),
-- jadwal semester lalu untuk histori nilai (2023/2024 Ganjil, id=1 & Genap id=2)
('SI101', 1, 1, 1, 'A', 'Senin', '08:00', '10:30', 40),
('SI102', 2, 2, 1, 'A', 'Senin', '10:30', '13:00', 40),
('MK901', 5, 2, 1, 'A', 'Jumat', '08:00', '09:40', 40),
('SI201', 1, 1, 2, 'A', 'Selasa', '08:00', '10:30', 40),
('SI202', 2, 3, 2, 'A', 'Selasa', '10:30', '13:00', 40);

-- 9. KRS semester lalu (2023/2024 Ganjil = id 1) untuk angkatan 2022 & 2023
INSERT INTO krs (nim, id_jadwal, id_tahun_akademik) VALUES
('2022210001', 8, 1), ('2022210001', 9, 1), ('2022210001', 10, 1),
('2022210002', 8, 1), ('2022210002', 9, 1), ('2022210002', 10, 1),
('2022210003', 8, 1), ('2022210003', 9, 1), ('2022210003', 10, 1),
('2023210006', 8, 1), ('2023210006', 9, 1), ('2023210006', 10, 1),
('2023210007', 8, 1), ('2023210007', 9, 1), ('2023210007', 10, 1);

-- 10. KRS semester genap 2023/2024 (id 2) - lanjutan SI201, SI202 (prasyaratnya sudah lulus)
INSERT INTO krs (nim, id_jadwal, id_tahun_akademik) VALUES
('2022210001', 11, 2), ('2022210001', 12, 2),
('2022210002', 11, 2), ('2022210002', 12, 2),
('2023210006', 11, 2), ('2023210006', 12, 2);

-- 11. nilai untuk KRS di atas (nilai_huruf & bobot akan dihitung otomatis oleh TRIGGER,
--     jadi cukup isi nilai_angka saja)
INSERT INTO nilai (id_krs, nilai_angka) VALUES
(1, 85), (2, 78), (3, 90),
(4, 72), (5, 88), (6, 95),
(7, 65), (8, 70), (9, 80),
(10, 92), (11, 84), (12, 77),
(13, 55), (14, 60), (15, 68),
(16, 81), (17, 89),
(18, 74), (19, 79),
(20, 91), (21, 86);

-- 12. KRS semester aktif (2024/2025 Ganjil = id 3) -- ini yang akan dipakai untuk
--     demo fitur "ambil KRS" & "input nilai" dari aplikasi (nilai sengaja masih kosong)
INSERT INTO krs (nim, id_jadwal, id_tahun_akademik) VALUES
('2024210011', 1, 3), ('2024210011', 2, 3), ('2024210011', 7, 3),
('2024210012', 1, 3), ('2024210012', 2, 3), ('2024210012', 7, 3),
('2024210013', 1, 3), ('2024210013', 2, 3),
('2022210003', 3, 3), ('2022210003', 4, 3),   -- ambil SI201 & SI202 (prasyarat sudah lulus)
('2023210007', 3, 3);                          -- ambil SI201 (prasyarat sudah lulus)

-- 13. beasiswa
INSERT INTO beasiswa (nama_beasiswa, sumber, nominal) VALUES
('Beasiswa PPA', 'Kemendikbud', 2400000),
('Beasiswa KIP-Kuliah', 'Pemerintah', 4200000),
('Beasiswa Prestasi Kampus', 'Universitas Muhammadiyah Jember', 1500000);

INSERT INTO penerima_beasiswa (nim, id_beasiswa, id_tahun_akademik, status) VALUES
('2022210001', 1, 3, 'Aktif'),
('2023210006', 2, 3, 'Aktif'),
('2022210002', 3, 3, 'Aktif');

-- 14. prestasi non akademik
INSERT INTO prestasi_non_akademik (nim, nama_prestasi, tingkat, tahun, keterangan) VALUES
('2022210001', 'Juara 2 Lomba Basis Data Nasional', 'Nasional', 2024, 'Diselenggarakan oleh ISDS'),
('2023210006', 'Juara 1 Futsal Antar Kampus', 'Lokal', 2024, 'Turnamen Rektor Cup'),
('2022210002', 'Finalis Hackathon BUMN', 'Nasional', 2023, 'Kategori Fintech');

-- 15. users (password contoh sudah di-hash bcrypt untuk kata sandi: "password123")
-- NOTE: hash di bawah adalah CONTOH, akan digenerate ulang otomatis oleh app/seed_users.py
INSERT INTO users (username, password_hash, role, nim, id_dosen) VALUES
('admin', 'to_be_generated', 'admin', NULL, NULL),
('kaprodi', 'to_be_generated', 'kaprodi', NULL, NULL),
('dosen.ahmad', 'to_be_generated', 'dosen', NULL, 1),
('dosen.siti', 'to_be_generated', 'dosen', NULL, 2),
('2024210011', 'to_be_generated', 'mahasiswa', '2024210011', NULL),
('2022210003', 'to_be_generated', 'mahasiswa', '2022210003', NULL);

-- Selesai data dummy.
-- PENTING: jalankan app/seed_users.py setelah ini untuk mengisi password_hash yang valid
-- (lihat README.md bagian "Setup Awal").

-- =====================================================================
-- 03_views.sql
-- minimal ada 3 view
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

ROLLBACK;

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

SELECT * FROM ringkasan_ip;

