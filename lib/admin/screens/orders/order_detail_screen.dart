import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/order.dart';
import '../../../presentation/providers/providers.dart';
import '../../data/admin_providers.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final AbeniOrder order;

  @override
  ConsumerState<OrderDetailScreen> createState() =>
      _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _busy = false;

  Future<void> _changeStatus(OrderStatus newStatus) async {
    final note = await _askNote(context, newStatus);
    if (note == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).updateOrderStatus(
            order: widget.order,
            newStatus: newStatus,
            note: note,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Status updated → ${newStatus.label}'),
            backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askNote(BuildContext context, OrderStatus s) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark as ${s.label}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'The customer will be notified via push notification.',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Add a note (optional)',
                hintText: 'e.g. ETA 30 minutes',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _markPaymentReceived() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm payment received?'),
        content: const Text(
          'The customer will be notified that you\'ve received their bank '
          'transfer.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .markPaymentReceived(widget.order);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Payment confirmed'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addInternalNote() async {
    final user = ref.read(currentUserProvider);
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add internal note'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Visible to staff only',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    await ref.read(adminRepositoryProvider).addOrderNote(
          orderId: widget.order.id,
          authorName: user?.fullName ?? 'Admin',
          note: ctrl.text.trim(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note saved')),
    );
  }

  Future<void> _sendQuickMessage() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final order = widget.order;

    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send message to customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This message will appear in the customer\'s notification inbox '
              'and trigger a push notification.',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: bodyCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty ||
                  bodyCtrl.text.trim().isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('customer_messages')
                  .add({
                'userId': order.userId,
                'orderId': order.id,
                'type': 'direct',
                'title': titleCtrl.text.trim(),
                'body': bodyCtrl.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
                'read': false,
              });
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (sent == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Message sent'),
            backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _deleteOrder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this order?'),
        content: Text(
          'Order #${widget.order.id} will be permanently removed from the '
          'list. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteOrder(widget.order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Order deleted'),
            backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id}'),
        actions: [
          IconButton(
            tooltip: 'Add internal note',
            icon: const Icon(Icons.note_add_outlined),
            onPressed: _busy ? null : _addInternalNote,
          ),
          IconButton(
            tooltip: 'Message customer',
            icon: const Icon(Icons.send_outlined),
            onPressed: _busy ? null : _sendQuickMessage,
          ),
          IconButton(
            tooltip: 'Delete order',
            icon:
                const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _busy ? null : _deleteOrder,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _statusHeader(order),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Customer',
            trailing: order.phone.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.phone,
                        color: AppColors.primary),
                    onPressed: () =>
                        launchUrl(Uri.parse('tel:${order.phone}')),
                  ),
          ),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Phone',
                    order.phone.isEmpty ? '—' : order.phone),
                _kv('Type', order.fulfillmentType.label),
                _kv('Address',
                    order.deliveryAddress.isEmpty
                        ? '—'
                        : order.deliveryAddress),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Items (${order.items.length})'),
          _Card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < order.items.length; i++) ...[
                  if (i > 0)
                    const Divider(
                        height: 1, color: AppColors.divider),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(order.items[i].productName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                '${order.items[i].quantity} × '
                                '${order.items[i].unitName}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(_money(order.items[i].lineTotal),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Totals'),
          _Card(
            child: Column(
              children: [
                _kv('Subtotal', _money(order.subtotal)),
                _kv('Delivery fee', _money(order.deliveryFee)),
                const Divider(height: 16),
                _kv('Total', _money(order.total), emphasis: true),
                const SizedBox(height: 8),
                _kv('Payment', order.paymentMethod.label),
                _kv('Placed',
                    DateFormat('d MMM yyyy, h:mm a')
                        .format(order.createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (order.paymentMethod == PaymentMethod.bankTransfer) ...[
            ElevatedButton.icon(
              onPressed: _busy ? null : _markPaymentReceived,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark payment as received'),
            ),
            const SizedBox(height: 12),
          ],
          const _SectionHeader(title: 'Update status'),
          const SizedBox(height: 8),
          ..._statusButtons(order),
          const SizedBox(height: 24),

          // ─────────── Communication history ───────────
          _CommHistoryPanel(orderId: order.id),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: _busy ? null : _deleteOrder,
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error),
            label: const Text('Delete this order',
                style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusHeader(AbeniOrder order) {
    final color = _statusColor(order.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(order.status), color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current status',
                    style: TextStyle(
                        color: color.withOpacity(0.85), fontSize: 11)),
                Text(order.status.label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    )),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: order.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order ID copied')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
          ),
        ],
      ),
    );
  }

  List<Widget> _statusButtons(AbeniOrder order) {
    final allowed =
        OrderStatus.values.where((s) => s != order.status).toList();
    return [
      for (final s in allowed)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton.icon(
            onPressed: _busy ? null : () => _changeStatus(s),
            icon: Icon(_statusIcon(s), color: _statusColor(s)),
            label: Text('Mark as ${s.label}',
                style: TextStyle(color: _statusColor(s))),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _statusColor(s)),
            ),
          ),
        ),
    ];
  }

  IconData _statusIcon(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return Icons.hourglass_top;
      case OrderStatus.processing:
        return Icons.kitchen_outlined;
      case OrderStatus.outForDelivery:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.processing:
      case OrderStatus.outForDelivery:
        return AppColors.statusProcessing;
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Communication History Panel
// Streams customer_messages where orderId == this order's ID, shows a
// chronological timeline of every push/inbox message sent to the customer.
// ═══════════════════════════════════════════════════════════════════════

class _CommHistoryPanel extends StatefulWidget {
  const _CommHistoryPanel({required this.orderId});
  final String orderId;

  @override
  State<_CommHistoryPanel> createState() => _CommHistoryPanelState();
}

class _CommHistoryPanelState extends State<_CommHistoryPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header row ──
          InkWell(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history_edu_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Communication history',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Every notification & message sent for this order',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // ── Collapsible body ──
          if (_expanded)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('customer_messages')
                  .where('orderId', isEqualTo: widget.orderId)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  // Likely missing composite index — show helper text
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Could not load history: ${snap.error}',
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12),
                    ),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _EmptyHistory();
                }
                return Column(
                  children: [
                    const Divider(height: 1, color: AppColors.divider),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) =>
                          const _TimelineSpacer(),
                      itemBuilder: (context, i) {
                        final data =
                            docs[i].data() as Map<String, dynamic>;
                        final isLast = i == docs.length - 1;
                        return _TimelineEntry(
                          data: data,
                          isLast: isLast,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.data, required this.isLast});
  final Map<String, dynamic> data;
  final bool isLast;

  String get _type => (data['type'] as String?) ?? 'direct';
  String get _title => (data['title'] as String?) ?? 'Notification';
  String get _body => (data['body'] as String?) ?? '';
  bool get _read => (data['read'] as bool?) ?? false;
  Timestamp? get _ts => data['createdAt'] as Timestamp?;

  IconData get _icon {
    switch (_type) {
      case 'order_status':
        return Icons.local_shipping_outlined;
      case 'payment_confirmed':
        return Icons.check_circle_outline;
      case 'broadcast':
        return Icons.campaign_outlined;
      case 'direct':
      default:
        return Icons.message_outlined;
    }
  }

  String get _typeLabel {
    switch (_type) {
      case 'order_status':
        return 'Status update';
      case 'payment_confirmed':
        return 'Payment';
      case 'broadcast':
        return 'Broadcast';
      case 'direct':
        return 'Direct message';
      default:
        return 'Notification';
    }
  }

  Color get _color {
    switch (_type) {
      case 'order_status':
        return AppColors.statusProcessing;
      case 'payment_confirmed':
        return AppColors.statusDelivered;
      case 'broadcast':
        return AppColors.primary;
      case 'direct':
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = _ts?.toDate();
    final timeStr = ts != null
        ? DateFormat('d MMM, h:mm a').format(ts)
        : '—';
    final color = _color;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Timeline rail ──
        Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 16, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 12),

        // ── Content ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type chip + read indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (_read)
                      const Row(
                        children: [
                          Icon(Icons.done_all,
                              size: 12,
                              color: AppColors.statusDelivered),
                          SizedBox(width: 3),
                          Text(
                            'Read',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.statusDelivered,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.circle,
                              size: 7,
                              color: AppColors.textMuted),
                          SizedBox(width: 4),
                          Text(
                            'Unread',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                // Title
                Text(
                  _title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                // Body
                if (_body.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    _body,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 5),
                // Timestamp
                Text(
                  timeStr,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted),
                ),
                // bottom spacing before connector
                if (!isLast) const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineSpacer extends StatelessWidget {
  const _TimelineSpacer();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.divider,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined,
                size: 18, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No messages sent yet.\n'
              'Status changes and direct messages will appear here.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────── shared helpers (file-private) ── //

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

Widget _kv(String k, String v, {bool emphasis = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(k,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            v,
            style: TextStyle(
              fontWeight: emphasis ? FontWeight.w900 : FontWeight.w600,
              fontSize: emphasis ? 16 : 13,
              color: emphasis
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

String _money(double amount) {
  final f = NumberFormat('#,##0', 'en_US');
  return '${AppConstants.currencySymbol}${f.format(amount)}';
}
