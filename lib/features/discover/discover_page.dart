import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';
import '../../data/local_store.dart';
import '../../domain/policies.dart';
import '../feed/feed_pages.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  String _city = brandCities.first;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final posts = store.posts.where((post) => post.city == _city).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const BrandWordmark(width: 150),
          const SizedBox(height: 16),
          Text('Discover', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Posts are placed by kabupaten/kota. This screen does not read device location and does not draw a precise pin.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final city in brandCities)
                ChoiceChip(
                  label: Text(city),
                  selected: city == _city,
                  onSelected: (_) => setState(() => _city = city),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (posts.isEmpty)
            const AppEmptyState(
              title: 'No stories in this city',
              body: 'When a member shares this city, the post will appear here.',
            )
          else
            for (final post in posts)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppListTile(
                  title: '${store.userById(post.authorId)?.displayName ?? 'Member'} · ${post.city}',
                  subtitle: captionPreview(post.caption),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => PostDetailPage(postId: post.id)),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
