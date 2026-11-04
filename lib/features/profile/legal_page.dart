import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/firebase_gate.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and terms')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _LegalBlock(
            title: 'Privacy',
            paragraphs: [
              'SincerelySea is operated with Artha Karya Digital. Contact $supportEmail.',
              'This closed beta stores the account, posts, city name you type, and orders on this device. It does not send them to a server. Password text is not stored. Only a hash remains on the device.',
              'The app does not request device location, does not read your contacts, and does not collect a payment card number. A public post shows a city name, not coordinates.',
              'Delete the account in Settings. The profile, posts, comments, and messages on this device are removed. Order records can remain as a transaction history without a sign-in.',
              'The app is not directed at children. Commerce features are intended for adults.',
              'When Firebase is connected later, this notice and the store data-safety form must be updated before that build is published.',
            ],
          ),
          _LegalBlock(
            title: 'Privasi',
            paragraphs: [
              'SincerelySea dioperasikan bersama Artha Karya Digital. Kontak: $supportEmail.',
              'Beta tertutup ini menyimpan akun, unggahan, nama kota yang Anda ketik, dan pesanan di perangkat ini. Data itu belum dikirim ke server. Teks sandi tidak disimpan, hanya hash.',
              'Aplikasi tidak meminta lokasi perangkat, tidak membaca kontak, dan tidak mengumpulkan nomor kartu. Postingan publik menampilkan nama kota, bukan koordinat.',
              'Hapus akun di Settings. Profil, postingan, komentar, dan pesan di perangkat ini dihapus. Catatan pesanan dapat tetap tersimpan sebagai riwayat transaksi tanpa masuk.',
              'Aplikasi tidak ditujukan untuk anak-anak.',
            ],
          ),
          _LegalBlock(
            title: 'Terms',
            paragraphs: [
              'A pre-order in this beta is a request. The app cannot mark it paid. Payment is confirmed only by a provider callback on a server, which is not connected yet.',
              'Catalog prices are the prices that count. A total typed or changed on the device is ignored.',
              'Verified ownership comes from an eligible purchase or an authorized review. Adding a bag by hand does not verify it. A gift acceptance does not move ownership.',
              'Do not post content you do not have the right to share. Reports are stored for review.',
              'The beta is provided as available, without a promise that an order will ship until a later production release says so.',
            ],
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text('SincerelySea'),
          SizedBox(height: 8),
          Text('Version $appVersionLabel'),
          SizedBox(height: 8),
          Text(betaNotice),
          SizedBox(height: 8),
          Text(FirebaseGate.status),
          SizedBox(height: 8),
          Text('Support: $supportEmail'),
        ],
      ),
    );
  }
}

class _LegalBlock extends StatelessWidget {
  const _LegalBlock({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final paragraph in paragraphs) ...[
            Text(paragraph),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
