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

  test('captions stop at 15 characters and places stay at city level', () {
    expect(captionPreview('Jane, on the way to the studio'), 'Jane, on the...read more');
    expect(captionPreview('Short line'), 'Short line');
    expect(PublicPlace('Denpasar').isCityLevel, isTrue);
    expect(PublicPlace('Denpasar, -8.65').isCityLevel, isFalse);
    expect(PublicPlace('  ').isCityLevel, isFalse);
  });
}
