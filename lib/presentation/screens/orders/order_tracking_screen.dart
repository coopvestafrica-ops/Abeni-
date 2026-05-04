import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order.dart';
import '../../providers/providers.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Single-document stream — no composite index, costs 1 read per
    // status change, fully compatible with Firebase free Spark plan.
    final orderAsync = ref.watch(singleOrderProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Track Order'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          const _LiveBadge(),
          IconButton(
            tooltip: 'Copy order ID',
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: orderId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order ID copied')),
              );
            },
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load order: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
        ),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found.'));
          }
          return _TrackingBody(order: order);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────── Live Badge ──

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _pulse,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.statusDelivered,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Live',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.statusDelivered,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── Body ──

class _TrackingBody extends StatelessWidget {
  final AbeniOrder order;
  const _TrackingBody({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        _OrderHeader(order: order),
        const SizedBox(height: 16),
        _StatusBanner(order: order),
        const SizedBox(height: 16),
        _StatusStepper(order: order),
        const SizedBox(height: 24),
        _SectionTitle(title: 'Items (${order.items.length})'),
        const SizedBox(height: 8),
        _ItemsList(order: order),
        const SizedBox(height: 20),
        _SectionTitle(title: 'Summary'),
        const SizedBox(height: 8),
        _SummaryCard(order: order),
        const SizedBox(height: 20),
        _StoreMessages(orderId: order.id),
      ],
    );
  }
}

// ─────────────────────────────────────────── Header ──

class _OrderHeader extends StatelessWidget {
  final AbeniOrder order;
  const _OrderHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status == OrderStatus.cancelled;
    final statusColor = _statusColor(order.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCancelled
                  ? Icons.cancel_rounded
                  : Icons.receipt_long_rounded,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDate(order.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              order.status.label,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── Status Banner ──

class _StatusBanner extends StatelessWidget {
  final AbeniOrder order;
  const _StatusBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.status == OrderStatus.delivered) {
      return _BannerTile(
        icon: Icons.check_circle_rounded,
        message: 'Your order has been delivered. Enjoy your purchase!',
        color: AppColors.statusDelivered,
      );
    }
    if (order.status == OrderStatus.cancelled) {
      return _BannerTile(
        icon: Icons.cancel_rounded,
        message:
            'This order was cancelled. Place a new order from the store.',
        color: AppColors.statusCancelled,
      );
    }
    if (order.status == OrderStatus.outForDelivery) {
      return _BannerTile(
        icon: Icons.local_shipping_rounded,
        message:
            "Your order is on its way! The rider is heading to your address.",
        color: AppColors.primary,
      );
    }
    if (order.status == OrderStatus.processing) {
      return _BannerTile(
        icon: Icons.blender_rounded,
        message:
            "We're packing your items carefully. Delivery usually takes 30–60 min after dispatch.",
        color: AppColors.statusProcessing,
      );
    }
    // pending
    return _BannerTile(
      icon: Icons.hourglass_top_rounded,
      message:
          "Your order has been received. We'll start preparing it shortly.",
      color: AppColors.statusPending,
    );
  }
}

class _BannerTile extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  const _BannerTile(
      {required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── Stepper ──

class _StatusStepper extends StatelessWidget {
  final AbeniOrder order;
  const _StatusStepper({required this.order});

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status == OrderStatus.cancelled;

    final steps = isCancelled
        ? [
            _StepData(
              icon: Icons.hourglass_top_rounded,
              label: 'Order Placed',
              subtitle: 'Your order was received',
              status: OrderStatus.pending,
            ),
            _StepData(
              icon: Icons.cancel_rounded,
              label: 'Cancelled',
              subtitle: 'This order was cancelled',
              status: OrderStatus.cancelled,
            ),
          ]
        : [
            _StepData(
              icon: Icons.hourglass_top_rounded,
              label: 'Order Placed',
              subtitle: 'Your order was received',
              status: OrderStatus.pending,
            ),
            _StepData(
              icon: Icons.blender_rounded,
              label: 'Preparing',
              subtitle: "We're packing your items",
              status: OrderStatus.processing,
            ),
            _StepData(
              icon: Icons.local_shipping_rounded,
              label: 'Out for Delivery',
              subtitle: 'Your order is on its way',
              status: OrderStatus.outForDelivery,
            ),
            _StepData(
              icon: Icons.check_circle_rounded,
              label: 'Delivered',
              subtitle: 'Order successfully delivered',
              status: OrderStatus.delivered,
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _StepRow(
              data: steps[i],
              currentStatus: order.status,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String label;
  final String subtitle;
  final OrderStatus status;
  const _StepData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.status,
  });
}

class _StepRow extends StatelessWidget {
  final _StepData data;
  final OrderStatus currentStatus;
  final bool isLast;

  const _StepRow({
    required this.data,
    required this.currentStatus,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final stepState = _computeState(data.status, currentStatus);
    final dotColor = _dotColor(stepState, data.status);
    final labelColor = stepState == _State.future
        ? AppColors.textMuted
        : AppColors.textPrimary;
    final subtitleColor = stepState == _State.future
        ? AppColors.textMuted
        : AppColors.textSecondary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: stepState == _State.future
                        ? AppColors.divider
                        : dotColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: stepState == _State.future
                          ? AppColors.divider
                          : dotColor,
                      width: stepState == _State.active ? 2.5 : 2,
                    ),
                  ),
                  child: stepState == _State.done
                      ? Icon(Icons.check_rounded, size: 18, color: dotColor)
                      : Icon(data.icon,
                          size: 18,
                          color: stepState == _State.future
                              ? AppColors.textMuted
                              : dotColor),
                ),
                if (!isLast)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: stepState == _State.done
                            ? AppColors.primary
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.label,
                          style: TextStyle(
                            fontWeight: stepState == _State.active
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 14,
                            color: labelColor,
                          ),
                        ),
                      ),
                      if (stepState == _State.active)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: dotColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Now',
                            style: TextStyle(
                              fontSize: 11,
                              color: dotColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: TextStyle(fontSize: 12, color: subtitleColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _State _computeState(OrderStatus step, OrderStatus current) {
    if (current == OrderStatus.cancelled) {
      if (step == OrderStatus.cancelled) return _State.active;
      if (step == OrderStatus.pending) return _State.done;
      return _State.future;
    }
    const order = [
      OrderStatus.pending,
      OrderStatus.processing,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];
    final stepIdx = order.indexOf(step);
    final currIdx = order.indexOf(current);
    if (stepIdx < currIdx) return _State.done;
    if (stepIdx == currIdx) return _State.active;
    return _State.future;
  }

  Color _dotColor(_State state, OrderStatus status) {
    if (state == _State.future) return AppColors.divider;
    if (status == OrderStatus.cancelled) return AppColors.statusCancelled;
    if (status == OrderStatus.delivered) return AppColors.statusDelivered;
    if (status == OrderStatus.outForDelivery) return AppColors.primary;
    if (status == OrderStatus.processing) return AppColors.statusProcessing;
    return AppColors.statusPending;
  }
}

enum _State { done, active, future }

// ─────────────────────────────────────────── Items ──

class _ItemsList extends StatelessWidget {
  final AbeniOrder order;
  const _ItemsList({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          for (var i = 0; i < order.items.length; i++) ...[
            if (i > 0)
              const Divider(
                  height: 1,
                  color: AppColors.divider,
                  indent: 16,
                  endIndent: 16),
            _ItemRow(line: order.items[i]),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final dynamic line;
  const _ItemRow({required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${line.unitName}  ×  ${line.quantity}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            formatNaira(line.lineTotal as num),
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── Summary ──

class _SummaryCard extends StatelessWidget {
  final AbeniOrder order;
  const _SummaryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _Row('Subtotal', formatNaira(order.subtotal)),
          const SizedBox(height: 6),
          _Row('Delivery fee', formatNaira(order.deliveryFee)),
          const SizedBox(height: 6),
          _Row('Payment', order.paymentMethod.label),
          const SizedBox(height: 6),
          _Row('Type', order.fulfillmentType.label),
          if (order.deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            _Row('Address', order.deliveryAddress),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          Row(
            children: [
              const Text('Total',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              Text(
                formatNaira(order.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────── Store Messages ──

class _StoreMessages extends ConsumerStatefulWidget {
  final String orderId;
  const _StoreMessages({required this.orderId});

  @override
  ConsumerState<_StoreMessages> createState() => _StoreMessagesState();
}

class _StoreMessagesState extends ConsumerState<_StoreMessages> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final msgsAsync = ref.watch(orderMessagesProvider(widget.orderId));

    return msgsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (msgs) {
        if (msgs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  const Text(
                    'Messages from Store',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${msgs.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < msgs.length; i++) ...[
                        if (i > 0)
                          const Divider(
                              height: 1,
                              color: AppColors.divider,
                              indent: 16,
                              endIndent: 16),
                        _MessageTile(msg: msgs[i]),
                      ],
                    ],
                  ),
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _MessageTile extends StatelessWidget {
  final Map<String, dynamic> msg;
  const _MessageTile({required this.msg});

  IconData get _typeIcon {
    switch ((msg['type'] as String?) ?? '') {
      case 'order_status':
        return Icons.local_shipping_outlined;
      case 'direct_message':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _timeStr() {
    final ts = msg['createdAt'];
    if (ts == null) return '';
    DateTime? dt;
    if (ts is Timestamp) dt = ts.toDate();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return formatDate(dt);
  }

  @override
  Widget build(BuildContext context) {
    final title = (msg['title'] as String?) ?? '';
    final body = (msg['body'] as String?) ?? '';
    final isRead = (msg['read'] as bool?) ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(_typeIcon, size: 18, color: AppColors.primary),
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
                          fontSize: 13,
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
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _timeStr(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── Helpers ──

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15));
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
