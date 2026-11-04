import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/firebase_gate.dart';
import '../../core/widgets.dart';
import '../../data/local_store.dart';
import '../../domain/policies.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final admin = store.session?.adminClaim == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!admin) ...[
            const AppEmptyState(
              title: 'Restricted',
              body:
                  'Administrator access is a Firebase Authentication custom claim. This app cannot grant it, and a role field on your profile is ignored.',
            ),
            const SizedBox(height: 12),
            Text(FirebaseGate.status, style: Theme.of(context).textTheme.bodySmall),
          ] else ...[
            Text('Reports ${store.reports.length}', style: Theme.of(context).textTheme.titleMedium),
            Text('Orders ${store.orders.length}'),
            for (final report in store.reports)
              AppListTile(title: report.targetType, subtitle: report.reason),
            const SizedBox(height: 12),
            for (final post in store.posts)
              AppListTile(
                title: post.id,
                subtitle: 'Remove',
                onTap: () => runStore(context, () => store.moderateRemovePost(post.id)),
              ),
          ],
          const SizedBox(height: 16),
          const AppSection(
            title: 'Modules',
            child: Text(
              'Product, order, moderation, ownership review, and resale tools stay closed until a trusted claim is present. Payment status is never edited from this screen.',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => runStore(context, () => store.moderateRemovePost('post-mira')),
            child: const Text('Try to moderate'),
          ),
        ],
      ),
    );
  }
}

class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final user = store.session;
    final saved = user == null
        ? const <CommunityPost>[]
        : store.posts.where((post) => store.savedBy(user.id, post.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved posts')),
      body: saved.isEmpty
          ? const AppEmptyState(title: 'Nothing saved', body: 'Saved stories stay separate from your wishlist and collection.')
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final post in saved) Text(captionPreview(post.caption)),
              ],
            ),
    );
  }
}

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final user = store.session;
    final ids = user == null
        ? const <String>[]
        : store.wishlist.where((key) => key.startsWith('${user.id}|')).map((key) => key.split('|').last).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: ids.isEmpty
          ? const AppEmptyState(title: 'Wishlist is empty', body: 'Saved products are not ownership records.')
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final id in ids)
                  AppListTile(
                    title: store.catalog[id]?.name ?? id,
                    subtitle: store.catalog[id] == null ? null : formatIdr(store.catalog[id]!.priceIdr),
                  ),
              ],
            ),
    );
  }
}
