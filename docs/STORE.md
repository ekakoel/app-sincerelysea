# Rilis November 2026

Dokumen ini adalah urutan kerja menuju pengujian pengguna, lalu Play Store dan App Store. Mesin pengembangan ini tidak memiliki Android SDK dan Xcode, jadi berkas `.aab` dan `.ipa` tidak dibuat di sini. Jangan mengunggah build yang belum ditandatangani dengan kunci Anda.

Kontak dukungan yang tertulis di aplikasi: `arthakaryadigital@gmail.com`.

Kebijakan yang dapat dipakai sebagai URL publik setelah commit ini ada di GitHub:

- https://github.com/ekakoel/app-sincerelysea/blob/main/docs/PRIVACY_POLICY.md
- https://github.com/ekakoel/app-sincerelysea/blob/main/docs/TERMS.md

Untuk produksi, salin teks yang sama ke halaman di sincerelysea.com. URL situs merek lebih kuat daripada URL GitHub.

## Yang sudah ada di build ini

- Akun, pesanan, dan unggahan tersimpan di perangkat. Menutup aplikasi tidak menghapusnya.
- Hapus akun ada di Settings. Profil, postingan, komentar, dan pesan perangkat dihapus. Catatan pesanan tetap sebagai riwayat transaksi.
- Privasi, syarat, dan tentang ada di profil, termasuk sebelum masuk.
- Izin Android hanya `INTERNET`. Lokasi perangkat tidak diminta.
- Cadangan awan Android tidak menyalin preferensi yang berisi hash sandi.
- iOS memakai privacy manifest dan `ITSAppUsesNonExemptEncryption` = false.
- Pesanan baru tetap `awaitingPayment`. Aplikasi tidak bisa menandai lunas.
- Beta ini belum menghubungkan satu ponsel dengan ponsel lain.

## Yang harus diselesaikan pemilik akun

Tanpa empat akun ini, aplikasi tidak bisa masuk toko dan tidak bisa dipakai bersama beberapa pengguna:

1. Firebase
2. Google Play Console
3. Apple Developer Program
4. Kunci unggah Android yang disimpan di luar git

### 1. Firebase, supaya beberapa pengguna melihat data yang sama

1. Buat proyek di [Firebase console](https://console.firebase.google.com/) atas nama merek.
2. Tambah aplikasi Android `com.sincerelysea.sincerelysea` dan aplikasi iOS dengan bundle yang sama.
3. Unduh `google-services.json` dan `GoogleService-Info.plist`. Simpan di mesin build. Jangan commit.
4. Aktifkan Authentication: Email/Password dulu. Google dan Facebook menyusul setelah kredensial OAuth ada.
5. Buat Firestore dan Storage.
6. Pasang Firebase CLI, lalu deploy aturan yang sudah ada:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

7. Deploy `functions/` hanya setelah `npm install` di folder itu dan pengujian emulator lulus. Jangan menganggap deploy ini sudah dilakukan.
8. Setelah berkas konfigurasi ada, sambungkan `Firebase.initializeApp` dengan opsi yang dihasilkan FlutterFire. Jangan mengarang API key.

Sampai langkah ini selesai, setiap ponsel hanya melihat datanya sendiri.

### 2. Google Play, pengujian internal dulu

1. Daftar [Play Console](https://play.google.com/console) dan bayar pendaftaran jika belum.
2. Buat aplikasi. Nama: SincerelySea. Bahasa default: Indonesia. Aplikasi, bukan game. Gratis.
3. Di komputer yang punya Android SDK dan Flutter, buat kunci sekali:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Simpan keystore dan sandinya di luar repositori. Salin `android/key.properties.example` menjadi `android/key.properties`.

4. Bangun:

```bash
flutter build appbundle --release
```

Berkas ada di `build/app/outputs/bundle/release/app-release.aab`.

5. Play App Signing: biarkan Google mengelola kunci aplikasi. Unggah AAB ke jalur Internal testing.
6. Isi listing, kebijakan privasi, iklan (tidak ada), audiens (bukan anak-anak), dan kuesioner rating.
7. Isi Data safety sesuai tabel di bawah. Jangan mencentang lokasi presisi atau data finansial kartu.
8. Tambah penguji internal lewat email. Mereka memasang dari Play, bukan dari berkas yang diteruskan di chat.
9. Setelah beberapa pengguna internal tidak menemukan cacat pemblokir, pindah ke closed testing, lalu production. Production membutuhkan peninjauan Google.

### 3. App Store, TestFlight dulu

1. Daftar [Apple Developer Program](https://developer.apple.com/programs/). Organisasi membutuhkan nomor D-U-N-S.
2. Di Mac dengan Xcode, buka `ios/Runner.xcworkspace`.
3. Bundle ID `com.sincerelysea.sincerelysea`. Tim penandatangan adalah akun developer. Sertifikat distribusi dibuat oleh Xcode.
4. Archive, lalu unggah ke App Store Connect. Atau:

```bash
flutter build ipa --release
```

5. Di App Store Connect, buat aplikasi SincerelySea.
6. Privacy Nutrition Labels sesuai tabel di bawah. Tracking: tidak.
7. Enkripsi: Info.plist sudah menyatakan tidak memakai enkripsi yang dikecualikan. Jawaban ekspor di Connect mengikuti itu.
8. Undang penguji internal TestFlight. Mereka harus memakai build yang sama dengan kebijakan di atas.
9. Setelah catatan peninjau dan tangkapan layar lengkap, kirim untuk review. Review Apple sering menolak aplikasi yang membuat akun tetapi tidak bisa menghapusnya. Penghapusan akun sudah ada di Settings.

## Jawaban Data safety untuk build beta ini

Gunakan jawaban ini hanya untuk build yang masih menyimpan data di perangkat dan belum mengirimnya ke Firebase. Setelah Firebase dipasang, formulir wajib diubah.

| Pertanyaan | Jawaban |
|---|---|
| Apakah data dikumpulkan dari perangkat? | Ya, disimpan di perangkat. Tidak dikirim ke server pada build ini. |
| Apakah data dibagikan ke pihak ketiga? | Tidak. |
| Apakah dipakai untuk iklan atau pelacakan? | Tidak. |
| Data yang ada | Nama, email, ID pengguna, foto yang dipilih pengguna, isi postingan, kota yang diketik, riwayat pesanan. |
| Data yang tidak ada | Lokasi presisi, kontak, nomor kartu, kata sandi mentah. |
| Pengguna dapat meminta hapus akun? | Ya, di dalam aplikasi. |
| Enkripsi saat transit | Tidak relevan pada build ini karena tidak ada pengiriman. Wajib diubah saat Firebase memakai HTTPS. |

## Privacy Nutrition Labels

Tracking: tidak.

Data yang terhubung ke identitas, untuk fungsi aplikasi, tidak untuk pelacakan:

- Email
- Nama
- ID pengguna
- Foto atau video yang dipilih pengguna
- Konten lain, termasuk caption dan nama kota
- Riwayat pembelian

## Listing

Nama: SincerelySea

Subjudul: Stories in every stitch

Ringkasan: Komunitas dan pre-order tas kulit sapi SincerelySea. Bagikan cerita, simpan koleksi yang terverifikasi, dan ajukan pre-order. Pembayaran belum diselesaikan di dalam aplikasi.

Tangkapan layar yang disiapkan: splash, onboarding, home, detail produk, keranjang dengan status menunggu pembayaran, koleksi, dan profil. Jangan menampilkan data pelanggan sungguhan.

Kategori: Belanja, atau Gaya Hidup jika Play meminta satu kategori utama. Usia: 18+.

## Urutan bulan ini

1. Akun Play Console dan Apple Developer dibuka.
2. Firebase dibuat dan aturan di-deploy. Berkas konfigurasi tidak di-commit.
3. Build internal dipasang ke 5–10 pengguna.
4. Cacat dari pengguna itu diperbaiki.
5. Listing, kebijakan, dan tangkapan layar dilengkapi.
6. Closed testing, lalu pengajuan production hanya jika pembayaran dan Firebase sudah jujur terhadap formulir tokonya.

Jangan mengajukan production selama pesanan masih tidak bisa dibayar dan data masih hanya ada di satu perangkat, kecuali listing dengan tegas menyebut beta tertutup dan toko mengizinkan aplikasi itu. Untuk pengguna sungguhan yang harus melihat unggahan yang sama, Firebase pada langkah 1 adalah syarat, bukan pilihan.
