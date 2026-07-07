# Checklist Sebelum Submit

## Basis Data
- [ ] Minimal 8-12 tabel ternormalisasi 3NF (proyek ini punya 18 tabel ✅)
- [ ] Minimal 3 VIEW aktif dipakai aplikasi (proyek ini punya 5 ✅)
- [ ] Minimal 2 TRIGGER dengan logika bisnis jelas (proyek ini punya 3 ✅)
- [ ] Minimal 2 Stored Procedure/Function dipanggil dari aplikasi (proyek ini punya 2 ✅)
- [ ] Minimal 1 skenario transaksi BEGIN-COMMIT-ROLLBACK (lihat `sql/05_transaksi_demo.sql` ✅)
- [ ] Minimal 10 query kompleks terdokumentasi (proyek ini punya 12 ✅)
- [ ] INDEX pada foreign key & kolom WHERE/JOIN (lihat akhir `sql/01_ddl.sql` ✅)

## Aplikasi
- [ ] Semua fitur MVP berjalan dan terhubung ke database nyata
- [ ] Data di aplikasi dinamis (bukan hardcode)
- [ ] Login & autentikasi berjalan dengan password ter-hash (bukan plaintext)
- [ ] Laporan/dashboard menampilkan hasil query nyata

## Deployment
- [ ] Database sudah di-deploy ke cloud (Neon/Supabase/Railway)
- [ ] Aplikasi bisa diakses lewat URL publik
- [ ] Login berfungsi dari browser/perangkat lain
- [ ] Tidak ada hardcode credential di kode yang di-push ke GitHub
- [ ] Akun demo untuk setiap role tersedia dan didokumentasikan
- [ ] URL dicantumkan di README.md dan laporan

## Dokumentasi
- [ ] Laporan lengkap BAB 1-6 + lampiran (gunakan `docs/laporan_template.md`)
- [ ] ERD terlampir (export dari dbdiagram.io)
- [ ] Script SQL lengkap terlampir
- [ ] README.md di GitHub berisi cara instalasi + cara akses online
- [ ] Semua anggota tim paham struktur database untuk sesi tanya jawab presentasi

## Presentasi
- [ ] Slide presentasi (20 menit) disiapkan
- [ ] Demo aplikasi sudah dicoba end-to-end sebelum presentasi (akses URL 2-3 menit sebelum demo agar tidak "sleeping")
- [ ] Siapkan skenario demo trigger (contoh: coba ambil KRS tanpa lulus prasyarat)
