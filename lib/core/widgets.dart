import 'package:flutter/material.dart';

import '../data/local_store.dart';
import 'theme.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.bottom,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final Widget child;
  final Widget? bottom;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(padding: padding, child: child),
          ),
          ?bottom,
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

class AppSection extends StatelessWidget {
  const AppSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: 52,
      width: expand ? double.infinity : null,
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
    return button;
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.maxLines = 1,
    this.fieldKey,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final int maxLines;
  final Key? fieldKey;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      textInputAction: textInputAction,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Something did not load',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class CustomerStateView extends StatelessWidget {
  const CustomerStateView({
    super.key,
    required this.loading,
    required this.error,
    required this.empty,
    required this.child,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final bool empty;
  final Widget child;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const AppLoadingState();
    if (error != null) return AppErrorState(message: error!, onRetry: onRetry);
    if (empty) {
      return const AppEmptyState(
        title: 'Nothing here yet',
        body: 'When there is something to show, it will appear in this view.',
      );
    }
    return child;
  }
}

void showAppFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

bool runStore(BuildContext context, void Function() action) {
  try {
    action();
    return true;
  } on StoreException catch (error) {
    showAppFeedback(context, error.message);
    return false;
  }
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.onDark = false, this.width = 168});

  final bool onDark;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      onDark ? 'assets/brand/logo_light.png' : 'assets/brand/logo_dark.png',
      width: width,
      fit: BoxFit.contain,
    );
  }
}

class BrandIcon extends StatelessWidget {
  const BrandIcon({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class PhotoFrame extends StatelessWidget {
  const PhotoFrame({super.key, required this.asset, this.height = 180, this.radius = 12});

  final String asset;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: height,
          color: AppColors.gray100,
        ),
      ),
    );
  }
}
