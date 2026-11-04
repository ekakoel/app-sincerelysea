import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets.dart';
import '../../data/local_store.dart';
import '../../domain/policies.dart';
import '../auth/auth_pages.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final products = store.catalog.values.toList();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              const BrandWordmark(width: 150),
              const Spacer(),
              IconButton(
                key: const Key('open-cart'),
                tooltip: 'Cart',
                onPressed: () {
                  if (store.session == null) {
                    openLogin(context);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CartPage()),
                  );
                },
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Shop', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Pre-order. Prices are catalog prices, not a client total.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const AppEmptyState(
              title: 'No products',
              body: 'The catalog is empty.',
            )
          else
            for (final product in products) ...[
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProductPage(productId: product.id),
                  ),
                ),
                child: PhotoFrame(asset: product.imageAsset, height: 220),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${formatIdr(product.priceIdr)} · ${product.preorder ? 'Pre-order' : 'Available'}',
              ),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}

class ProductPage extends StatelessWidget {
  const ProductPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final product = store.catalog[productId];
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppEmptyState(
          title: 'Product unavailable',
          body: 'This piece is not in the catalog.',
        ),
      );
    }
    final wished =
        store.session != null &&
        store.wishlist.contains('${store.session!.id}|${product.id}');
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PhotoFrame(asset: product.imageAsset, height: 280),
          const SizedBox(height: 16),
          Text(
            formatIdr(product.priceIdr),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(product.material),
          const SizedBox(height: 4),
          Text('Variant · ${product.variant}'),
          const SizedBox(height: 4),
          Text(
            product.preorder
                ? 'Pre-order · ${product.fulfillment}'
                : product.fulfillment,
          ),
          const SizedBox(height: 8),
          const Text(
            'The photograph may be a stand-in until official product photography is supplied. The price above is the catalog price.',
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Add to cart',
            onPressed: () {
              if (store.session == null) {
                openLogin(context);
                return;
              }
              runStore(context, () => store.addToCart(product.id));
              showAppFeedback(context, 'Added to cart.');
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              if (store.session == null) {
                openLogin(context);
                return;
              }
              store.toggleWishlist(product.id);
            },
            child: Text(wished ? 'Remove from wishlist' : 'Save to wishlist'),
          ),
        ],
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final user = store.session;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: const AppEmptyState(
          title: 'Sign in',
          body: 'A cart belongs to an account.',
        ),
      );
    }
    final lines = store.cartFor(user.id);
    OrderQuote? quote;
    String? quoteError;
    try {
      quote = quoteCart(
        lines: lines,
        catalog: store.catalog,
        clientSubtotalIdr: 1,
      );
    } on QuoteException catch (error) {
      quoteError = error.message;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (lines.isEmpty)
            const AppEmptyState(
              title: 'Cart is empty',
              body: 'Add a piece from the shop.',
            )
          else
            for (final line in lines)
              _CartLine(line: line, product: store.catalog[line.productId]),
          const SizedBox(height: 12),
          if (quote != null)
            Text('Catalog total ${formatIdr(quote.subtotalIdr)}'),
          if (quoteError != null) Text(quoteError),
          const SizedBox(height: 8),
          const Text(
            'A client-submitted total is ignored. Shipping is confirmed with the order, not invented here.',
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Checkout',
            onPressed: quote == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CheckoutPage(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.line, required this.product});

  final CartRequest line;
  final CatalogProduct? product;

  @override
  Widget build(BuildContext context) {
    final store = context.read<LocalAppStore>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product?.name ?? line.productId),
          Text(
            'Qty ${line.quantity} · ${product == null ? '' : formatIdr(product!.priceIdr)}',
          ),
          Row(
            children: [
              IconButton(
                onPressed: () =>
                    store.setCartQuantity(line.productId, line.quantity - 1),
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                onPressed: line.quantity >= 5
                    ? null
                    : () => store.setCartQuantity(
                        line.productId,
                        line.quantity + 1,
                      ),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _address = TextEditingController();
  String _method = 'Bank transfer';

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final user = store.session;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppEmptyState(
          title: 'Sign in',
          body: 'Checkout requires an account.',
        ),
      );
    }
    OrderQuote? quote;
    try {
      quote = quoteCart(
        lines: store.cartFor(user.id),
        catalog: store.catalog,
        clientSubtotalIdr: 0,
      );
    } on QuoteException {
      quote = null;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            user.displayName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(user.email),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Shipping address',
            controller: _address,
            fieldKey: const Key('ship-to'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Payment method'),
            items: const [
              DropdownMenuItem(
                value: 'Bank transfer',
                child: Text('Bank transfer'),
              ),
              DropdownMenuItem(
                value: 'Payment provider',
                child: Text('Payment provider — not connected'),
              ),
            ],
            onChanged: (value) => setState(() => _method = value ?? _method),
          ),
          const SizedBox(height: 12),
          if (quote != null)
            Text('Due ${formatIdr(quote.subtotalIdr)} via $_method')
          else
            const Text('The cart cannot be quoted.'),
          const SizedBox(height: 8),
          const Text('Submitting does not mark this order paid.'),
          const SizedBox(height: 16),
          AppButton(
            key: const Key('place-order'),
            label: 'Place pre-order',
            onPressed: quote == null
                ? null
                : () {
                    CustomerOrder? order;
                    try {
                      order = store.placeOrder(
                        shipTo: _address.text,
                        clientSubtotalIdr: 1,
                      );
                    } on StoreException catch (error) {
                      showAppFeedback(context, error.message);
                      return;
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => OrderReceivedPage(orderId: order!.id),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}

class OrderReceivedPage extends StatelessWidget {
  const OrderReceivedPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order received')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(orderId, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Status: Awaiting payment'),
            const SizedBox(height: 8),
            const Text(
              'This device cannot mark the order paid. Payment is confirmed only after a provider callback on the server.',
            ),
            const Spacer(),
            AppButton(
              label: 'View order',
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderDetailPage(orderId: orderId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    final order = store.orders.cast<CustomerOrder?>().firstWhere(
      (item) => item!.id == orderId,
      orElse: () => null,
    );
    if (order == null ||
        store.session == null ||
        (order.userId != store.session!.id && !store.session!.adminClaim)) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppEmptyState(
          title: 'Order unavailable',
          body: 'This order is not on your account.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(order.id)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            orderStatusLabel(order.status),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('Ship to ${order.shipTo}'),
          Text('Catalog total ${formatIdr(order.subtotalIdr)}'),
          const SizedBox(height: 12),
          for (final line in order.lines)
            Text(
              '${line.name} × ${line.quantity} · ${formatIdr(line.lineTotalIdr)}',
            ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              runStore(context, () => store.markOrderPaid(order.id));
            },
            child: const Text('I already paid'),
          ),
          const SizedBox(height: 8),
          Text(
            'That action is refused. ${orderStatusLabel(order.status)} stays until a trusted confirmation.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
