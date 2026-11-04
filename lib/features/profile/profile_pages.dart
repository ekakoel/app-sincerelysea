import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';
import '../../data/local_store.dart';
import '../../domain/policies.dart';
import '../admin/admin_page.dart';
import '../auth/auth_pages.dart';
import '../feed/feed_pages.dart';
import '../messages/message_pages.dart';
import '../shop/shop_pages.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final user = store.session;
    if (user == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandWordmark(width: 160),
              const Spacer(),
              Text(
                'Your profile',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('Sign in to post, order, and keep a collection.'),
              const SizedBox(height: 16),
              AppButton(
                key: const Key('sign-in-cta'),
                label: 'Sign in',
                onPressed: () => openLogin(context),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const RegisterPage()),
                ),
                child: const Text('Create an account'),
              ),
              const Spacer(),
            ],
          ),
        ),
      );
    }
    final posts = store.posts.where((post) => post.authorId == user.id).length;
    final owned = store.verifiedCollection(user.id).length;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const BrandWordmark(width: 150),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: user.avatarAsset == null
                    ? null
                    : AssetImage(user.avatarAsset!),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text('@${user.username} · ${user.city}'),
                  ],
                ),
              ),
            ],
          ),
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(user.bio),
          ],
          const SizedBox(height: 8),
          Text(
            '$posts stories · $owned verified · joined ${user.joinedAt.year}',
          ),
          if (!user.emailVerified) ...[
            const SizedBox(height: 8),
            const Text('Email is not verified.'),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const VerifyEmailPage(),
                ),
              ),
              child: const Text('Enter verification code'),
            ),
          ],
          const Divider(),
          AppListTile(
            title: 'Edit profile',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const EditProfilePage()),
            ),
          ),
          AppListTile(
            title: 'Saved posts',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SavedPostsPage()),
            ),
          ),
          AppListTile(
            title: 'Wishlist',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const WishlistPage()),
            ),
          ),
          AppListTile(
            title: 'Orders',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const OrdersPage())),
          ),
          AppListTile(title: 'Messages', onTap: () => openMessages(context)),
          AppListTile(
            title: 'Notifications',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const NotificationPage()),
            ),
          ),
          AppListTile(
            title: 'Settings',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
          ),
          AppListTile(
            title: 'Administration',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const AdminPage())),
          ),
          const SizedBox(height: 8),
          Text(
            'Loyalty balance ${store.loyaltyBalance(user.id)}. Redemption rules are not defined.',
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => runStore(context, () => store.redeemPoints(10)),
            child: const Text('Redeem points'),
          ),
          const SizedBox(height: 16),
          Text('Gift requests', style: Theme.of(context).textTheme.titleMedium),
          for (final gift in store.gifts.where(
            (gift) => gift.toUserId == user.id,
          ))
            AppListTile(
              title: gift.id,
              subtitle: gift.status,
              onTap: gift.status == 'pending'
                  ? () {
                      final ok = runStore(
                        context,
                        () => store.acceptGift(gift.id),
                      );
                      if (ok && context.mounted) {
                        showAppFeedback(
                          context,
                          'Accepted for server review. Ownership did not move.',
                        );
                      }
                    }
                  : null,
            ),
        ],
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  late String _city;

  @override
  void initState() {
    super.initState();
    final user = context.read<LocalAppStore>().session!;
    _name = TextEditingController(text: user.displayName);
    _username = TextEditingController(text: user.username);
    _bio = TextEditingController(text: user.bio);
    _city = brandCities.contains(user.city) ? user.city : brandCities.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<LocalAppStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppTextField(label: 'Display name', controller: _name),
          const SizedBox(height: 12),
          AppTextField(label: 'Username', controller: _username),
          const SizedBox(height: 12),
          AppTextField(label: 'Biography', controller: _bio, maxLines: 3),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _city,
            decoration: const InputDecoration(labelText: 'City'),
            items: [
              for (final city in brandCities)
                DropdownMenuItem(value: city, child: Text(city)),
            ],
            onChanged: (value) => setState(() => _city = value ?? _city),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Save',
            onPressed: () {
              final user = store.session;
              if (user == null) return;
              final ok = runStore(context, () {
                store.updateProfile(
                  userId: user.id,
                  displayName: _name.text,
                  username: _username.text,
                  bio: _bio.text,
                  city: _city,
                );
              });
              if (ok && context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final user = store.session;
    final orders = user == null
        ? const <CustomerOrder>[]
        : store.orders.where((order) => order.userId == user.id).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: orders.isEmpty
          ? const AppEmptyState(
              title: 'No orders',
              body: 'Pre-orders you place will stay here.',
            )
          : ListView(
              children: [
                for (final order in orders.reversed)
                  ListTile(
                    title: Text(order.id),
                    subtitle: Text(
                      '${orderStatusLabel(order.status)} · ${formatIdr(order.subtotalIdr)}',
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OrderDetailPage(orderId: order.id),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark theme'),
            value: store.darkMode,
            onChanged: store.setDarkMode,
          ),
          const SizedBox(height: 8),
          const AppSection(
            title: 'Privacy',
            child: Text(
              'Public posts show a city only. Precise coordinates are not stored. Device location is not requested.',
            ),
          ),
          const SizedBox(height: 12),
          AppListTile(
            title: 'Reset password',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ForgotPasswordPage(),
              ),
            ),
          ),
          AppListTile(
            title: 'Sign out',
            onTap: () {
              store.logout();
              Navigator.of(context).pop();
            },
          ),
          AppListTile(
            title: 'Delete account',
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete account'),
                  content: const Text(
                    'This removes the local account. It cannot grant or keep administrator access.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                store.deleteAccount();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
