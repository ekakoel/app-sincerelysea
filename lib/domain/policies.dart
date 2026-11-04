/// Business rules that must not depend on the client UI.
/// Cloud Functions mirror [quoteCart]. Client-submitted money and
/// ownership flags are ignored.
library;

enum OrderStatus {
  pending,
  awaitingPayment,
  paid,
  processing,
  readyToShip,
  shipped,
  delivered,
  cancelled,
  failed,
  refunded,
}

enum OwnershipSource { eligiblePurchase, adminReview }

enum OwnershipStatus { pendingReview, verified, transferred }

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    required this.priceIdr,
    required this.imageAsset,
    required this.material,
    required this.preorder,
    required this.fulfillment,
    this.variant = 'Default',
  });

  final String id;
  final String name;
  final int priceIdr;
  final String imageAsset;
  final String material;
  final bool preorder;
  final String fulfillment;
  final String variant;
}

class CartRequest {
  const CartRequest({required this.productId, required this.quantity});

  final String productId;
  final int quantity;
}

class QuotedLine {
  const QuotedLine({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPriceIdr,
  });

  final String productId;
  final String name;
  final int quantity;
  final int unitPriceIdr;

  int get lineTotalIdr => unitPriceIdr * quantity;
}

class OrderQuote {
  const OrderQuote({required this.lines, required this.subtotalIdr});

  final List<QuotedLine> lines;
  final int subtotalIdr;
}

class QuoteException implements Exception {
  QuoteException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Prices always come from [catalog]. [clientSubtotalIdr] is discarded.
OrderQuote quoteCart({
  required List<CartRequest> lines,
  required Map<String, CatalogProduct> catalog,
  int? clientSubtotalIdr,
}) {
  if (lines.isEmpty) {
    throw QuoteException('Cart is empty.');
  }
  final quoted = <QuotedLine>[];
  for (final line in lines) {
    if (line.quantity < 1 || line.quantity > 5) {
      throw QuoteException('Quantity must be between 1 and 5.');
    }
    final product = catalog[line.productId];
    if (product == null) {
      throw QuoteException('Unknown product ${line.productId}.');
    }
    quoted.add(
      QuotedLine(
        productId: product.id,
        name: product.name,
        quantity: line.quantity,
        unitPriceIdr: product.priceIdr,
      ),
    );
  }
  final subtotal = quoted.fold<int>(0, (sum, line) => sum + line.lineTotalIdr);
  // Touch the client value so callers cannot silently depend on it.
  if (clientSubtotalIdr != null && clientSubtotalIdr != subtotal) {
    // Intentionally ignored. The returned quote uses catalog prices.
  }
  return OrderQuote(lines: quoted, subtotalIdr: subtotal);
}

String orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'Pending';
    case OrderStatus.awaitingPayment:
      return 'Awaiting payment';
    case OrderStatus.paid:
      return 'Paid';
    case OrderStatus.processing:
      return 'Processing';
    case OrderStatus.readyToShip:
      return 'Ready to ship';
    case OrderStatus.shipped:
      return 'Shipped';
    case OrderStatus.delivered:
      return 'Delivered';
    case OrderStatus.cancelled:
      return 'Cancelled';
    case OrderStatus.failed:
      return 'Failed';
    case OrderStatus.refunded:
      return 'Refunded';
  }
}

/// A newly submitted order is never paid. Payment requires a provider callback.
OrderStatus statusForNewOrder() => OrderStatus.awaitingPayment;

bool clientMayMarkOrderPaid() => false;

bool clientMayVerifyOwnership() => false;

/// Public posts expose a city label only. Precise coordinates are not a field.
class PublicPlace {
  const PublicPlace(this.city);
  final String city;

  bool get isCityLevel => city.trim().isNotEmpty && !city.contains(',');
}

String captionPreview(String text, {int maxChars = 15}) {
  final trimmed = text.trim();
  if (trimmed.length <= maxChars) return trimmed;
  var raw = trimmed.substring(0, maxChars);
  final next = trimmed[maxChars];
  final cutMidWord = raw.isNotEmpty &&
      _isWordChar(raw[raw.length - 1]) &&
      _isWordChar(next);
  if (cutMidWord) {
    final space = raw.lastIndexOf(' ');
    if (space >= 8) raw = raw.substring(0, space);
  }
  return '${raw.trimRight()}...read more';
}

bool _isWordChar(String char) {
  final code = char.codeUnitAt(0);
  return (code >= 48 && code <= 57) ||
      (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122);
}

String formatIdr(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'Rp $buffer';
}
