# Arsitektur

SincerelySea adalah aplikasi Flutter untuk Android dan iOS. State management yang dipakai adalah Provider. Riverpod dan Bloc tidak dipakai.

## Lapisan

| Lapisan | Tanggung jawab |
|---|---|
| `lib/domain` | Aturan yang tidak bergantung pada widget: kutipan harga, status pesanan, pratinjau caption, dan tingkat lokasi |
| `lib/data` | `LocalAppStore`, adaptor sementara sebelum kredensial Firebase ada |
| `lib/core` | Tema monokrom, komponen bersama, dan status konfigurasi Firebase |
| `lib/features` | Layar dan alur pelanggan |
| `lib/app` | Splash, onboarding, dan shell |
| `firebase/` | Rules dan indeks. Belum ditegakkan di proyek Firebase |
| `functions/` | Validasi server untuk pesanan dan claim admin. Belum di-deploy |

`Firebase.initializeApp` tidak dipanggil. `lib/core/firebase_gate.dart` menjelaskan bahwa opsi Firebase belum ada. Plugin Google Services tidak dipasang agar build Android tidak gagal tanpa `google-services.json`.

## Data yang dipercaya

Adaptor lokal meniru batas yang nanti ditegakkan server:

- `quoteCart` memakai harga katalog dan mengabaikan subtotal klien.
- Pesanan baru memakai `awaitingPayment`.
- `clientMayMarkOrderPaid` dan `clientMayVerifyOwnership` bernilai salah.
- Posting publik hanya menyimpan nama kota.
- `adminClaim` tidak dapat diubah dari formulir daftar.

Adaptor memori bukan batas keamanan produksi. Rules di `firebase/firestore.rules` dan `firebase/storage.rules` adalah rancangan batas itu. Rules belum diuji dengan emulator.

## Yang tidak ada

- Kunci Google Maps
- Penyedia pembayaran
- Sinkronisasi WooCommerce
- Cloud Messaging
- Transfer kepemilikan yang selesai di server

Jangan menambah integrasi itu dengan kredensial palsu atau keberhasilan palsu.
