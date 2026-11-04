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
  });

  final String id;
  final String authorId;
  final String imageAsset;
  final String caption;
  final String city;
  final DateTime createdAt;
  final String? productId;
  int shareCount;
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

/// Local adapter used until Firebase credentials are configured.
/// Passwords are hashed and never written to Firestore.
/// Administrator access cannot be granted from this client.
class LocalAppStore extends ChangeNotifier {
  LocalAppStore({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _seed();
  }

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
      ),
      CommunityPost(
        id: 'post-sari',
        authorId: sari.id,
        imageAsset: 'assets/photos/life.jpg',
        caption: 'Morning light, the strap still new',
        city: 'Kuta',
        createdAt: _clock().subtract(const Duration(hours: 5)),
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
      ),
      CommunityPost(
        id: 'post-ayu',
        authorId: ayu.id,
        imageAsset: 'assets/photos/bali.jpg',
        caption: 'Morning at the lake, shared as a city',
        city: 'Bedugul',
        createdAt: _clock().subtract(const Duration(days: 2)),
        productId: 'jane-medium',
      ),
      CommunityPost(
        id: 'post-atelier',
        authorId: mira.id,
        imageAsset: 'assets/photos/atelier.jpg',
        caption: 'Stitching the strap before it leaves',
        city: 'Denpasar',
        createdAt: _clock().subtract(const Duration(days: 4)),
      ),
      CommunityPost(
        id: 'post-sand',
        authorId: sari.id,
        imageAsset: 'assets/photos/sand.jpg',
        caption: 'Sand leather in late light',
        city: 'Kuta',
        createdAt: _clock().subtract(const Duration(days: 6)),
        productId: 'jane-sand',
      ),
    ]);

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

  List<CommunityPost> feedPage({required int offset, int limit = 4}) {
    final sorted = [...posts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (offset >= sorted.length) return const [];
    final end = offset + limit > sorted.length ? sorted.length : offset + limit;
    return sorted.sublist(offset, end);
  }

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
    users.remove(user.id);
    posts.removeWhere((post) => post.authorId == user.id);
    comments.removeWhere((comment) => comment.authorId == user.id);
    carts.remove(user.id);
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
  }) {
    final user = _requireSession();
    if (!user.emailVerified) {
      throw StoreException('Verify your email before publishing.');
    }
    final place = PublicPlace(city.trim());
    if (!place.isCityLevel) {
      throw StoreException('Share a city, not a pin.');
    }
    if (caption.trim().length < 3) {
      throw StoreException('Add a caption.');
    }
    final post = CommunityPost(
      id: _id('post'),
      authorId: user.id,
      imageAsset: imageAsset,
      caption: caption.trim(),
      city: place.city,
      createdAt: _clock(),
      productId: productId,
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
}
