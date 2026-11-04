import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../data/local_store.dart';
import '../features/collection/collection_pages.dart';
import '../features/discover/discover_page.dart';
import '../features/feed/feed_pages.dart';
import '../features/profile/profile_pages.dart';
import '../features/shop/shop_pages.dart';

class AppThemeBridge {
  static ThemeData get light => AppTheme.light();
  static ThemeData get dark => AppTheme.dark();
}

class AppGate extends StatefulWidget {
  const AppGate({super.key, this.splashDuration = const Duration(milliseconds: 1200)});

  final Duration splashDuration;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool _splash = true;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = context.read<LocalAppStore>();
    if (store.splashSeen) {
      _splash = false;
      return;
    }
    if (_scheduled) return;
    _scheduled = true;
    Future<void>.delayed(widget.splashDuration, () {
      if (!mounted) return;
      context.read<LocalAppStore>().markSplashSeen();
      setState(() => _splash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LocalAppStore>();
    if (_splash) return const SplashPage();
    if (!store.onboardingComplete) return const OnboardingPage();
    return const CustomerShell();
  }
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandWordmark(onDark: true, width: 220),
            SizedBox(height: 16),
            Text(
              'Stories in every stitch',
              style: TextStyle(color: AppColors.gray500, letterSpacing: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    (
      title: 'SincerelySea Community',
      body: 'A place for the stories that travel with a piece of leather. Not a generic feed.',
      asset: 'assets/photos/atelier.jpg',
    ),
    (
      title: 'Discover Stories and Experiences',
      body: 'Find community posts by city. A live location is never published for you.',
      asset: 'assets/photos/bali.jpg',
    ),
    (
      title: 'Shop, Collect, and Connect',
      body: 'Pre-order a bag, then keep a verified record of what you actually own.',
      asset: 'assets/photos/jane.jpg',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => context.read<LocalAppStore>().completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: BrandWordmark(width: 132),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _finish, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              page.asset,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(page.title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(page.body),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Text('${_index + 1} / ${_pages.length}', style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  if (_index > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('Back'),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: last
                        ? _finish
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOut,
                            ),
                    child: Text(last ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomePage(),
      DiscoverPage(),
      ShopPage(),
      CollectionPage(),
      ProfilePage(),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.place_outlined), selectedIcon: Icon(Icons.place), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag), label: 'Shop'),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Collection',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
