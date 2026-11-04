import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../domain/policies.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.username,
    required this.passwordHash,
    this.bio = '',
    this.city = 'Denpasar',
    this.avatarAsset,
    this.emailVerified = false,
    this.adminClaim = false,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.utc(2025, 6, 1);

  final String id;
  final String email;
  String displayName;
  String username;
  String passwordHash;
  String bio;
  String city;
  String? avatarAsset;
  bool emailVerified;
  final bool adminClaim;
  final DateTime joinedAt;
}

class CommunityPost {
  CommunityPost({
    required this.id,
    required this.authorId,
    required this.imageAsset,
    required this.caption,
    required this.city,
    required this.createdAt,
    this.productId,
    this.shareCount = 0,
    this.latitude,
    this.longitude,
    this.topic = 'story',
  });

  final String id;
  final String authorId;
  final String imageAsset;
  final String caption;
  final String city;
  final DateTime createdAt;
  final String? productId;
  int shareCount;
  final double? latitude;
  final double? longitude;
  final String topic;

  bool get sharesMapPoint => latitude != null && longitude != null;
}

class PostComment {
  PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final String body;
  final DateTime createdAt;
}

class CustomerOrder {
  CustomerOrder({
    required this.id,
    required this.userId,
    required this.lines,
    required this.subtotalIdr,
    required this.status,
    required this.createdAt,
    required this.shipTo,
  });

  final String id;
  final String userId;
  final List<QuotedLine> lines;
  final int subtotalIdr;
  OrderStatus status;
  final DateTime createdAt;
  final String shipTo;
}

class OwnershipRecord {
  OwnershipRecord({
    required this.id,
    required this.productId,
    required this.ownerId,
    required this.source,
    required this.status,
    required this.since,
    this.orderId,
  });

  final String id;
  final String productId;
  final String ownerId;
  final OwnershipSource source;
  final OwnershipStatus status;
  final DateTime since;
  final String? orderId;
}

class DirectMessage {
  DirectMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.sentAt,
    this.read = false,
  });

  final String id;
  final String senderId;
  final String body;
  final DateTime sentAt;
  bool read;
}

class Conversation {
  Conversation({
    required this.id,
    required this.participantIds,
    required this.messages,
  });

  final String id;
  final List<String> participantIds;
  final List<DirectMessage> messages;
}

class AppNotice {
  AppNotice({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.targetType,
    this.targetId,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? targetType;
  final String? targetId;
}

class ContentReport {
  ContentReport({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
  });

  final String id;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String reason;
}

class ResaleListing {
  ResaleListing({
    required this.id,
    required this.ownershipId,
    required this.sellerId,
    required this.productId,
    required this.note,
  });

  final String id;
  final String ownershipId;
  final String sellerId;
  final String productId;
  final String note;
  String status = 'open';
}

class GiftRequest {
  GiftRequest({
    required this.id,
    required this.ownershipId,
    required this.fromUserId,
    required this.toUserId,
  });

  final String id;
  final String ownershipId;
  final String fromUserId;
  final String toUserId;
  String status = 'pending';
}

class ResaleInterest {
  ResaleInterest({
    required this.id,
    required this.listingId,
    required this.buyerId,
  });

  final String id;
  final String listingId;
  final String buyerId;
}

class StoreException implements Exception {
  StoreException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Device-local snapshot. This is not a security boundary.
abstract class SnapshotPersistence {
  Future<String?> load();
  void save(String raw);
}

class MemorySnapshotPersistence implements SnapshotPersistence {
  String? value;

  @override
  Future<String?> load() async => value;

  @override
  void save(String raw) => value = raw;
}

/// Local adapter used until Firebase credentials are configured.
/// Passwords are hashed and never written to Firestore.
/// Administrator access cannot be granted from this client.
const _seedPoints = <String, PostPoint>{
  'post-mira': PostPoint(latitude: -8.667, longitude: 115.216),
  'post-sari': PostPoint(latitude: -8.718, longitude: 115.169),
  'post-dita': PostPoint(latitude: -8.655, longitude: 115.222),
  'post-ayu': PostPoint(latitude: -8.275, longitude: 115.167),
  'post-atelier': PostPoint(latitude: -8.682, longitude: 115.204),
  'post-sand': PostPoint(latitude: -8.731, longitude: 115.168),
};

class LocalAppStore extends ChangeNotifier {
  LocalAppStore({DateTime Function()? clock, this.persistence})
    : _clock = clock ?? DateTime.now {
    _seed();
  }

  final SnapshotPersistence? persistence;
  bool restored = false;
  bool _persistSuspended = false;

  final DateTime Function() _clock;
  final Map<String, AppUser> users = {};
  final Map<String, CatalogProduct> catalog = {};
  final List<CommunityPost> posts = [];
  final List<PostComment> comments = [];
  final List<CustomerOrder> orders = [];
  final List<OwnershipRecord> ownership = [];
  final List<Conversation> conversations = [];
  final List<AppNotice> notices = [];
  final List<ContentReport> reports = [];
  final Map<String, List<CartRequest>> carts = {};
  final Set<String> likes = {};
  final Set<String> saves = {};
  final Set<String> wishlist = {};
  final Set<String> follows = {};

  final List<ResaleListing> listings = [];
  final List<GiftRequest> gifts = [];
  final List<ResaleInterest> interests = [];
  final List<String> auditLog = [];
  final Set<String> blocks = {};

  AppUser? session;
  bool onboardingComplete = false;
  bool darkMode = false;
  bool splashSeen = false;
  String? pendingVerificationCode;
  String? pendingResetCode;
  String? pendingResetUserId;
  int _seq = 100;

  static const fixtureEmail = 'ayu@sincerelysea.dev';
  static const fixturePassword = 'preview-ayu';

  @override
  void notifyListeners() {
    super.notifyListeners();
    final persistence = this.persistence;
    if (_persistSuspended || persistence == null) return;
    persistence.save(jsonEncode(toSnapshot()));
  }

  Future<void> restore() async {
    final persistence = this.persistence;
    if (persistence == null) return;
    final raw = await persistence.load();
    if (raw == null || raw.trim().isEmpty) return;
    _persistSuspended = true;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Snapshot is not an object.');
      }
      applySnapshot(Map<String, Object?>.from(decoded));
      restored = true;
    } catch (_) {
      _clearMutable();
      _seed();
      session = null;
      restored = false;
    } finally {
      _persistSuspended = false;
    }
    if (restored) notifyListeners();
  }

  void _seed() {
    final ayu = AppUser(
      id: 'user-ayu',
      email: fixtureEmail,
      displayName: 'Ayu Putri',
      username: 'ayu',
      passwordHash: _hash(fixturePassword),
      bio: 'Slow fashion · Bali',
      city: 'Bedugul',
      avatarAsset: 'assets/photos/ava_ayu.jpg',
      emailVerified: true,
    );
    final mira = AppUser(
      id: 'user-mira',
      email: 'mira@sincerelysea.dev',
      displayName: 'Mira',
      username: 'mira',
      passwordHash: _hash('not-a-login'),
      city: 'Denpasar',
      avatarAsset: 'assets/photos/ava_mira.jpg',
      emailVerified: true,
    );
    final sari = AppUser(
      id: 'user-sari',
      email: 'sari@sincerelysea.dev',
      displayName: 'Sari',
      username: 'sari',
      passwordHash: _hash('not-a-login'),
      city: 'Kuta',
      avatarAsset: 'assets/photos/ava_sari.jpg',
      emailVerified: true,
    );
    final dita = AppUser(
      id: 'user-dita',
      email: 'dita@sincerelysea.dev',
      displayName: 'Dita',
      username: 'dita',
      passwordHash: _hash('not-a-login'),
      city: 'Denpasar',
      avatarAsset: 'assets/photos/ava_dita.jpg',
      emailVerified: true,
    );
    for (final user in [ayu, mira, sari, dita]) {
      users[user.id] = user;
    }

    catalog['jane-medium'] = const CatalogProduct(
      id: 'jane-medium',
      name: 'Jane Medium',
      priceIdr: 1500000,
      imageAsset: 'assets/photos/jane.jpg',
      material: 'Cognac · Calfskin',
      preorder: true,
      fulfillment: 'Ships in 2–3 weeks',
      variant: 'Cognac',
    );
    catalog['jane-sand'] = const CatalogProduct(
      id: 'jane-sand',
      name: 'Jane · Sand',
      priceIdr: 1500000,
      imageAsset: 'assets/photos/sand.jpg',
      material: 'Sand · Calfskin',
      preorder: true,
      fulfillment: 'Ships in 2–3 weeks',
      variant: 'Sand',
    );
    catalog['viola-sling'] = const CatalogProduct(
      id: 'viola-sling',
      name: 'Viola Sling',
      priceIdr: 830000,
      imageAsset: 'assets/photos/viola.jpg',
      material: 'Tan · Calfskin',
      preorder: true,
      fulfillment: 'Ships in 2–3 weeks',
      variant: 'Tan',
    );
    catalog['satchel'] = const CatalogProduct(
      id: 'satchel',
      name: 'Satchel',
      priceIdr: 1750000,
      imageAsset: 'assets/photos/satchel.jpg',
      material: 'Calfskin',
      preorder: true,
      fulfillment: 'Made to order',
    );

    posts.addAll([
      CommunityPost(
        id: 'post-mira',
        authorId: mira.id,
        imageAsset: 'assets/photos/jane.jpg',
        caption: 'Jane, on the way to the studio',
        city: 'Denpasar',
        createdAt: _clock().subtract(const Duration(hours: 2)),
        productId: 'jane-medium',
        topic: 'experience',
        latitude: -8.667,
        longitude: 115.216,
      ),
      CommunityPost(
        id: 'post-sari',
        authorId: sari.id,
        imageAsset: 'assets/photos/life.jpg',
        caption: 'Morning light, the strap still new',
        city: 'Kuta',
        createdAt: _clock().subtract(const Duration(hours: 5)),
        topic: 'story',
        latitude: -8.718,
        longitude: 115.169,
      ),
      CommunityPost(
        id: 'post-dita',
        authorId: dita.id,
        imageAsset: 'assets/photos/carry.jpg',
        caption: 'Carried this to the morning market',
        city: 'Denpasar',
        createdAt: _clock().subtract(const Duration(days: 1)),
        productId: 'viola-sling',
        shareCount: 7,
        topic: 'experience',
        latitude: -8.655,
        longitude: 115.222,
      ),
      CommunityPost(
        id: 'post-ayu',
        authorId: ayu.id,
        imageAsset: 'assets/photos/bali.jpg',
        caption: 'Morning at the lake, shared as a city',
        city: 'Bedugul',
        createdAt: _clock().subtract(const Duration(days: 2)),
        productId: 'jane-medium',
        topic: 'story',
        latitude: -8.275,
        longitude: 115.167,
      ),
      CommunityPost(
        id: 'post-atelier',
        authorId: mira.id,
        imageAsset: 'assets/photos/atelier.jpg',
        caption: 'Condition the strap, then let it rest',
        city: 'Denpasar',
        createdAt: _clock().subtract(const Duration(days: 4)),
        topic: 'care',
        latitude: -8.682,
        longitude: 115.204,
      ),
      CommunityPost(
        id: 'post-sand',
        authorId: sari.id,
        imageAsset: 'assets/photos/sand.jpg',
        caption: 'Sand leather in late light',
        city: 'Kuta',
        createdAt: _clock().subtract(const Duration(days: 6)),
        productId: 'jane-sand',
        topic: 'experience',
        latitude: -8.731,
        longitude: 115.168,
      ),
    ]);
    comments.addAll([
      PostComment(
        id: 'comment-mira-1',
        postId: 'post-mira',
        authorId: ayu.id,
        body: 'How do you keep the cognac from spotting after rain?',
        createdAt: _clock().subtract(const Duration(hours: 1)),
      ),
      PostComment(
        id: 'comment-mira-2',
        postId: 'post-mira',
        authorId: mira.id,
        body: 'A dry cloth the same day. I leave the patina alone.',
        createdAt: _clock().subtract(const Duration(minutes: 40)),
      ),
      PostComment(
        id: 'comment-dita-1',
        postId: 'post-dita',
        authorId: sari.id,
        body: 'The sling sits well for a market morning.',
        createdAt: _clock().subtract(const Duration(hours: 20)),
      ),
      PostComment(
        id: 'comment-care-1',
        postId: 'post-atelier',
        authorId: dita.id,
        body: 'Do you condition the strap every season?',
        createdAt: _clock().subtract(const Duration(days: 3)),
      ),
    ]);
    likes.addAll([
      'user-ayu|post-mira',
      'user-sari|post-mira',
      'user-dita|post-mira',
      'user-mira|post-dita',
      'user-ayu|post-dita',
      'user-dita|post-sand',
      'user-mira|post-atelier',
    ]);
    saves.addAll(['user-ayu|post-mira', 'user-sari|post-atelier']);
    follows.add('user-ayu|user-mira');

    orders.add(
      CustomerOrder(
        id: 'SS-2025-014',
        userId: ayu.id,
        lines: [
          const QuotedLine(
            productId: 'jane-medium',
            name: 'Jane Medium',
            quantity: 1,
            unitPriceIdr: 1500000,
          ),
        ],
        subtotalIdr: 1500000,
        status: OrderStatus.delivered,
        createdAt: DateTime.utc(2025, 4, 2),
        shipTo: 'Bedugul',
      ),
    );
    ownership.add(
      OwnershipRecord(
        id: 'own-ayu-jane',
        productId: 'jane-medium',
        ownerId: ayu.id,
        source: OwnershipSource.eligiblePurchase,
        status: OwnershipStatus.verified,
        since: DateTime.utc(2025, 5, 1),
        orderId: 'SS-2025-014',
      ),
    );
    conversations.add(
      Conversation(
        id: 'conv-ayu-mira',
        participantIds: [ayu.id, mira.id],
        messages: [
          DirectMessage(
            id: 'msg-1',
            senderId: mira.id,
            body: 'The cognac Jane looks right with that light.',
            sentAt: _clock().subtract(const Duration(hours: 8)),
          ),
        ],
      ),
    );
    notices.add(
      AppNotice(
        id: 'note-1',
        userId: ayu.id,
        title: 'Order delivered',
        body: 'Jane Medium · SS-2025-014 is in your verified collection.',
        createdAt: DateTime.utc(2025, 5, 1),
        targetType: 'order',
        targetId: 'SS-2025-014',
      ),
    );
  }

  String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  String _id(String prefix) => '$prefix-${_seq++}';

  AppUser? userById(String id) => users[id];

  List<CommunityPost> feedPage({required int offset, int limit = 6}) {
    final sorted = [...posts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (offset >= sorted.length) return const [];
    final end = offset + limit > sorted.length ? sorted.length : offset + limit;
    return sorted.sublist(offset, end);
  }

  int heatFor(CommunityPost post, {String? viewerId}) {
    final followsAuthor =
        viewerId != null && follows.contains('$viewerId|${post.authorId}');
    final followsProduct =
        viewerId != null &&
        post.productId != null &&
        posts.any(
          (other) =>
              other.id != post.id &&
              other.productId == post.productId &&
              likedBy(viewerId, other.id),
        );
    return communityHeat(
      likes: likeCount(post.id),
      comments: commentCount(post.id),
      saves: saveCount(post.id),
      shares: post.shareCount,
      age: _clock().difference(post.createdAt),
      followsAuthor: followsAuthor,
      followsProduct: followsProduct,
      topic: post.topic,
    );
  }

  List<CommunityPost> rankedPosts({String? viewerId, String topic = 'all'}) {
    final list = [
      for (final post in posts)
        if (topic == 'all' || post.topic == topic) post,
    ];
    list.sort((a, b) {
      final byHeat = heatFor(
        b,
        viewerId: viewerId,
      ).compareTo(heatFor(a, viewerId: viewerId));
      if (byHeat != 0) return byHeat;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  int productPopularity(String productId) {
    var postCount = 0;
    var likeTotal = 0;
    var commentTotal = 0;
    var saveTotal = 0;
    for (final post in posts) {
      if (post.productId != productId) continue;
      postCount += 1;
      likeTotal += likeCount(post.id);
      commentTotal += commentCount(post.id);
      saveTotal += saveCount(post.id);
    }
    final orderCount = orders.where((order) {
      if (order.status == OrderStatus.cancelled ||
          order.status == OrderStatus.failed) {
        return false;
      }
      return order.lines.any((line) => line.productId == productId);
    }).length;
    return productPopularityScore(
      posts: postCount,
      likes: likeTotal,
      comments: commentTotal,
      saves: saveTotal,
      orders: orderCount,
    );
  }

  void toggleFollow(String userId) {
    final user = _requireSession();
    if (user.id == userId) {
      throw StoreException('You cannot follow yourself.');
    }
    if (!users.containsKey(userId)) {
      throw StoreException('Member not found.');
    }
    final key = '${user.id}|$userId';
    if (!follows.add(key)) follows.remove(key);
    notifyListeners();
  }

  bool isFollowing(String followerId, String userId) =>
      follows.contains('$followerId|$userId');

  int likeCount(String postId) =>
      likes.where((key) => key.endsWith('|$postId')).length;

  int saveCount(String postId) =>
      saves.where((key) => key.endsWith('|$postId')).length;

  int commentCount(String postId) =>
      comments.where((comment) => comment.postId == postId).length;

  bool likedBy(String userId, String postId) =>
      likes.contains('$userId|$postId');

  bool savedBy(String userId, String postId) =>
      saves.contains('$userId|$postId');

  void register({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) {
    final normalized = email.trim().toLowerCase();
    final handle = username.trim().toLowerCase();
    if (password.length < 8) {
      throw StoreException('Use at least 8 characters.');
    }
    if (users.values.any((user) => user.email == normalized)) {
      throw StoreException('That email is already registered.');
    }
    if (users.values.any((user) => user.username == handle)) {
      throw StoreException('That username is taken.');
    }
    final user = AppUser(
      id: _id('user'),
      email: normalized,
      displayName: displayName.trim(),
      username: handle,
      passwordHash: _hash(password),
      emailVerified: false,
      joinedAt: _clock(),
    );
    users[user.id] = user;
    session = user;
    pendingVerificationCode = '184206';
    notifyListeners();
  }

  void login({required String email, required String password}) {
    final normalized = email.trim().toLowerCase();
    final user = users.values.cast<AppUser?>().firstWhere(
      (item) => item!.email == normalized,
      orElse: () => null,
    );
    if (user == null || user.passwordHash != _hash(password)) {
      throw StoreException('Email or password is incorrect.');
    }
    session = user;
    notifyListeners();
  }

  void logout() {
    session = null;
    notifyListeners();
  }

  void completeOnboarding() {
    onboardingComplete = true;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    darkMode = value;
    notifyListeners();
  }

  void markSplashSeen() {
    if (splashSeen) return;
    splashSeen = true;
    notifyListeners();
  }

  void requestPasswordReset(String email) {
    final normalized = email.trim().toLowerCase();
    final user = users.values.cast<AppUser?>().firstWhere(
      (item) => item!.email == normalized,
      orElse: () => null,
    );
    if (user == null) {
      throw StoreException('No account uses that email.');
    }
    pendingResetCode = '392817';
    pendingResetUserId = user.id;
    notifyListeners();
  }

  void completePasswordReset({
    required String code,
    required String newPassword,
  }) {
    if (pendingResetUserId == null || code.trim() != pendingResetCode) {
      throw StoreException('Reset code is not valid.');
    }
    if (newPassword.length < 8) {
      throw StoreException('Use at least 8 characters.');
    }
    users[pendingResetUserId!]!.passwordHash = _hash(newPassword);
    pendingResetCode = null;
    pendingResetUserId = null;
    notifyListeners();
  }

  void confirmEmail(String code) {
    final user = _requireSession();
    if (pendingVerificationCode == null ||
        code.trim() != pendingVerificationCode) {
      throw StoreException('Verification code is not valid.');
    }
    user.emailVerified = true;
    pendingVerificationCode = null;
    notifyListeners();
  }

  void updateProfile({
    required String userId,
    required String displayName,
    required String username,
    required String bio,
    required String city,
  }) {
    final actor = _requireSession();
    if (actor.id != userId) {
      throw StoreException('You can only edit your own profile.');
    }
    final handle = username.trim().toLowerCase();
    final taken = users.values.any(
      (user) => user.username == handle && user.id != userId,
    );
    if (taken) throw StoreException('That username is taken.');
    actor.displayName = displayName.trim();
    actor.username = handle;
    actor.bio = bio.trim();
    actor.city = city.trim();
    notifyListeners();
  }

  void deleteAccount() {
    final user = _requireSession();
    final id = user.id;
    users.remove(id);
    posts.removeWhere((post) => post.authorId == id);
    comments.removeWhere((comment) => comment.authorId == id);
    notices.removeWhere((notice) => notice.userId == id);
    carts.remove(id);
    likes.removeWhere((key) => key.startsWith('$id|'));
    saves.removeWhere((key) => key.startsWith('$id|'));
    wishlist.removeWhere((key) => key.startsWith('$id|'));
    follows.removeWhere(
      (key) => key.startsWith('$id|') || key.endsWith('|$id'),
    );
    blocks.removeWhere((key) => key.startsWith('$id|') || key.endsWith('|$id'));
    conversations.removeWhere(
      (conversation) => conversation.participantIds.contains(id),
    );
    pendingVerificationCode = null;
    pendingResetCode = null;
    pendingResetUserId = null;
    session = null;
    notifyListeners();
  }

  void toggleLike(String postId) {
    final user = _requireSession();
    final key = '${user.id}|$postId';
    if (!likes.add(key)) likes.remove(key);
    notifyListeners();
  }

  void toggleSave(String postId) {
    final user = _requireSession();
    final key = '${user.id}|$postId';
    if (!saves.add(key)) saves.remove(key);
    notifyListeners();
  }

  void share(String postId) {
    _requireSession();
    final post = _post(postId);
    post.shareCount += 1;
    notifyListeners();
  }

  PostComment addComment(String postId, String body) {
    final user = _requireSession();
    final text = body.trim();
    if (text.isEmpty) throw StoreException('Write a comment first.');
    final comment = PostComment(
      id: _id('comment'),
      postId: postId,
      authorId: user.id,
      body: text,
      createdAt: _clock(),
    );
    comments.add(comment);
    notifyListeners();
    return comment;
  }

  void deleteOwnComment(String commentId) {
    final user = _requireSession();
    final comment = comments.cast<PostComment?>().firstWhere(
      (item) => item!.id == commentId,
      orElse: () => null,
    );
    if (comment == null) throw StoreException('Comment not found.');
    if (comment.authorId != user.id) {
      throw StoreException('You can only delete your own comment.');
    }
    comments.remove(comment);
    notifyListeners();
  }

  void deleteOwnPost(String postId) {
    final user = _requireSession();
    final post = _post(postId);
    if (post.authorId != user.id) {
      throw StoreException('You can only delete your own post.');
    }
    posts.remove(post);
    comments.removeWhere((comment) => comment.postId == postId);
    notifyListeners();
  }

  CommunityPost publishPost({
    required String imageAsset,
    required String caption,
    required String city,
    String? productId,
    String topic = 'story',
    bool shareOnMap = false,
    double? latitude,
    double? longitude,
  }) {
    final user = _requireSession();
    if (!user.emailVerified) {
      throw StoreException('Verify your email before publishing.');
    }
    final place = PublicPlace(city.trim());
    if (!place.isCityLevel) {
      throw StoreException('Share a city, not a coordinate in the city name.');
    }
    if (caption.trim().length < 3) {
      throw StoreException('Add a caption.');
    }
    final point = mapPointIfOptedIn(
      shareOnMap: shareOnMap,
      latitude: latitude,
      longitude: longitude,
    );
    if (shareOnMap && point == null) {
      throw StoreException('Choose a point on the map before sharing GPS.');
    }
    final post = CommunityPost(
      id: _id('post'),
      authorId: user.id,
      imageAsset: imageAsset,
      caption: caption.trim(),
      city: place.city,
      createdAt: _clock(),
      productId: productId,
      topic: postTopics.contains(topic) ? topic : 'story',
      latitude: point?.latitude,
      longitude: point?.longitude,
    );
    posts.insert(0, post);
    notifyListeners();
    return post;
  }

  void report({
    required String targetType,
    required String targetId,
    required String reason,
  }) {
    final user = _requireSession();
    reports.add(
      ContentReport(
        id: _id('report'),
        reporterId: user.id,
        targetType: targetType,
        targetId: targetId,
        reason: reason.trim(),
      ),
    );
    notifyListeners();
  }

  void addToCart(String productId) {
    final user = _requireSession();
    final cart = carts.putIfAbsent(user.id, () => []);
    final existing = cart.cast<CartRequest?>().firstWhere(
      (line) => line!.productId == productId,
      orElse: () => null,
    );
    if (existing == null) {
      cart.add(CartRequest(productId: productId, quantity: 1));
    } else {
      final index = cart.indexOf(existing);
      cart[index] = CartRequest(
        productId: productId,
        quantity: existing.quantity + 1,
      );
    }
    notifyListeners();
  }

  void setCartQuantity(String productId, int quantity) {
    final user = _requireSession();
    final cart = carts[user.id];
    if (cart == null) return;
    cart.removeWhere((line) => line.productId == productId);
    if (quantity > 0) {
      cart.add(CartRequest(productId: productId, quantity: quantity));
    }
    notifyListeners();
  }

  void toggleWishlist(String productId) {
    _requireSession();
    final key = '${session!.id}|$productId';
    if (!wishlist.add(key)) wishlist.remove(key);
    notifyListeners();
  }

  List<CartRequest> cartFor(String userId) =>
      List.unmodifiable(carts[userId] ?? const []);

  CustomerOrder placeOrder({required String shipTo, int? clientSubtotalIdr}) {
    final user = _requireSession();
    if (!user.emailVerified) {
      throw StoreException('Verify your email before ordering.');
    }
    final destination = shipTo.trim();
    if (destination.length < 3) {
      throw StoreException('Add a shipping address.');
    }
    final quote = quoteCart(
      lines: cartFor(user.id),
      catalog: catalog,
      clientSubtotalIdr: clientSubtotalIdr,
    );
    final order = CustomerOrder(
      id: _id('SS'),
      userId: user.id,
      lines: quote.lines,
      subtotalIdr: quote.subtotalIdr,
      status: statusForNewOrder(),
      createdAt: _clock(),
      shipTo: destination,
    );
    if (clientMayMarkOrderPaid()) {
      order.status = OrderStatus.paid;
    }
    orders.add(order);
    carts[user.id] = [];
    notices.add(
      AppNotice(
        id: _id('note'),
        userId: user.id,
        title: 'Order received',
        body: '${order.id} is awaiting payment. It is not marked paid.',
        createdAt: _clock(),
      ),
    );
    notifyListeners();
    return order;
  }

  List<OwnershipRecord> verifiedCollection(String userId) {
    return ownership
        .where(
          (record) =>
              record.ownerId == userId &&
              record.status == OwnershipStatus.verified,
        )
        .toList();
  }

  void requestSelfVerification(String productId) {
    if (clientMayVerifyOwnership()) {
      throw StoreException('Unexpected client verification path.');
    }
    throw StoreException(
      'Verified ownership comes from an eligible purchase or an authorized review.',
    );
  }

  List<Conversation> conversationsFor(String userId) {
    return conversations
        .where((conversation) => conversation.participantIds.contains(userId))
        .toList();
  }

  void sendMessage(String conversationId, String body) {
    final user = _requireSession();
    final conversation = conversations.cast<Conversation?>().firstWhere(
      (item) => item!.id == conversationId,
      orElse: () => null,
    );
    if (conversation == null ||
        !conversation.participantIds.contains(user.id)) {
      throw StoreException('That conversation is not available to you.');
    }
    final otherId = conversation.participantIds.cast<String?>().firstWhere(
      (id) => id != user.id,
      orElse: () => null,
    );
    if (otherId != null && _blocked(user.id, otherId)) {
      throw StoreException('Messaging is unavailable for this member.');
    }
    final text = body.trim();
    if (text.isEmpty) throw StoreException('Write a message first.');
    conversation.messages.add(
      DirectMessage(
        id: _id('msg'),
        senderId: user.id,
        body: text,
        sentAt: _clock(),
      ),
    );
    notifyListeners();
  }

  void markConversationRead(String conversationId) {
    final user = _requireSession();
    final conversation = conversations.cast<Conversation?>().firstWhere(
      (item) => item!.id == conversationId,
      orElse: () => null,
    );
    if (conversation == null ||
        !conversation.participantIds.contains(user.id)) {
      throw StoreException('That conversation is not available to you.');
    }
    for (final message in conversation.messages) {
      if (message.senderId != user.id) message.read = true;
    }
    notifyListeners();
  }

  void blockUser(String otherId) {
    final user = _requireSession();
    if (otherId == user.id) {
      throw StoreException('You cannot block yourself.');
    }
    blocks.add('${user.id}|$otherId');
    notifyListeners();
  }

  bool _blocked(String a, String b) =>
      blocks.contains('$a|$b') || blocks.contains('$b|$a');

  int loyaltyBalance(String userId) => 0;

  void redeemPoints(int points) {
    _requireSession();
    if (points <= 0 || loyaltyBalance(session!.id) >= 0) {
      throw StoreException('Point rules are not defined.');
    }
  }

  void markOrderPaid(String orderId) {
    _requireSession();
    throw StoreException(
      'Payment status for $orderId is confirmed only by the payment provider.',
    );
  }

  void moderateRemovePost(String postId) {
    final user = _requireSession();
    if (!user.adminClaim) {
      throw StoreException('Moderation requires an administrator claim.');
    }
    final post = _post(postId);
    posts.remove(post);
    auditLog.add('remove-post ${post.id} by ${user.id}');
    notifyListeners();
  }

  OwnershipRecord _ownedVerified(String ownershipId, String userId) {
    final record = ownership.cast<OwnershipRecord?>().firstWhere(
      (item) => item!.id == ownershipId,
      orElse: () => null,
    );
    if (record == null || record.ownerId != userId) {
      throw StoreException('That piece is not in your verified collection.');
    }
    if (record.status != OwnershipStatus.verified) {
      throw StoreException('Only a verified piece can be offered.');
    }
    return record;
  }

  ResaleListing listForResale(String ownershipId, String note) {
    final user = _requireSession();
    final record = _ownedVerified(ownershipId, user.id);
    final open = listings.any(
      (listing) =>
          listing.ownershipId == ownershipId && listing.status == 'open',
    );
    if (open) {
      throw StoreException('This piece already has an open listing.');
    }
    final listing = ResaleListing(
      id: _id('listing'),
      ownershipId: record.id,
      sellerId: user.id,
      productId: record.productId,
      note: note.trim(),
    );
    listings.add(listing);
    notifyListeners();
    return listing;
  }

  void expressResaleInterest(String listingId) {
    final user = _requireSession();
    final listing = listings.cast<ResaleListing?>().firstWhere(
      (item) => item!.id == listingId,
      orElse: () => null,
    );
    if (listing == null || listing.status != 'open') {
      throw StoreException('That listing is not open.');
    }
    if (listing.sellerId == user.id) {
      throw StoreException('You already hold this piece.');
    }
    interests.add(
      ResaleInterest(
        id: _id('interest'),
        listingId: listing.id,
        buyerId: user.id,
      ),
    );
    notices.add(
      AppNotice(
        id: _id('note'),
        userId: listing.sellerId,
        title: 'Resale interest',
        body:
            'A member asked about listing ${listing.id}. Ownership is unchanged.',
        createdAt: _clock(),
        targetType: 'listing',
        targetId: listing.id,
      ),
    );
    notifyListeners();
  }

  GiftRequest requestGift(String ownershipId, String recipientUsername) {
    final user = _requireSession();
    final record = _ownedVerified(ownershipId, user.id);
    final handle = recipientUsername.trim().toLowerCase();
    final recipient = users.values.cast<AppUser?>().firstWhere(
      (item) => item!.username == handle,
      orElse: () => null,
    );
    if (recipient == null) throw StoreException('Recipient not found.');
    if (recipient.id == user.id) {
      throw StoreException('Choose another member.');
    }
    final gift = GiftRequest(
      id: _id('gift'),
      ownershipId: record.id,
      fromUserId: user.id,
      toUserId: recipient.id,
    );
    gifts.add(gift);
    notices.add(
      AppNotice(
        id: _id('note'),
        userId: recipient.id,
        title: 'Gift request',
        body:
            '${user.displayName} offered a piece. Acceptance does not transfer it yet.',
        createdAt: _clock(),
        targetType: 'gift',
        targetId: gift.id,
      ),
    );
    notifyListeners();
    return gift;
  }

  void acceptGift(String giftId) {
    final user = _requireSession();
    final gift = gifts.cast<GiftRequest?>().firstWhere(
      (item) => item!.id == giftId,
      orElse: () => null,
    );
    if (gift == null || gift.toUserId != user.id) {
      throw StoreException('This gift is not addressed to you.');
    }
    if (gift.status != 'pending') {
      throw StoreException('This gift is no longer pending.');
    }
    gift.status = 'accepted_pending_server';
    notifyListeners();
  }

  void completeTransfer(String giftId) {
    _requireSession();
    throw StoreException(
      'Ownership transfer for $giftId is completed only by a trusted server operation.',
    );
  }

  AppUser _requireSession() {
    final current = session;
    if (current == null) throw StoreException('Sign in to continue.');
    return current;
  }

  CommunityPost _post(String id) {
    return posts.firstWhere(
      (post) => post.id == id,
      orElse: () => throw StoreException('Post not found.'),
    );
  }

  void _clearMutable() {
    users.clear();
    posts.clear();
    comments.clear();
    orders.clear();
    ownership.clear();
    conversations.clear();
    notices.clear();
    reports.clear();
    carts.clear();
    likes.clear();
    saves.clear();
    wishlist.clear();
    follows.clear();
    listings.clear();
    gifts.clear();
    interests.clear();
    auditLog.clear();
    blocks.clear();
    session = null;
  }

  Map<String, Object?> toSnapshot() {
    return {
      'version': 1,
      'seq': _seq,
      'sessionUserId': session?.id,
      'onboardingComplete': onboardingComplete,
      'darkMode': darkMode,
      'pendingVerificationCode': pendingVerificationCode,
      'pendingResetCode': pendingResetCode,
      'pendingResetUserId': pendingResetUserId,
      'users': users.values
          .map(
            (user) => {
              'id': user.id,
              'email': user.email,
              'displayName': user.displayName,
              'username': user.username,
              'passwordHash': user.passwordHash,
              'bio': user.bio,
              'city': user.city,
              'avatarAsset': user.avatarAsset,
              'emailVerified': user.emailVerified,
              'joinedAt': user.joinedAt.toIso8601String(),
            },
          )
          .toList(),
      'posts': posts
          .map(
            (post) => {
              'id': post.id,
              'authorId': post.authorId,
              'imageAsset': post.imageAsset,
              'caption': post.caption,
              'city': post.city,
              'createdAt': post.createdAt.toIso8601String(),
              'productId': post.productId,
              'shareCount': post.shareCount,
              'latitude': post.latitude,
              'longitude': post.longitude,
              'topic': post.topic,
            },
          )
          .toList(),
      'comments': comments
          .map(
            (comment) => {
              'id': comment.id,
              'postId': comment.postId,
              'authorId': comment.authorId,
              'body': comment.body,
              'createdAt': comment.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'orders': orders
          .map(
            (order) => {
              'id': order.id,
              'userId': order.userId,
              'subtotalIdr': order.subtotalIdr,
              'status': order.status.name,
              'createdAt': order.createdAt.toIso8601String(),
              'shipTo': order.shipTo,
              'lines': order.lines
                  .map(
                    (line) => {
                      'productId': line.productId,
                      'name': line.name,
                      'quantity': line.quantity,
                      'unitPriceIdr': line.unitPriceIdr,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'ownership': ownership
          .map(
            (record) => {
              'id': record.id,
              'productId': record.productId,
              'ownerId': record.ownerId,
              'source': record.source.name,
              'status': record.status.name,
              'since': record.since.toIso8601String(),
              'orderId': record.orderId,
            },
          )
          .toList(),
      'conversations': conversations
          .map(
            (conversation) => {
              'id': conversation.id,
              'participantIds': conversation.participantIds,
              'messages': conversation.messages
                  .map(
                    (message) => {
                      'id': message.id,
                      'senderId': message.senderId,
                      'body': message.body,
                      'sentAt': message.sentAt.toIso8601String(),
                      'read': message.read,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'notices': notices
          .map(
            (notice) => {
              'id': notice.id,
              'userId': notice.userId,
              'title': notice.title,
              'body': notice.body,
              'createdAt': notice.createdAt.toIso8601String(),
              'targetType': notice.targetType,
              'targetId': notice.targetId,
            },
          )
          .toList(),
      'reports': reports
          .map(
            (report) => {
              'id': report.id,
              'reporterId': report.reporterId,
              'targetType': report.targetType,
              'targetId': report.targetId,
              'reason': report.reason,
            },
          )
          .toList(),
      'carts': carts.map(
        (userId, lines) => MapEntry(
          userId,
          lines
              .map(
                (line) => {
                  'productId': line.productId,
                  'quantity': line.quantity,
                },
              )
              .toList(),
        ),
      ),
      'likes': likes.toList(),
      'saves': saves.toList(),
      'wishlist': wishlist.toList(),
      'follows': follows.toList(),
      'blocks': blocks.toList(),
      'listings': listings
          .map(
            (listing) => {
              'id': listing.id,
              'ownershipId': listing.ownershipId,
              'sellerId': listing.sellerId,
              'productId': listing.productId,
              'note': listing.note,
              'status': listing.status,
            },
          )
          .toList(),
      'gifts': gifts
          .map(
            (gift) => {
              'id': gift.id,
              'ownershipId': gift.ownershipId,
              'fromUserId': gift.fromUserId,
              'toUserId': gift.toUserId,
              'status': gift.status,
            },
          )
          .toList(),
      'interests': interests
          .map(
            (interest) => {
              'id': interest.id,
              'listingId': interest.listingId,
              'buyerId': interest.buyerId,
            },
          )
          .toList(),
      'auditLog': auditLog,
    };
  }

  void applySnapshot(Map<String, Object?> data) {
    if (data['version'] != 1) {
      throw const FormatException('Unsupported snapshot.');
    }
    final nextUsers = <String, AppUser>{};
    for (final item in _mapList(data['users'])) {
      final user = _userFromMap(item);
      nextUsers[user.id] = user;
    }
    final nextPosts = _mapList(data['posts']).map(_postFromMap).toList();
    final nextComments = _mapList(data['comments'])
        .map(_commentFromMap)
        .toList();
    final nextOrders = _mapList(data['orders']).map(_orderFromMap).toList();
    final nextOwnership = _mapList(data['ownership'])
        .map(_ownershipFromMap)
        .toList();
    final nextConversations = _mapList(data['conversations'])
        .map(_conversationFromMap)
        .toList();
    final nextNotices = _mapList(data['notices']).map(_noticeFromMap).toList();
    final nextReports = _mapList(data['reports']).map(_reportFromMap).toList();
    final nextListings = _mapList(data['listings'])
        .map(_listingFromMap)
        .toList();
    final nextGifts = _mapList(data['gifts']).map(_giftFromMap).toList();
    final nextInterests = _mapList(data['interests'])
        .map(_interestFromMap)
        .toList();
    final nextCarts = <String, List<CartRequest>>{};
    final rawCarts = data['carts'];
    if (rawCarts is Map) {
      rawCarts.forEach((key, value) {
        nextCarts['$key'] = _mapList(value)
            .map(
              (line) => CartRequest(
                productId: _text(line['productId']),
                quantity: _int(line['quantity']),
              ),
            )
            .toList();
      });
    }
    users
      ..clear()
      ..addAll(nextUsers);
    posts
      ..clear()
      ..addAll(nextPosts);
    comments
      ..clear()
      ..addAll(nextComments);
    orders
      ..clear()
      ..addAll(nextOrders);
    ownership
      ..clear()
      ..addAll(nextOwnership);
    conversations
      ..clear()
      ..addAll(nextConversations);
    notices
      ..clear()
      ..addAll(nextNotices);
    reports
      ..clear()
      ..addAll(nextReports);
    listings
      ..clear()
      ..addAll(nextListings);
    gifts
      ..clear()
      ..addAll(nextGifts);
    interests
      ..clear()
      ..addAll(nextInterests);
    carts
      ..clear()
      ..addAll(nextCarts);
    likes
      ..clear()
      ..addAll(_stringSet(data['likes']));
    saves
      ..clear()
      ..addAll(_stringSet(data['saves']));
    wishlist
      ..clear()
      ..addAll(_stringSet(data['wishlist']));
    follows
      ..clear()
      ..addAll(_stringSet(data['follows']));
    blocks
      ..clear()
      ..addAll(_stringSet(data['blocks']));
    auditLog
      ..clear()
      ..addAll(_stringSet(data['auditLog']));
    final seq = data['seq'];
    if (seq is int && seq > _seq) _seq = seq;
    final sessionId = data['sessionUserId'];
    session = sessionId is String ? users[sessionId] : null;
    onboardingComplete = data['onboardingComplete'] == true;
    darkMode = data['darkMode'] == true;
    pendingVerificationCode = data['pendingVerificationCode'] as String?;
    pendingResetCode = data['pendingResetCode'] as String?;
    pendingResetUserId = data['pendingResetUserId'] as String?;
  }

  AppUser _userFromMap(Map<String, Object?> item) {
    return AppUser(
      id: _text(item['id']),
      email: _text(item['email']),
      displayName: _text(item['displayName']),
      username: _text(item['username']),
      passwordHash: _text(item['passwordHash']),
      bio: _text(item['bio'], fallback: ''),
      city: _text(item['city'], fallback: 'Denpasar'),
      avatarAsset: item['avatarAsset'] as String?,
      emailVerified: item['emailVerified'] == true,
      adminClaim: false,
      joinedAt: _time(item['joinedAt']),
    );
  }

  CommunityPost _postFromMap(Map<String, Object?> item) {
    final id = _text(item['id']);
    final seeded = _seedPoints[id];
    final latitude = _optionalDouble(item['latitude']) ?? seeded?.latitude;
    final longitude = _optionalDouble(item['longitude']) ?? seeded?.longitude;
    final topic = item['topic'];
    return CommunityPost(
      id: id,
      authorId: _text(item['authorId']),
      imageAsset: _text(item['imageAsset']),
      caption: _text(item['caption']),
      city: _text(item['city']),
      createdAt: _time(item['createdAt']),
      productId: item['productId'] as String?,
      shareCount: _int(item['shareCount']),
      latitude: latitude,
      longitude: longitude,
      topic: topic is String && postTopics.contains(topic) ? topic : 'story',
    );
  }

  PostComment _commentFromMap(Map<String, Object?> item) {
    return PostComment(
      id: _text(item['id']),
      postId: _text(item['postId']),
      authorId: _text(item['authorId']),
      body: _text(item['body']),
      createdAt: _time(item['createdAt']),
    );
  }

  CustomerOrder _orderFromMap(Map<String, Object?> item) {
    return CustomerOrder(
      id: _text(item['id']),
      userId: _text(item['userId']),
      lines: _mapList(item['lines'])
          .map(
            (line) => QuotedLine(
              productId: _text(line['productId']),
              name: _text(line['name']),
              quantity: _int(line['quantity']),
              unitPriceIdr: _int(line['unitPriceIdr']),
            ),
          )
          .toList(),
      subtotalIdr: _int(item['subtotalIdr']),
      status: OrderStatus.values.byName(_text(item['status'])),
      createdAt: _time(item['createdAt']),
      shipTo: _text(item['shipTo']),
    );
  }

  OwnershipRecord _ownershipFromMap(Map<String, Object?> item) {
    return OwnershipRecord(
      id: _text(item['id']),
      productId: _text(item['productId']),
      ownerId: _text(item['ownerId']),
      source: OwnershipSource.values.byName(_text(item['source'])),
      status: OwnershipStatus.values.byName(_text(item['status'])),
      since: _time(item['since']),
      orderId: item['orderId'] as String?,
    );
  }

  Conversation _conversationFromMap(Map<String, Object?> item) {
    final participants = item['participantIds'];
    if (participants is! List) {
      throw const FormatException('Conversation participants are missing.');
    }
    return Conversation(
      id: _text(item['id']),
      participantIds: participants.map((id) => '$id').toList(),
      messages: _mapList(item['messages'])
          .map(
            (message) => DirectMessage(
              id: _text(message['id']),
              senderId: _text(message['senderId']),
              body: _text(message['body']),
              sentAt: _time(message['sentAt']),
              read: message['read'] == true,
            ),
          )
          .toList(),
    );
  }

  AppNotice _noticeFromMap(Map<String, Object?> item) {
    return AppNotice(
      id: _text(item['id']),
      userId: _text(item['userId']),
      title: _text(item['title']),
      body: _text(item['body']),
      createdAt: _time(item['createdAt']),
      targetType: item['targetType'] as String?,
      targetId: item['targetId'] as String?,
    );
  }

  ContentReport _reportFromMap(Map<String, Object?> item) {
    return ContentReport(
      id: _text(item['id']),
      reporterId: _text(item['reporterId']),
      targetType: _text(item['targetType']),
      targetId: _text(item['targetId']),
      reason: _text(item['reason']),
    );
  }

  ResaleListing _listingFromMap(Map<String, Object?> item) {
    return ResaleListing(
      id: _text(item['id']),
      ownershipId: _text(item['ownershipId']),
      sellerId: _text(item['sellerId']),
      productId: _text(item['productId']),
      note: _text(item['note'], fallback: ''),
    )..status = _text(item['status'], fallback: 'open');
  }

  GiftRequest _giftFromMap(Map<String, Object?> item) {
    return GiftRequest(
      id: _text(item['id']),
      ownershipId: _text(item['ownershipId']),
      fromUserId: _text(item['fromUserId']),
      toUserId: _text(item['toUserId']),
    )..status = _text(item['status'], fallback: 'pending');
  }

  ResaleInterest _interestFromMap(Map<String, Object?> item) {
    return ResaleInterest(
      id: _text(item['id']),
      listingId: _text(item['listingId']),
      buyerId: _text(item['buyerId']),
    );
  }

  List<Map<String, Object?>> _mapList(Object? value) {
    if (value is! List) throw const FormatException('Expected a list.');
    return value.map((item) {
      if (item is! Map) throw const FormatException('Expected an object.');
      return Map<String, Object?>.from(item);
    }).toList();
  }

  Set<String> _stringSet(Object? value) {
    if (value is! List) throw const FormatException('Expected a list.');
    return value.map((item) => '$item').toSet();
  }

  String _text(Object? value, {String? fallback}) {
    if (value is String) return value;
    if (fallback != null) return fallback;
    throw const FormatException('Expected text.');
  }

  int _int(Object? value) {
    if (value is int) return value;
    throw const FormatException('Expected a number.');
  }

  double? _optionalDouble(Object? value) {
    if (value is num) return value.toDouble();
    return null;
  }

  DateTime _time(Object? value) {
    if (value is! String) throw const FormatException('Expected a time.');
    return DateTime.parse(value);
  }
}
