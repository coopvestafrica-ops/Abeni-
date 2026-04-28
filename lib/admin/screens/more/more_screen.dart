import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../presentation/providers/providers.dart';
import 'broadcast_screen.dart';
import 'sales_screen.dart';
import 'staff_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (user != null) _ProfileCard(name: user.fullName, email: user.email),
          const SizedBox(height: 16),
          _Tile(
            icon: Icons.campaign_outlined,
            title: 'Broadcast notification',
            subtitle: 'Send a push to all customers',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BroadcastScreen())),
          ),
          _Tile(
            icon: Icons.bar_chart_outlined,
            title: 'Sales reports',
            subtitle: 'Today, this week, this month',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SalesScreen())),
          ),
          if (isAdmin)
            _Tile(
              icon: Icons.shield_outlined,
              title: 'Staff & admins',
              subtitle: 'Grant or revoke admin access',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const StaffScreen())),
            ),
          _Tile(
            icon: Icons.cloud_upload_outlined,
            title: 'Seed sample products',
            subtitle: 'Upload the built-in catalog to Firestore',
            onTap: () => _seedCatalog(context, ref),
          ),
          const SizedBox(height: 16),
          const Divider(),
          _Tile(
            icon: Icons.logout,
            title: 'Sign out',
            color: AppColors.error,
            onTap: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _seedCatalog(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed sample products?'),
        content: const Text(
          'This will upload the built-in product catalog (with photos) to '
          'Firestore. Existing products with the same IDs will be overwritten.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Seed')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final n = await ProductRepository().seedSampleProducts();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Uploaded $n products'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to use the admin app.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    context.go('/login');
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.email});
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.shield_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Admin' : name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800),
                ),
                if (email.isNotEmpty)
                  Text(email,
                      style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: c, size: 22),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.textPrimary)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
