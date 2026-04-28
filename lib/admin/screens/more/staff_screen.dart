import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_user.dart';
import '../../../data/services/firebase_service.dart';
import '../../../presentation/providers/providers.dart';
import '../../data/admin_providers.dart';

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminAllUsersProvider);
    final me = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Staff & admins')),
      body: users.when(
        data: (list) {
          if (!FirebaseService.isInitialized) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Firebase is not configured. Staff management '
                  'requires a real Firebase project.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _Hint(
                text: 'Promote a customer account to staff (read + manage '
                    'orders) or admin (full access).',
              ),
              const SizedBox(height: 16),
              ...list.map((u) => _UserRow(
                    user: u,
                    isMe: u.id == me?.id,
                    onChange: (role) async {
                      await ref
                          .read(adminRepositoryProvider)
                          .updateUserRole(u.id, role);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${u.fullName} is now ${role.label}')),
                      );
                    },
                  )),
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
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.isMe,
    required this.onChange,
  });

  final AppUser user;
  final bool isMe;
  final ValueChanged<UserRole> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isEmpty ? '(no name)' : user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (user.email.isNotEmpty)
                      Text(user.email,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12)),
                  ],
                ),
              ),
              if (isMe)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('You',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final role in UserRole.values)
                ChoiceChip(
                  label: Text(role.label),
                  selected: user.role == role,
                  onSelected: isMe
                      ? null
                      : (_) {
                          if (user.role != role) onChange(role);
                        },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
