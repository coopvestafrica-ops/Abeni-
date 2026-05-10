import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

enum _MenuAction { markAllRead, clearAll }

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          PopupMenuButton<_MenuAction>(
            tooltip: 'Options',
            onSelected: (action) {
              switch (action) {
                case _MenuAction.markAllRead:
                  _markAllRead(user.id);
                case _MenuAction.clearAll:
                  _confirmClearAll(context, user.id);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _MenuAction.markAllRead,
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded,
                        size: 20, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _MenuAction.clearAll,
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded,
                        size: 20, color: AppColors.error),
                    SizedBox(width: 10),
                    Text('Clear all notifications',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customer_messages')
            .where('userId', isEqualTo: user.id)
            .orderBy('createdAt', descending: true)
            .limit(60)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final docId = docs[i].id;
              final isRead = (data['read'] as bool?) ?? false;
              final title = (data['title'] as String?) ?? 'Abeni Mart';
              final body = (data['body'] as String?) ?? '';
              final type = (data['type'] as String?) ?? '';
              final orderId = (data['orderId'] as String?) ?? '';
              final ts = data['createdAt'] as Timestamp?;
              final time = ts != null ? ts.toDate() : null;

              return Dismissible(
                key: ValueKey(docId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: Colors.white, size: 26),
                      SizedBox(height: 4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (_) => _confirmDelete(context),
                onDismissed: (_) => _deleteNotif(docId),
                child: _NotifCard(
                  docId: docId,
                  userId: user.id,
                  isRead: isRead,
                  title: title,
                  body: body,
                  type: type,
                  orderId: orderId,
                  time: time,
                  onTap: () {
                    _markRead(docId);
                    if (orderId.isNotEmpty) {
                      context.push('/order-tracking/$orderId');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _markRead(String docId) {
    FirebaseFirestore.instance
        .collection('customer_messages')
        .doc(docId)
        .update({'read': true}).catchError((_) {});
  }

  void _markAllRead(String userId) {
    FirebaseFirestore.instance
        .collection('customer_messages')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get()
        .then((snap) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      batch.commit();
    });
  }

  void _deleteNotif(String docId) {
    FirebaseFirestore.instance
        .collection('customer_messages')
        .doc(docId)
        .delete()
        .catchError((_) {});
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete notification?'),
        content:
            const Text('This notification will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmClearAll(
      BuildContext context, String userId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'All notifications will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear all',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _clearAll(userId);
  }

  void _clearAll(String userId) {
    FirebaseFirestore.instance
        .collection('customer_messages')
        .where('userId', isEqualTo: userId)
        .get()
        .then((snap) {
      if (snap.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      batch.commit();
    }).catchError((_) {});
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.docId,
    required this.userId,
    required this.isRead,
    required this.title,
    required this.body,
    required this.type,
    required this.orderId,
    required this.time,
    required this.onTap,
  });

  final String docId;
  final String userId;
  final bool isRead;
  final String title;
  final String body;
  final String type;
  final String orderId;
  final DateTime? time;
  final VoidCallback onTap;

  IconData get _icon {
    switch (type) {
      case 'order_status':
        return Icons.local_shipping_outlined;
      case 'payment_confirmed':
        return Icons.check_circle_outline;
      case 'broadcast':
        return Icons.campaign_outlined;
      case 'direct':
        return Icons.message_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _iconColor {
    switch (type) {
      case 'order_status':
        return AppColors.statusProcessing;
      case 'payment_confirmed':
        return AppColors.statusDelivered;
      case 'broadcast':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? AppColors.divider
                : AppColors.primary.withOpacity(0.3),
            width: isRead ? 1 : 1.4,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight:
                                isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (time != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(time!),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('d MMM, h:mm a').format(dt);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No notifications yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Order updates and messages will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
