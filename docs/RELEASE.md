# Rilis Android dan iOS

Dokumen ini menjelaskan apa yang sudah disiapkan di repositori dan apa yang masih membutuhkan kredensial pemilik proyek. File ini tidak membuat artefak toko.

## Yang belum bisa dihasilkan di mesin ini

- Tidak ada Android SDK, jadi App Bundle (`.aab`) tidak dibangun.
- Tidak ada Xcode atau sertifikat Apple, jadi archive iOS dan `.ipa` tidak dibangun.
- Jangan menganggap file tersebut ada.

## Android

Identitas aplikasi: `com.sincerelysea.sincerelysea`  
Nama yang tampil: `SincerelySea`

Signing rilis membaca `android/key.properties` jika file itu ada. Contoh ada di `android/key.properties.example`. File asli dan keystore tidak boleh di-commit.

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Salin `android/key.properties.example` menjadi `android/key.properties`, lalu isi sandi. `storeFile` relatif terhadap `android/app`.

```bash
flutter build appbundle --release
```

Tanpa `key.properties`, varian release memakai debug signing agar proyek tetap bisa dikompilasi. Itu bukan kunci unggah Play Console.

`google-services.json` belum ada dan tidak boleh di-commit. Plugin Google Services sengaja tidak dipasang agar build Android tidak gagal.

Izin yang diminta saat ini hanya `INTERNET`. Lokasi perangkat tidak diminta.

## iOS

Bundle identifier: `com.sincerelysea.sincerelysea`  
Nama yang tampil: `SincerelySea`

Build rilis membutuhkan macOS, Xcode, akun Apple Developer, dan sertifikat distribusi. Tidak ada `GoogleService-Info.plist`.

```bash
flutter build ipa --release
```

Tidak ada deskripsi izin lokasi atau kamera karena aplikasi ini belum meminta GPS atau galeri perangkat.

## Firebase

Inisialisasi Firebase tidak dipanggil. Setelah proyek Firebase dibuat:

1. Tambahkan aplikasi Android dan iOS dengan application id di atas.
2. Letakkan `google-services.json` dan `GoogleService-Info.plist` hanya di mesin build.
3. Baru kemudian panggil `Firebase.initializeApp` dengan options yang dihasilkan FlutterFire.
4. Deploy `firebase/firestore.rules`, `firebase/storage.rules`, dan `functions/` setelah rules diuji di emulator.

`functions/confirmPayment` menolak konfirmasi dari klien. Status bayar harus datang dari callback penyedia yang tanda-tangannya diverifikasi. Integrasi itu belum ada.

## Pratinjau lokal

Akun fixture hanya untuk adaptor memori: `ayu@sincerelysea.dev` / `preview-ayu`. Ini bukan kredensial produksi. Kode verifikasi `184206` dan kode reset `392817` tidak dikirim melalui email.
