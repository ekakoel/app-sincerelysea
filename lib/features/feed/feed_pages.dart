import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
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
  int _limit = 4;

  Future<void> _refresh() async {
    setState(() => _limit = 4);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final posts = store.feedPage(offset: 0, limit: _limit);
    final hasMore = store.posts.length > posts.length;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
            const SizedBox(height: 8),
            if (posts.isEmpty)
              const AppEmptyState(
                title: 'The feed is quiet',
                body: 'Community stories will appear here.',
              )
            else
              ..._columns(context, store, posts),
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

  List<Widget> _columns(
    BuildContext context,
    LocalAppStore store,
    List<CommunityPost> posts,
  ) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    if (!wide) {
      return [for (final post in posts) _PostCard(post: post, store: store)];
    }
    final left = <CommunityPost>[];
    final right = <CommunityPost>[];
    for (var i = 0; i < posts.length; i++) {
      (i.isEven ? left : right).add(posts[i]);
    }
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                for (final post in left) _PostCard(post: post, store: store),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                for (final post in right) _PostCard(post: post, store: store),
              ],
            ),
          ),
        ],
      ),
    ];
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.store});

  final CommunityPost post;
  final LocalAppStore store;

  @override
  Widget build(BuildContext context) {
    final author = store.userById(post.authorId);
    final preview = captionPreview(post.caption);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AppCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PostDetailPage(postId: post.id),
                ),
              ),
              child: PhotoFrame(asset: post.imageAsset, height: 220, radius: 8),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: author?.avatarAsset == null
                      ? null
                      : AssetImage(author!.avatarAsset!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${author?.displayName ?? 'Member'} · ${post.city} · ${relativeTime(post.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PostDetailPage(postId: post.id),
                ),
              ),
              child: Text(preview),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _Count(
                  key: Key('like-${post.id}'),
                  icon:
                      store.session != null &&
                          store.likedBy(store.session!.id, post.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  count: store.likeCount(post.id),
                  onTap: () =>
                      _engage(context, () => store.toggleLike(post.id)),
                ),
                _Count(
                  icon: Icons.chat_bubble_outline,
                  count: store.commentCount(post.id),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PostDetailPage(postId: post.id),
                    ),
                  ),
                ),
                _Count(
                  key: Key('save-${post.id}'),
                  icon:
                      store.session != null &&
                          store.savedBy(store.session!.id, post.id)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  count: store.saveCount(post.id),
                  onTap: () =>
                      _engage(context, () => store.toggleSave(post.id)),
                ),
                _Count(
                  key: Key('share-${post.id}'),
                  icon: Icons.share_outlined,
                  count: post.shareCount,
                  onTap: () => _engage(context, () => store.share(post.id)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _engage(BuildContext context, void Function() action) {
    if (store.session == null) {
      openLogin(context);
      return;
    }
    runStore(context, action);
  }
}

class _Count extends StatelessWidget {
  const _Count({
    super.key,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 4),
              Text('$count', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
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
          Text('${author?.displayName ?? 'Member'} · ${post.city}'),
          const SizedBox(height: 8),
          Text(post.caption),
          if (product != null) ...[
            const SizedBox(height: 12),
            AppListTile(
              title: product.name,
              subtitle: formatIdr(product.priceIdr),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductPage(productId: product.id),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${store.likeCount(post.id)} likes · ${store.saveCount(post.id)} saves · ${post.shareCount} shares',
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
  bool _busy = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
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
          DropdownButtonFormField<String>(
            initialValue: _city,
            decoration: const InputDecoration(labelText: 'City'),
            items: [
              for (final city in brandCities)
                DropdownMenuItem(value: city, child: Text(city)),
            ],
            onChanged: (value) => setState(() => _city = value ?? _city),
          ),
          const SizedBox(height: 8),
          Text(
            'Shared as kabupaten/kota. A map pin is not attached.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
