# Kontribusi

Repositori ini adalah sumber kode aplikasi SincerelySea. Perubahan kecil dan terfokus lebih mudah ditinjau daripada penulisan ulang.

## Sebelum mengubah kode

1. Baca [README.md](README.md) dan [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
2. Jangan mengganti Provider, Firebase, atau struktur folder tanpa alasan yang tertulis di pull request.
3. Jangan melemahkan aturan di `firebase/` agar tes lolos.
4. Jangan menandai pesanan lunas, mengubah harga, atau memverifikasi kepemilikan dari data yang dikirim klien.

## Pemeriksaan

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Alur yang sama berjalan di GitHub Actions pada pull request ke `main`.

## Commit

- Bahasa Inggris, kalimat lengkap, menjelaskan perubahannya.
- Jangan force-push ke `main`.
- Jangan commit rahasia: service account, keystore, `.env`, `google-services.json`, `GoogleService-Info.plist`, atau `android/key.properties`.

## Pull request

Jelaskan perilaku yang berubah, pengujian yang dijalankan, dan dampak ke otorisasi. Jika pengujian tidak dijalankan, tulis itu dengan jelas.
