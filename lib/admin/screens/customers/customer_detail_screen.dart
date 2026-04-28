import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/order.dart';
import '../../../data/services/firebase_service.dart';
import '../../data/admin_providers.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminAllUsersProvider);
    final orders = ref.watch(adminAllOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customer')),
      body: users.when(
        data: (list) {
          final user = list.firstWhere(
            (u) => u.id == userId,
            orElse: () => const AppUser(
              id: '',
              email: '',
              fullName: '(unknown)',
              phone: '',
              deliveryAddress: '',
            ),
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CustomerHeader(user: user),
              const SizedBox(height: 16),
              if (user.phone.isNotEmpty || user.email.isNotEmpty)
                Row(
                  children: [
                    if (user.phone.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              launchUrl(Uri.parse('tel:${user.phone}')),
                          icon: const Icon(Icons.call),
                          label: const Text('Call'),
                        ),
                      ),
                    if (user.phone.isNotEmpty && user.email.isNotEmpty)
                      const SizedBox(width: 8),
                    if (user.email.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(
                              Uri.parse('mailto:${user.email}')),
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Email'),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _sendDirectMessage(context, ref, user),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Send notification'),
              ),
              const SizedBox(height: 24),
              const Text('Order history',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              orders.when(
                data: (all) {
                  final mine = all
                      .where((o) => o.userId == userId)
                      .toList()
                    ..sort(
                        (a, b) => b.createdAt.compareTo(a.createdAt));
                  if (mine.isEmpty) {
                    return _EmptyHint(
                        text:
                            FirebaseService.isInitialized
                                ? 'This customer hasn\'t placed any orders yet.'
                                : 'Order history is unavailable in demo mode.');
                  }
                  return Column(
                    children: [
                      _SummaryRow(
                        label: 'Total spent',
                        value: _money(mine.fold<double>(
                            0, (sum, o) => sum + o.total)),
                      ),
                      _SummaryRow(
                        label: 'Total orders',
                        value: '${mine.length}',
                      ),
                      const SizedBox(height: 8),
                      for (final o in mine) _OrderTile(order: o),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('$e',
                    style: const TextStyle(color: AppColors.error)),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('$e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Future<void> _sendDirectMessage(
      BuildContext context, WidgetRef ref, AppUser user) async {
    if (!FirebaseService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Firebase is not configured. See README.')),
      );
      return;
    }
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Notify ${user.fullName.split(' ').first}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send')),
        ],
      ),
    );
    if (ok != true) return;
    if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required')),
      );
      return;
    }
    await ref.read(adminRepositoryProvider).sendDirectMessage(
          userId: user.id,
          title: titleCtrl.text.trim(),
          body: bodyCtrl.text.trim(),
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Notification sent'),
          backgroundColor: AppColors.success),
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              _initials(user.fullName),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isEmpty ? '(no name)' : user.fullName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                if (user.phone.isNotEmpty)
                  Text(user.phone,
                      style: const TextStyle(
                          color: AppColors.textSecondary)),
                if (user.email.isNotEmpty)
                  Text(user.email,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                if (user.deliveryAddress.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(user.deliveryAddress,
                              style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final AbeniOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text('#${order.id}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${DateFormat('d MMM, h:mm a').format(order.createdAt)} · ${order.status.label}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          _money(order.total),
          style: const TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        onTap: () => context.push('/order-detail', extra: order),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(text,
          style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}

String _money(double amount) {
  final f = NumberFormat('#,##0', 'en_US');
  return '${AppConstants.currencySymbol}${f.format(amount)}';
}

// Quiet warnings for unused import in some code paths.
// ignore: unused_element
final _kFsTouch = FirebaseFirestore;
