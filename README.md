# SincerelySea

Aplikasi komunitas dan pre-order untuk tas kulit sapi SincerelySea. Android dan iOS memakai Flutter. Ini bukan jejaring sosial generik dan bukan toko biasa.

[![CI](https://github.com/ekakoel/app-sincerelysea/actions/workflows/ci.yml/badge.svg)](https://github.com/ekakoel/app-sincerelysea/actions/workflows/ci.yml)

| | |
|---|---|
| Produk | Komunitas, koleksi, dan pre-order |
| Platform | Android dan iOS |
| Kode | Flutter, Dart, Provider |
| Backend yang direncanakan | Firebase Authentication, Firestore, Storage, Cloud Functions |
| Desain | [Figma](https://www.figma.com/design/op6iQBv7uUCAWJIHoUKrJA) |
| Situs merek | [sincerelysea.com](https://sincerelysea.com) |

## Status

Aplikasi klien sudah bisa dijalankan. Firebase, pembayaran, dan build toko belum selesai. Jangan menganggap fitur di bawah ini sudah produksi.

| Area | Status |
|---|---|
| Splash, onboarding, lima tab | Ada di klien |
| Masuk dengan email pada adaptor lokal | Ada. Google dan Facebook belum |
| Feed, suka, simpan, komentar, laporkan | Ada di memori perangkat |
| Discover per kota | Ada. Peta dan GPS tidak dipakai |
| Katalog, keranjang, checkout | Ada. Pesanan baru selalu menunggu pembayaran |
| Koleksi terverifikasi | Ada sebagai fondasi. Transfer pemilik belum |
| Pesan antar anggota | Ada di memori, hanya untuk peserta |
| Aturan Firestore dan Storage | Tertulis, belum diuji di emulator |
| Cloud Functions | Tertulis, belum di-deploy |
| Akun tersimpan di perangkat | Ada. Belum tersinkron antarponsel |
| Kebijakan privasi, syarat, hapus akun | Ada. Lihat [docs/STORE.md](docs/STORE.md) |
| App Bundle dan IPA | Belum dibuat |

## Persyaratan

- Flutter stable `3.47.9` atau yang lebih baru pada channel yang sama, dengan Dart `3.13.7` atau lebih baru
- Android Studio atau Xcode hanya diperlukan saat membangun ke perangkat atau toko

## Mulai

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Pratinjau browser memakai kode Flutter yang sama, bukan aplikasi web terpisah:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Akun pratinjau hanya ada di adaptor lokal: `ayu@sincerelysea.dev` / `preview-ayu`. Sandi itu bukan kredensial produksi.

## Struktur

```text
lib/domain        Aturan harga, status pesanan, dan privasi lokasi
lib/data          Adaptor lokal sampai Firebase dikonfigurasi
lib/core          Tema, komponen, dan gerbang Firebase
lib/features      Layar pelanggan
lib/app           Splash, onboarding, dan navigasi
firebase/         Aturan Firestore, Storage, dan indeks
functions/        Cloud Functions. Belum di-deploy
android/ ios/     Proyek platform
docs/             Arsitektur dan rilis
```

Detail ada di [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Aturan yang tidak boleh dilanggar klien

- Harga dihitung dari katalog. Total yang dikirim aplikasi diabaikan.
- Pesanan baru tidak pernah ditandai lunas dari perangkat.
- Kepemilikan terverifikasi hanya dari pembelian yang memenuhi syarat atau tinjauan yang berwenang.
- Lokasi publik paling detail pada tingkat kota. Koordinat tidak disimpan.
- Peran administrator tidak bisa dipilih saat daftar. Claim hanya lewat fungsi server.
- Jangan commit `google-services.json`, `GoogleService-Info.plist`, service account, `.env`, atau keystore.

## Rilis

Langkah Android dan iOS ada di [docs/RELEASE.md](docs/RELEASE.md). Mesin tanpa Android SDK dan Xcode tidak menghasilkan berkas toko.

## Kontribusi

Baca [CONTRIBUTING.md](CONTRIBUTING.md) sebelum membuka pull request. Kerentanan dilaporkan lewat [SECURITY.md](SECURITY.md), bukan isu publik.

## Lisensi

Sumber ini proprietary. Lihat [LICENSE](LICENSE). Tidak ada izin penggunaan di luar perjanjian tertulis.
