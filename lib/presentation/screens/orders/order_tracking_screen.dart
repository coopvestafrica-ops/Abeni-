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
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Track Order'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
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
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load order: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
        ),
        data: (orders) {
          final order = orders.cast<AbeniOrder?>().firstWhere(
                (o) => o?.id == orderId,
                orElse: () => null,
              );
          if (order == null) {
            return const Center(child: Text('Order not found.'));
          }
          return _TrackingBody(order: order);
        },
      ),
    );
  }
}

class _TrackingBody extends StatelessWidget {
  final AbeniOrder order;
  const _TrackingBody({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        _OrderHeader(order: order),
        const SizedBox(height: 24),
        _StatusStepper(order: order),
        const SizedBox(height: 24),
        _SectionTitle(title: 'Items (${order.items.length})'),
        const SizedBox(height: 8),
        _ItemsList(order: order),
        const SizedBox(height: 20),
        _SectionTitle(title: 'Summary'),
        const SizedBox(height: 8),
        _SummaryCard(order: order),
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
          // ── left column: dot + connector line ──
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
                      ? Icon(Icons.check_rounded,
                          size: 18, color: dotColor)
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
          // ── right column: label + subtitle ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 6,
                bottom: isLast ? 0 : 24,
              ),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
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
    final order = [
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
    if (status == OrderStatus.outForDelivery) return AppColors.statusProcessing;
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
              const Divider(height: 1, color: AppColors.divider,
                  indent: 16, endIndent: 16),
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
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14),
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
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
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

// ─────────────────────────────────────────── Helpers ──

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15));
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
