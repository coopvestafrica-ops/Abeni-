import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_user.dart';
import '../../data/admin_providers.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminAllUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search by name, phone, or email',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: users.when(
              data: (list) {
                final customers = list
                    .where((u) => u.role == UserRole.customer)
                    .where((u) {
                  if (_query.trim().isEmpty) return true;
                  final q = _query.toLowerCase();
                  return u.fullName.toLowerCase().contains(q) ||
                      u.phone.toLowerCase().contains(q) ||
                      u.email.toLowerCase().contains(q);
                }).toList();
                if (customers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No customers yet.\nCustomers appear here once they sign up.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: customers.length,
                  itemBuilder: (context, i) {
                    final u = customers[i];
                    return _CustomerRow(
                      user: u,
                      onTap: () =>
                          context.push('/customer-detail', extra: u.id),
                    );
                  },
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
          ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.user, required this.onTap});
  final AppUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user.fullName);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(initials,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800)),
        ),
        title: Text(
          user.fullName.isEmpty ? '(no name)' : user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            if (user.phone.isNotEmpty) user.phone,
            if (user.email.isNotEmpty) user.email,
          ].join(' · '),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }
}
