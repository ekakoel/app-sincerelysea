import 'package:flutter_test/flutter_test.dart';
import 'package:sincerelysea/data/local_store.dart';
import 'package:sincerelysea/domain/policies.dart';

void main() {
  test('registration cannot create an administrator', () {
    final store = LocalAppStore();
    store.register(
      email: 'new@sincerelysea.dev',
      password: 'correct-horse',
      displayName: 'New Member',
      username: 'newmember',
    );
    expect(store.session?.adminClaim, isFalse);
    expect(store.session?.passwordHash, isNot('correct-horse'));
    expect(store.pendingVerificationCode, '184206');
  });

  test('likes are unique and another member cannot delete a comment', () {
    final store = LocalAppStore();
    store.login(
      email: LocalAppStore.fixtureEmail,
      password: LocalAppStore.fixturePassword,
    );
    store.toggleLike('post-mira');
    store.toggleLike('post-mira');
    store.toggleLike('post-mira');
    expect(store.likeCount('post-mira'), 1);
    final comment = store.addComment('post-mira', 'The edge is clean.');
    store.logout();
    store.login(email: 'mira@sincerelysea.dev', password: 'not-a-login');
    expect(
      () => store.deleteOwnComment(comment.id),
      throwsA(isA<StoreException>()),
    );
    expect(store.commentCount('post-mira'), 1);
  });

  test('orders ignore a forged total and cannot be marked paid', () {
    final store = LocalAppStore();
    store.login(
      email: LocalAppStore.fixtureEmail,
      password: LocalAppStore.fixturePassword,
    );
    store.addToCart('viola-sling');
    final order = store.placeOrder(shipTo: 'Denpasar', clientSubtotalIdr: 1);
    expect(order.subtotalIdr, 830000);
    expect(order.status, OrderStatus.awaitingPayment);
    expect(() => store.markOrderPaid(order.id), throwsA(isA<StoreException>()));
    expect(order.status, OrderStatus.awaitingPayment);
    expect(store.cartFor('user-ayu'), isEmpty);
  });

  test('self verification and client transfer do not change ownership', () {
    final store = LocalAppStore();
    store.login(
      email: LocalAppStore.fixtureEmail,
      password: LocalAppStore.fixturePassword,
    );
    expect(
      () => store.requestSelfVerification('satchel'),
      throwsA(isA<StoreException>()),
    );
    expect(
      store.verifiedCollection('user-ayu').single.productId,
      'jane-medium',
    );
    final gift = store.requestGift('own-ayu-jane', 'mira');
    expect(store.verifiedCollection('user-ayu').single.ownerId, 'user-ayu');
    store.logout();
    store.login(email: 'mira@sincerelysea.dev', password: 'not-a-login');
    store.acceptGift(gift.id);
    expect(gift.status, 'accepted_pending_server');
    expect(
      store.ownership
          .singleWhere((record) => record.id == 'own-ayu-jane')
          .ownerId,
      'user-ayu',
    );
    expect(
      () => store.completeTransfer(gift.id),
      throwsA(isA<StoreException>()),
    );
  });

  test('private conversations and precise places are refused', () {
    final store = LocalAppStore();
    expect(store.conversationsFor('user-sari'), isEmpty);
    store.login(email: 'sari@sincerelysea.dev', password: 'not-a-login');
    expect(
      () => store.sendMessage('conv-ayu-mira', 'hello'),
      throwsA(isA<StoreException>()),
    );
    expect(
      () => store.publishPost(
        imageAsset: 'assets/photos/bali.jpg',
        caption: 'A precise pin',
        city: 'Denpasar, -8.6',
      ),
      throwsA(isA<StoreException>()),
    );
  });

  test('moderation and loyalty stay closed', () {
    final store = LocalAppStore();
    store.login(
      email: LocalAppStore.fixtureEmail,
      password: LocalAppStore.fixturePassword,
    );
    expect(
      () => store.moderateRemovePost('post-mira'),
      throwsA(isA<StoreException>()),
    );
    expect(store.posts.any((post) => post.id == 'post-mira'), isTrue);
    expect(store.loyaltyBalance('user-ayu'), 0);
    expect(() => store.redeemPoints(10), throwsA(isA<StoreException>()));
  });

  test(
    'a blocked member cannot receive a message and a reset replaces the hash',
    () {
      final store = LocalAppStore();
      store.login(
        email: LocalAppStore.fixtureEmail,
        password: LocalAppStore.fixturePassword,
      );
      store.blockUser('user-mira');
      expect(
        () => store.sendMessage('conv-ayu-mira', 'still there?'),
        throwsA(isA<StoreException>()),
      );
      store.requestPasswordReset(LocalAppStore.fixtureEmail);
      store.completePasswordReset(code: '392817', newPassword: 'next-password');
      store.logout();
      expect(
        () => store.login(
          email: LocalAppStore.fixtureEmail,
          password: LocalAppStore.fixturePassword,
        ),
        throwsA(isA<StoreException>()),
      );
      store.login(email: LocalAppStore.fixtureEmail, password: 'next-password');
      expect(store.session?.id, 'user-ayu');
    },
  );

  test('resale interest does not move the verified owner', () {
    final store = LocalAppStore();
    store.login(
      email: LocalAppStore.fixtureEmail,
      password: LocalAppStore.fixturePassword,
    );
    final listing = store.listForResale(
      'own-ayu-jane',
      'Open to the community',
    );
    store.logout();
    store.login(email: 'mira@sincerelysea.dev', password: 'not-a-login');
    store.expressResaleInterest(listing.id);
    expect(
      store.ownership
          .singleWhere((record) => record.id == 'own-ayu-jane')
          .ownerId,
      'user-ayu',
    );
    expect(listing.status, 'open');
  });
}
