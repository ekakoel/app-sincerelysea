import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';
import '../../data/local_store.dart';
import '../../domain/policies.dart';
import '../auth/auth_pages.dart';
import '../shop/shop_pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _limit = 8;
  bool _forYou = true;

  Future<void> _refresh() async {
    setState(() => _limit = 8);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final posts = _forYou
        ? store.rankedPosts(viewerId: store.session?.id).take(_limit).toList()
        : store.feedPage(offset: 0, limit: _limit);
    final hasMore = store.posts.length > posts.length;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            Row(
              children: [
                const BrandIcon(size: 40),
                const Spacer(),
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () {
                    if (store.session == null) {
                      openLogin(context);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_none),
                ),
                IconButton(
                  key: const Key('create-post'),
                  tooltip: 'Create post',
                  onPressed: () {
                    if (store.session == null) {
                      openLogin(context);
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreatePostPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('For you'),
                  selected: _forYou,
                  onSelected: (_) => setState(() => _forYou = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Latest'),
                  selected: !_forYou,
                  onSelected: (_) => setState(() => _forYou = false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppListTile(
              title: 'Leather care',
              subtitle: 'Notes members use between wears.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LeatherCarePage(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (posts.isEmpty)
              const AppEmptyState(
                title: 'The feed is quiet',
                body: 'Community stories will appear here.',
              )
            else
              _Masonry(posts: posts, store: store),
            if (hasMore)
              TextButton(
                onPressed: () => setState(() => _limit += 4),
                child: const Text('More stories'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Masonry extends StatelessWidget {
  const _Masonry({required this.posts, required this.store});

  final List<CommunityPost> posts;
  final LocalAppStore store;

  static const _heights = [168.0, 232.0, 196.0, 248.0, 180.0, 214.0];

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.sizeOf(context).width >= 900 ? 3 : 2;
    final buckets = List.generate(columns, (_) => <Widget>[]);
    for (var i = 0; i < posts.length; i++) {
      buckets[i % columns].add(
        _PostCard(
          post: posts[i],
          store: store,
          height: _heights[i % _heights.length],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var column = 0; column < columns; column++) ...[
          if (column > 0) const SizedBox(width: 8),
          Expanded(child: Column(children: buckets[column])),
        ],
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.store,
    required this.height,
  });

  final CommunityPost post;
  final LocalAppStore store;
  final double height;

  @override
  Widget build(BuildContext context) {
    final author = store.userById(post.authorId);
    final product = post.productId == null
        ? null
        : store.catalog[post.productId];
    final where = post.sharesMapPoint
        ? '${post.city} · ${formatPoint(post.latitude!, post.longitude!)}'
        : post.city;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _open(context),
            child: Stack(
              children: [
                PhotoFrame(asset: post.imageAsset, height: height, radius: 12),
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${store.likeCount(post.id)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chat_bubble,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${store.commentCount(post.id)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            author?.displayName ?? 'Member',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          GestureDetector(
            onTap: () => _open(context),
            child: Text(
              captionPreview(post.caption),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (product != null)
            Text(
              '${product.name} · ${store.productPopularity(product.id)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          Text(
            where,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PostDetailPage(postId: post.id)),
    );
  }
}

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final post = store.posts.cast<CommunityPost?>().firstWhere(
      (item) => item!.id == widget.postId,
      orElse: () => null,
    );
    if (post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppEmptyState(
          title: 'Post unavailable',
          body: 'This story is no longer here.',
        ),
      );
    }
    final author = store.userById(post.authorId);
    final comments = store.comments
        .where((item) => item.postId == post.id)
        .toList();
    final product = post.productId == null
        ? null
        : store.catalog[post.productId];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story'),
        actions: [
          if (store.session?.id == post.authorId)
            IconButton(
              tooltip: 'Delete post',
              onPressed: () {
                final ok = runStore(
                  context,
                  () => store.deleteOwnPost(post.id),
                );
                if (ok && context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline),
            ),
          IconButton(
            tooltip: 'Report',
            onPressed: () {
              if (store.session == null) {
                openLogin(context);
                return;
              }
              final ok = runStore(
                context,
                () => store.report(
                  targetType: 'post',
                  targetId: post.id,
                  reason: 'Community report',
                ),
              );
              if (ok && context.mounted) {
                showAppFeedback(context, 'Report sent to moderation.');
              }
            },
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PhotoFrame(asset: post.imageAsset, height: 320, radius: 12),
          const SizedBox(height: 12),
          Text(
            '${author?.displayName ?? 'Member'} · ${topicLabel(post.topic)}',
          ),
          Text(
            post.sharesMapPoint
                ? '${post.city} · ${formatPoint(post.latitude!, post.longitude!)}'
                : '${post.city} · city only',
          ),
          if (store.session != null && store.session!.id != post.authorId)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    runStore(context, () => store.toggleFollow(post.authorId)),
                child: Text(
                  store.isFollowing(store.session!.id, post.authorId)
                      ? 'Following'
                      : 'Follow',
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(post.caption),
          if (product != null) ...[
            const SizedBox(height: 12),
            AppListTile(
              title: product.name,
              subtitle:
                  '${formatIdr(product.priceIdr)} · popularity ${store.productPopularity(product.id)}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductPage(productId: product.id),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${store.likeCount(post.id)} likes · ${store.commentCount(post.id)} comments · ${store.saveCount(post.id)} saves · ${post.shareCount} shares',
          ),
          const SizedBox(height: 16),
          Text('Comments', style: Theme.of(context).textTheme.titleMedium),
          if (comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No comments yet.'),
            ),
          for (final comment in comments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                store.userById(comment.authorId)?.displayName ?? 'Member',
              ),
              subtitle: Text(comment.body),
              trailing: store.session?.id == comment.authorId
                  ? IconButton(
                      onPressed: () => runStore(
                        context,
                        () => store.deleteOwnComment(comment.id),
                      ),
                      icon: const Icon(Icons.close),
                    )
                  : null,
            ),
          const SizedBox(height: 8),
          AppTextField(label: 'Comment', controller: _comment),
          const SizedBox(height: 8),
          AppButton(
            label: 'Publish comment',
            onPressed: () {
              if (store.session == null) {
                openLogin(context);
                return;
              }
              final ok = runStore(
                context,
                () => store.addComment(post.id, _comment.text),
              );
              if (ok) _comment.clear();
            },
          ),
        ],
      ),
    );
  }
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _caption = TextEditingController();
  String _asset = galleryAssets.first;
  String _city = brandCities.first;
  String? _productId;
  String _topic = 'story';
  bool _shareOnMap = false;
  double? _latitude;
  double? _longitude;
  bool _busy = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _useCityCenter() {
    final center = cityCenters[_city];
    setState(() {
      _latitude = center?.latitude;
      _longitude = center?.longitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final pin = _latitude != null && _longitude != null
        ? LatLng(_latitude!, _longitude!)
        : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Create post')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PhotoFrame(asset: _asset, height: 220),
          const SizedBox(height: 12),
          const Text(
            'Choose a studio photograph. Camera upload waits for Firebase Storage.',
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final asset in galleryAssets)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _asset = asset),
                      child: SizedBox(
                        width: 72,
                        child: PhotoFrame(asset: asset, height: 72, radius: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Caption', controller: _caption, maxLines: 3),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final topic in postTopics)
                ChoiceChip(
                  label: Text(topicLabel(topic)),
                  selected: topic == _topic,
                  onSelected: (_) => setState(() => _topic = topic),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _city,
            decoration: const InputDecoration(labelText: 'City'),
            items: [
              for (final city in brandCities)
                DropdownMenuItem(value: city, child: Text(city)),
            ],
            onChanged: (value) {
              setState(() => _city = value ?? _city);
              if (_shareOnMap) _useCityCenter();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Share a GPS point'),
            subtitle: const Text(
              'Off by default. This places a pin you choose. It does not track your phone.',
            ),
            value: _shareOnMap,
            onChanged: (value) {
              setState(() => _shareOnMap = value);
              if (value) {
                _useCityCenter();
              } else {
                setState(() {
                  _latitude = null;
                  _longitude = null;
                });
              }
            },
          ),
          if (_shareOnMap && pin != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: pin,
                    initialZoom: 12,
                    onTap: (_, point) {
                      setState(() {
                        _latitude = point.latitude;
                        _longitude = point.longitude;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sincerelysea.sincerelysea',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pin,
                          width: 28,
                          height: 28,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'GPS ${formatPoint(_latitude!, _longitude!)}. Tap the map to move it.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _productId,
            decoration: const InputDecoration(labelText: 'Product'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No product'),
              ),
              for (final product in store.catalog.values)
                DropdownMenuItem<String?>(
                  value: product.id,
                  child: Text(product.name),
                ),
            ],
            onChanged: (value) => setState(() => _productId = value),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: _busy ? 'Publishing' : 'Publish',
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await Future<void>.delayed(
                      const Duration(milliseconds: 250),
                    );
                    if (!context.mounted) return;
                    final ok = runStore(context, () {
                      store.publishPost(
                        imageAsset: _asset,
                        caption: _caption.text,
                        city: _city,
                        productId: _productId,
                        topic: _topic,
                        shareOnMap: _shareOnMap,
                        latitude: _latitude,
                        longitude: _longitude,
                      );
                    });
                    if (!context.mounted) return;
                    setState(() => _busy = false);
                    if (ok) Navigator.of(context).pop();
                  },
          ),
        ],
      ),
    );
  }
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final user = store.session;
    final notes = user == null
        ? const <AppNotice>[]
        : store.notices
              .where((notice) => notice.userId == user.id)
              .toList()
              .reversed
              .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notes.isEmpty
          ? const AppEmptyState(
              title: 'No notifications',
              body: 'Order and community updates will appear here.',
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final notice in notes)
                  AppListTile(
                    title: notice.title,
                    subtitle: notice.body,
                    onTap:
                        notice.targetType == 'order' && notice.targetId != null
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  OrderDetailPage(orderId: notice.targetId!),
                            ),
                          )
                        : null,
                  ),
              ],
            ),
    );
  }
}

class LeatherCarePage extends StatelessWidget {
  const LeatherCarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leather care')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Community notes for calfskin, not a warranty. Share what worked for your own piece.',
          ),
          SizedBox(height: 16),
          AppListTile(
            title: 'After a wet day',
            subtitle: 'Wipe with a dry cloth. Let it dry in the shade.',
          ),
          AppListTile(
            title: 'Between wears',
            subtitle: 'Empty it, stuff the shape lightly, and rest the strap.',
          ),
          AppListTile(
            title: 'Patina',
            subtitle: 'Color deepens with use. That is the story, not a stain to erase.',
          ),
          AppListTile(
            title: 'Ask the circle',
            subtitle:
                'Post with the Care topic so the answer stays on the map.',
          ),
        ],
      ),
    );
  }
}
