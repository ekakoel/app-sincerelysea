# SincerelySea

Aplikasi komunitas dan pre-order untuk tas kulit sapi SincerelySea. Android dan iOS memakai Flutter. Bukan jejaring sosial generik dan bukan toko biasa.

| | |
|---|---|
| Platform | Android dan iOS |
| Stack | Flutter, Provider, adaptor lokal sampai Firebase dikonfigurasi |
| Repositori | https://github.com/ekakoel/app-sincerelysea |
| Desain | https://www.figma.com/design/op6iQBv7uUCAWJIHoUKrJA |

## Menjalankan

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Pratinjau web dari kode Flutter yang sama, bukan aplikasi web terpisah:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

## Yang sudah ada di kode

- Splash, onboarding tiga langkah, dan lima tab: Home, Discover, Shop, Collection, Profile.
- Masuk, daftar, reset sandi, dan verifikasi email pada adaptor lokal. Google dan Facebook tidak diselesaikan karena Firebase belum dikonfigurasi.
- Feed dengan caption paling banyak 15 karakter, jumlah like, save, dan share.
- Discover berdasarkan kota. Koordinat dan lokasi perangkat tidak dipakai.
- Katalog, keranjang, dan checkout. Pesanan baru selalu `awaitingPayment`. Total dari klien diabaikan.
- Koleksi hanya untuk kepemilikan terverifikasi. Klaim manual ditolak. Resale dan hadiah tidak memindahkan pemilik.
- Pesan hanya untuk peserta. Admin tidak bisa diberikan dari aplikasi.

## Yang belum

- Proyek Firebase, `google-services.json`, dan `GoogleService-Info.plist`.
- Cloud Functions belum di-deploy dan belum diuji di emulator. Aturan Firestore dan Storage ada di `firebase/`, tetapi belum dijalankan.
- Tidak ada kunci Google Maps, penyedia pembayaran, atau sinkronisasi WooCommerce.
- Foto katalog adalah foto stok, bukan foto produk resmi.
- Harga Satchel `Rp 1.750.000` adalah harga katalog pada adaptor lokal. Desain awal hanya menandai Satchel sebagai pre-order tanpa harga.
- App Bundle dan IPA belum dibuat. Lihat [docs/RELEASE.md](docs/RELEASE.md).

## Commit

Setiap perubahan kode aplikasi di-commit ke repositori ini.

- Branch default: `main`
- Jangan force-push ke `main`
- Jangan commit rahasia: service account, keystore, `.env`, `google-services.json`, `GoogleService-Info.plist`
