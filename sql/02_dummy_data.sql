-- =====================================================================
-- 02_dummy_data.sql
-- Data dummy realistis untuk demo & pengujian
-- Jalankan SETELAH 01_ddl.sql
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
