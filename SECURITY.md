# Kebijakan keamanan

## Yang dilindungi

- Profil, email, dan sesi
- Pesanan dan status pembayaran
- Catatan kepemilikan
- Percakapan pribadi
- Lokasi. Default publik adalah kota, bukan koordinat
- Claim administrator

Aplikasi klien bukan batas keamanan. Firestore Rules, Storage Rules, dan Cloud Functions harus menolak permintaan yang tidak sah walaupun antarmuka menyembunyikan tombolnya.

## Melaporkan kerentanan

Jangan membuka isu publik dan jangan menyertakan data pelanggan.

Kirim laporan ke [arthakaryadigital@gmail.com](mailto:arthakaryadigital@gmail.com) dengan:

- lokasi berkas atau alur yang terdampak
- langkah untuk memicu masalah
- dampak yang dapat diamati

Jangan menyertakan service account, keystore, atau token.

## Yang sengaja belum aktif

Firebase belum diinisialisasi. Tidak ada `google-services.json` atau `GoogleService-Info.plist` di repositori. Functions belum di-deploy, dan aturan belum diuji di emulator. Ketiadaan pengujian itu adalah batas yang diketahui, bukan pernyataan bahwa aturannya sudah terbukti.
