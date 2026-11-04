import 'package:flutter_test/flutter_test.dart';
import 'package:sincerelysea/domain/policies.dart';

void main() {
  const jane = CatalogProduct(
    id: 'jane-medium',
    name: 'Jane Medium',
    priceIdr: 1500000,
    imageAsset: 'assets/photos/jane.jpg',
    material: 'Cognac',
    preorder: true,
    fulfillment: '2–3 weeks',
  );

  test('quote uses the catalog and ignores a client total', () {
    final quote = quoteCart(
      lines: const [CartRequest(productId: 'jane-medium', quantity: 2)],
      catalog: const {'jane-medium': jane},
      clientSubtotalIdr: 1,
    );
    expect(quote.subtotalIdr, 3000000);
    expect(formatIdr(quote.subtotalIdr), 'Rp 3.000.000');
  });

  test('quote rejects an empty cart, unknown products, and bad quantities', () {
    expect(
      () => quoteCart(lines: const [], catalog: const {'jane-medium': jane}),
      throwsA(isA<QuoteException>()),
    );
    expect(
      () => quoteCart(
        lines: const [CartRequest(productId: 'missing', quantity: 1)],
        catalog: const {'jane-medium': jane},
      ),
      throwsA(isA<QuoteException>()),
    );
    expect(
      () => quoteCart(
        lines: const [CartRequest(productId: 'jane-medium', quantity: 6)],
        catalog: const {'jane-medium': jane},
      ),
      throwsA(isA<QuoteException>()),
    );
  });

  test('new orders are unpaid and clients cannot verify ownership', () {
    expect(statusForNewOrder(), OrderStatus.awaitingPayment);
    expect(clientMayMarkOrderPaid(), isFalse);
    expect(clientMayVerifyOwnership(), isFalse);
    expect(orderStatusLabel(OrderStatus.awaitingPayment), 'Awaiting payment');
  });

  test('GPS is kept only when the author opts in', () {
    expect(
      mapPointIfOptedIn(shareOnMap: false, latitude: -8.6, longitude: 115.2),
      isNull,
    );
    expect(
      mapPointIfOptedIn(shareOnMap: true, latitude: -8.6, longitude: 115.2),
      isNotNull,
    );
    expect(
      mapPointIfOptedIn(shareOnMap: true, latitude: 120, longitude: 10),
      isNull,
    );
    final quiet = communityHeat(
      likes: 0,
      comments: 0,
      saves: 0,
      shares: 0,
      age: const Duration(days: 30),
      followsAuthor: false,
      followsProduct: false,
      topic: 'story',
    );
    final talked = communityHeat(
      likes: 1,
      comments: 3,
      saves: 1,
      shares: 0,
      age: const Duration(hours: 2),
      followsAuthor: true,
      followsProduct: false,
      topic: 'care',
    );
    expect(talked, greaterThan(quiet));
    expect(
      mapDominance(talked, talked),
      greaterThan(mapDominance(quiet, talked)),
    );
  });

  test('captions stop at 15 characters and places stay at city level', () {
    expect(
      captionPreview('Jane, on the way to the studio'),
      'Jane, on the...read more',
    );
    expect(captionPreview('Short line'), 'Short line');
    expect(PublicPlace('Denpasar').isCityLevel, isTrue);
    expect(PublicPlace('Denpasar, -8.65').isCityLevel, isFalse);
    expect(PublicPlace('  ').isCityLevel, isFalse);
  });
}
