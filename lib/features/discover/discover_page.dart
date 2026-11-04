import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

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
  final MapController _map = MapController();
  String _topic = 'all';
  String? _selectedId;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final viewerId = store.session?.id;
    final ranked = store.rankedPosts(viewerId: viewerId, topic: _topic);
    final mapped = ranked.where((post) => post.sharesMapPoint).toList();
    var maxHeat = 0;
    for (final post in mapped) {
      final heat = store.heatFor(post, viewerId: viewerId);
      if (heat > maxHeat) maxHeat = heat;
    }
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const BrandWordmark(width: 150),
          const SizedBox(height: 16),
          Text('Discover', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'OpenStreetMap. A larger marker means more conversation. Your live location is never read.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final topic in ['all', ...postTopics])
                ChoiceChip(
                  label: Text(topic == 'all' ? 'All' : topicLabel(topic)),
                  selected: topic == _topic,
                  onSelected: (_) => setState(() => _topic = topic),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 420,
              child: FlutterMap(
                mapController: _map,
                options: const MapOptions(
                  initialCenter: LatLng(0, 20),
                  initialZoom: 2,
                  minZoom: 1,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sincerelysea.sincerelysea',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final post in mapped)
                        _marker(context, store, post, maxHeat, viewerId),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () => _map.move(const LatLng(0, 20), 2),
                child: const Text('World'),
              ),
              TextButton(
                onPressed: () => _map.move(const LatLng(-8.65, 115.2), 9),
                child: const Text('Bali'),
              ),
            ],
          ),
          Text(
            'In the conversation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (ranked.isEmpty)
            const AppEmptyState(
              title: 'Nothing in this topic yet',
              body: 'Care notes and wearing stories will gather here.',
            )
          else
            for (final post in ranked.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppListTile(
                  title:
                      '${store.userById(post.authorId)?.displayName ?? 'Member'} · ${topicLabel(post.topic)}',
                  subtitle: _subtitle(store, post),
                  onTap: () => _open(context, post.id),
                ),
              ),
        ],
      ),
    );
  }

  Marker _marker(
    BuildContext context,
    LocalAppStore store,
    CommunityPost post,
    int maxHeat,
    String? viewerId,
  ) {
    final heat = store.heatFor(post, viewerId: viewerId);
    final dominance = mapDominance(heat, maxHeat);
    final size = 28 + dominance * 46;
    final selected = post.id == _selectedId;
    return Marker(
      key: Key('map-${post.id}'),
      point: LatLng(post.latitude!, post.longitude!),
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedId = post.id);
          _open(context, post.id);
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.black,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.black : Colors.white,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '${store.commentCount(post.id)}',
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontSize: size > 48 ? 13 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(LocalAppStore store, CommunityPost post) {
    final where = post.sharesMapPoint
        ? '${post.city} · ${formatPoint(post.latitude!, post.longitude!)}'
        : post.city;
    final product = post.productId == null
        ? ''
        : ' · ${store.catalog[post.productId]?.name ?? 'Piece'} ${store.productPopularity(post.productId!)}';
    return '$where · ${store.likeCount(post.id)} likes · ${store.commentCount(post.id)} comments$product';
  }

  void _open(BuildContext context, String postId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PostDetailPage(postId: postId)),
    );
  }
}
