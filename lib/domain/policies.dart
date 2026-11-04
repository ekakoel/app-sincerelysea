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

/// A city label is always public. A GPS point is separate and optional.
class PublicPlace {
  const PublicPlace(this.city);
  final String city;

  bool get isCityLevel => city.trim().isNotEmpty && !city.contains(',');
}

/// Coordinates the author chose to publish. Never a live device track.
class PostPoint {
  const PostPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

const cityCenters = <String, PostPoint>{
  'Denpasar': PostPoint(latitude: -8.6705, longitude: 115.2126),
  'Kuta': PostPoint(latitude: -8.7224, longitude: 115.1767),
  'Bedugul': PostPoint(latitude: -8.2750, longitude: 115.1667),
  'Ubud': PostPoint(latitude: -8.5069, longitude: 115.2625),
  'Sanur': PostPoint(latitude: -8.7080, longitude: 115.2620),
};

const postTopics = ['story', 'care', 'experience'];

String topicLabel(String topic) {
  switch (topic) {
    case 'care':
      return 'Care';
    case 'experience':
      return 'Experience';
    default:
      return 'Story';
  }
}

/// Drops coordinates unless the author opted in and both values are valid.
PostPoint? mapPointIfOptedIn({
  required bool shareOnMap,
  double? latitude,
  double? longitude,
}) {
  if (!shareOnMap || latitude == null || longitude == null) return null;
  final point = PostPoint(latitude: latitude, longitude: longitude);
  if (!point.isValid) return null;
  return point;
}

/// Ranks a story for the community, not for advertising.
/// Comments weigh more than likes so a conversation stays visible.
int communityHeat({
  required int likes,
  required int comments,
  required int saves,
  required int shares,
  required Duration age,
  required bool followsAuthor,
  required bool followsProduct,
  required String topic,
}) {
  final safeLikes = likes < 0 ? 0 : likes;
  final safeComments = comments < 0 ? 0 : comments;
  final safeSaves = saves < 0 ? 0 : saves;
  final safeShares = shares < 0 ? 0 : shares;
  final engagement =
      safeLikes * 3 + safeComments * 5 + safeSaves * 4 + safeShares * 2;
  final hours = age.isNegative ? 0 : age.inMinutes / 60.0;
  final recency = hours < 6
      ? 12
      : hours < 48
      ? 6
      : hours < 24 * 7
      ? 2
      : 0;
  final connection = (followsAuthor ? 8 : 0) + (followsProduct ? 6 : 0);
  final practice = topic == 'care' || topic == 'experience' ? 3 : 0;
  final talk = safeComments > 0 ? 4 : 0;
  return engagement + recency + connection + practice + talk;
}

/// 0.38 for a quiet pin, up to 1 for the most active story on the map.
double mapDominance(int heat, int maxHeat) {
  if (maxHeat <= 0) return 0.42;
  final ratio = (heat / maxHeat).clamp(0.0, 1.0);
  return 0.38 + ratio * 0.62;
}

int productPopularityScore({
  required int posts,
  required int likes,
  required int comments,
  required int saves,
  required int orders,
}) {
  final safePosts = posts < 0 ? 0 : posts;
  final safeLikes = likes < 0 ? 0 : likes;
  final safeComments = comments < 0 ? 0 : comments;
  final safeSaves = saves < 0 ? 0 : saves;
  final safeOrders = orders < 0 ? 0 : orders;
  return safePosts * 2 +
      safeLikes * 3 +
      safeComments * 4 +
      safeSaves * 3 +
      safeOrders * 5;
}

String formatPoint(double latitude, double longitude) {
  return '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
}

String captionPreview(String text, {int maxChars = 15}) {
  final trimmed = text.trim();
  if (trimmed.length <= maxChars) return trimmed;
  var raw = trimmed.substring(0, maxChars);
  final next = trimmed[maxChars];
  final cutMidWord =
      raw.isNotEmpty && _isWordChar(raw[raw.length - 1]) && _isWordChar(next);
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
