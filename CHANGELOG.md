# Changelog

Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versi aplikasi mengikuti `pubspec.yaml`.

## [Unreleased]

### Added

- Aplikasi pelanggan Flutter: splash, onboarding, feed, discover per kota, toko, koleksi, profil, dan pesan.
- Adaptor lokal untuk autentikasi, pesanan, dan kepemilikan sampai Firebase dikonfigurasi.
- Aturan Firestore, Storage, dan Cloud Functions yang belum di-deploy.
- Alur GitHub Actions untuk `flutter analyze` dan `flutter test`.

### Security

- Harga pesanan dihitung dari katalog. Klien tidak dapat menandai pesanan lunas atau memverifikasi kepemilikan sendiri.
- Lokasi publik dibatasi pada nama kota.

## [1.0.0+1] - 2026-11-04

Rilis sumber pertama. Bukan build toko.
