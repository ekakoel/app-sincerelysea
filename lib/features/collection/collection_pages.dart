import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets.dart';
import '../../data/local_store.dart';
import '../auth/auth_pages.dart';
import '../shop/shop_pages.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final user = store.session;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const BrandWordmark(width: 150),
          const SizedBox(height: 16),
          Text('Collection', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Verified ownership comes from an eligible purchase or an authorized review. Adding a bag yourself does not verify it.',
          ),
          const SizedBox(height: 16),
          if (user == null)
            AppButton(label: 'Sign in', onPressed: () => openLogin(context))
          else ...[
            for (final record in store.verifiedCollection(user.id))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppListTile(
                  title:
                      store.catalog[record.productId]?.name ?? record.productId,
                  subtitle:
                      'Verified · ${record.source.name} · ${record.orderId ?? 'no order'}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => OwnershipPage(ownershipId: record.id),
                    ),
                  ),
                ),
              ),
            if (store.verifiedCollection(user.id).isEmpty)
              const AppEmptyState(
                title: 'No verified pieces',
                body: 'A delivered, eligible order can become part of your collection after review.',
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => runStore(
                context,
                () => store.requestSelfVerification('jane-medium'),
              ),
              child: const Text('I own this already'),
            ),
          ],
        ],
      ),
    );
  }
}

class OwnershipPage extends StatefulWidget {
  const OwnershipPage({super.key, required this.ownershipId});

  final String ownershipId;

  @override
  State<OwnershipPage> createState() => _OwnershipPageState();
}

class _OwnershipPageState extends State<OwnershipPage> {
  final _note = TextEditingController();
  final _recipient = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    _recipient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final record = store.ownership.cast<OwnershipRecord?>().firstWhere(
      (item) => item!.id == widget.ownershipId,
      orElse: () => null,
    );
    if (record == null || store.session?.id != record.ownerId) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppEmptyState(
          title: 'Private record',
          body: 'This ownership record is not yours.',
        ),
      );
    }
    final product = store.catalog[record.productId];
    final gifts = store.gifts
        .where((gift) => gift.ownershipId == record.id)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Ownership')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (product != null)
            PhotoFrame(asset: product.imageAsset, height: 200),
          const SizedBox(height: 12),
          Text(
            product?.name ?? record.productId,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text('Status · ${record.status.name}'),
          Text('Source · ${record.source.name}'),
          Text('Since · ${record.since.toIso8601String().split('T').first}'),
          if (record.orderId != null)
            AppListTile(
              title: record.orderId!,
              subtitle: 'Eligible purchase',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OrderDetailPage(orderId: record.orderId!),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Resale and gifting record interest only. They do not move ownership.',
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Listing note', controller: _note),
          const SizedBox(height: 8),
          AppButton(
            label: 'List for resale',
            onPressed: () {
              final ok = runStore(
                context,
                () => store.listForResale(record.id, _note.text),
              );
              if (ok && context.mounted) {
                showAppFeedback(
                  context,
                  'Listing opened. You are still the verified owner.',
                );
              }
            },
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Gift to username', controller: _recipient),
          const SizedBox(height: 8),
          AppButton(
            label: 'Send gift request',
            onPressed: () {
              final ok = runStore(
                context,
                () => store.requestGift(record.id, _recipient.text),
              );
              if (ok && context.mounted) {
                showAppFeedback(
                  context,
                  'Request sent. Ownership is unchanged.',
                );
              }
            },
          ),
          for (final gift in gifts) Text('${gift.id} · ${gift.status}'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => runStore(
              context,
              () => store.completeTransfer(
                gifts.isEmpty ? record.id : gifts.first.id,
              ),
            ),
            child: const Text('Complete transfer'),
          ),
        ],
      ),
    );
  }
}
