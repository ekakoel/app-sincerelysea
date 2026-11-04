import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sincerelysea/data/local_store.dart';
import 'package:sincerelysea/domain/policies.dart';

void main() {
  test('a restarted device keeps the account and the unpaid order', () async {
    final memory = MemorySnapshotPersistence();
    final first = LocalAppStore(persistence: memory);
    first.register(
      email: 'beta@sincerelysea.dev',
      password: 'beta-user',
      displayName: 'Beta',
      username: 'beta',
    );
    first.confirmEmail('184206');
    first.addToCart('viola-sling');
    final order = first.placeOrder(shipTo: 'Denpasar', clientSubtotalIdr: 1);

    final second = LocalAppStore(persistence: memory);
    await second.restore();
    expect(second.restored, isTrue);
    second.login(email: 'beta@sincerelysea.dev', password: 'beta-user');
    final restored = second.orders.singleWhere((item) => item.id == order.id);
    expect(restored.status, OrderStatus.awaitingPayment);
    expect(restored.subtotalIdr, 830000);
    expect(second.session!.adminClaim, isFalse);
    expect(second.markOrderPaid, isNotNull);
    expect(
      () => second.markOrderPaid(restored.id),
      throwsA(isA<StoreException>()),
    );
    expect(restored.status, OrderStatus.awaitingPayment);
  });

  test('a edited snapshot cannot grant administrator access', () async {
    final memory = MemorySnapshotPersistence();
    final first = LocalAppStore(persistence: memory);
    first.completeOnboarding();
    final saved = jsonDecode(memory.value!) as Map<String, dynamic>;
    final users = saved['users'] as List<dynamic>;
    (users.first as Map<String, dynamic>)['adminClaim'] = true;
    memory.value = jsonEncode(saved);

    final second = LocalAppStore(persistence: memory);
    await second.restore();
    expect(
      second.users.values.every((user) => user.adminClaim == false),
      isTrue,
    );
    expect(second.onboardingComplete, isTrue);
  });

  test(
    'deleting an account removes the profile and keeps the order record',
    () {
      final store = LocalAppStore();
      store.login(
        email: LocalAppStore.fixtureEmail,
        password: LocalAppStore.fixturePassword,
      );
      store.deleteAccount();
      expect(store.session, isNull);
      expect(
        store.users.values.any(
          (user) => user.email == LocalAppStore.fixtureEmail,
        ),
        isFalse,
      );
      expect(store.orders.any((order) => order.id == 'SS-2025-014'), isTrue);
    },
  );
}
