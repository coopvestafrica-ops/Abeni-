import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/order.dart';
import '../../../presentation/providers/providers.dart';
import '../../data/admin_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final today = ref.watch(adminTodaySummaryProvider);
    final todayTop = ref.watch(adminTodayTopProductProvider);
    final week = ref.watch(adminWeekSummaryProvider);
    final month = ref.watch(adminMonthSummaryProvider);
    final orders = ref.watch(adminAllOrdersProvider);
    final lowStock = ref.watch(adminLowStockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminAllOrdersProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (user != null)
            Text(
              'Welcome, ${user.fullName.isEmpty ? 'Admin' : user.fullName.split(' ').first}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          // Sales summary cards
          _TodayDetailCard(summary: today, topProduct: todayTop),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Last 7 days',
                  color: AppColors.info,
                  asyncValue: week,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Last 30 days',
                  color: AppColors.terracotta,
                  asyncValue: month,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Pending action items
          orders.when(
            data: (list) {
              final pending =
                  list.where((o) => o.status == OrderStatus.pending).toList();
              final processing = list
                  .where((o) => o.status == OrderStatus.processing)
                  .toList();
              return _ActionRow(
                pending: pending.length,
                processing: processing.length,
                onPendingTap: () {
                  ref.read(adminOrderStatusFilterProvider.notifier).state =
                      OrderStatus.pending;
                  context.go('/orders');
                },
                onProcessingTap: () {
                  ref.read(adminOrderStatusFilterProvider.notifier).state =
                      OrderStatus.processing;
                  context.go('/orders');
                },
              );
            },
            loading: () => const SizedBox(
              height: 64,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorBox(message: '$e'),
          ),
          const SizedBox(height: 24),
          // Recent orders
          const _SectionHeader('Recent orders'),
          const SizedBox(height: 8),
          orders.when(
            data: (list) {
              final recent = list.take(5).toList();
              if (recent.isEmpty) {
                return _EmptyHint(
                  icon: Icons.receipt_long_outlined,
                  text: 'No orders yet.',
                );
              }
              return Column(
                children: [
                  for (final o in recent)
                    _OrderListTile(
                      order: o,
                      onTap: () => context.push('/order-detail', extra: o),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorBox(message: '$e'),
          ),
          const SizedBox(height: 24),
          // Top products
          const _SectionHeader('Top selling products'),
          const SizedBox(height: 8),
          ref.watch(adminTopProductsProvider).when(
                data: (list) {
                  if (list.isEmpty) {
                    return _EmptyHint(
                      icon: Icons.trending_up,
                      text: 'No sales yet.',
                    );
                  }
                  return Column(
                    children: [
                      for (final p in list.take(5))
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${p.unitsSold} sold',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                              const SizedBox(width: 12),
                              Text(
                                _money(p.revenue),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _ErrorBox(message: '$e'),
              ),
          const SizedBox(height: 24),
          // Low stock
          const _SectionHeader('Low stock'),
          const SizedBox(height: 8),
          lowStock.when(
            data: (list) {
              if (list.isEmpty) {
                return _EmptyHint(
                  icon: Icons.check_circle_outline,
                  text: 'All products well stocked.',
                );
              }
              return Column(
                children: [
                  for (final p in list.take(6))
                    InkWell(
                      onTap: () => context.push('/product-edit', extra: p),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppColors.warning, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                            Text(
                              p.units
                                  .where((u) => u.stock <= 3)
                                  .map((u) => '${u.unitName}: ${u.stock}')
                                  .join(' · '),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorBox(message: '$e'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────── //
// Today detail card — revenue, order count, and today's top product.        //
// ─────────────────────────────────────────────────────────────────────────── //
class _TodayDetailCard extends StatelessWidget {
  const _TodayDetailCard({
    required this.summary,
    required this.topProduct,
  });

  final AsyncValue<SalesSummary> summary;
  final AsyncValue<TopProduct?> topProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: summary.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
          ),
        ),
        error: (e, _) => Text('$e',
            style: const TextStyle(color: Colors.white, fontSize: 12)),
        data: (s) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.today_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Today',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Revenue
            Text(
              _money(s.revenue),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 32,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${s.orderCount} order${s.orderCount == 1 ? '' : 's'} today',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
              ),
            ),
            // Divider + top product row
            if (topProduct.hasValue && topProduct.value != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(
                  color: Colors.white.withOpacity(0.2),
                  height: 1,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: AppColors.accent, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top product today',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          topProduct.value!.productName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${topProduct.value!.unitsSold} sold',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _money(double amount) {
  final formatter = NumberFormat('#,##0', 'en_US');
  return '${AppConstants.currencySymbol}${formatter.format(amount)}';
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.color,
    required this.asyncValue,
    this.compact = false,
  });

  final String label;
  final Color color;
  final AsyncValue<SalesSummary> asyncValue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.75)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: asyncValue.when(
        data: (s) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: compact ? 6 : 8),
            Text(
              _money(s.revenue),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 18 : 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${s.orderCount} order${s.orderCount == 1 ? '' : 's'}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: compact ? 11 : 12,
              ),
            ),
          ],
        ),
        loading: () => const SizedBox(
          height: 60,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            ),
          ),
        ),
        error: (e, _) => Text('$e',
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.pending,
    required this.processing,
    required this.onPendingTap,
    required this.onProcessingTap,
  });

  final int pending;
  final int processing;
  final VoidCallback onPendingTap;
  final VoidCallback onProcessingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            label: 'Pending',
            count: pending,
            color: AppColors.statusPending,
            icon: Icons.hourglass_top,
            onTap: onPendingTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            label: 'Processing',
            count: processing,
            color: AppColors.statusProcessing,
            icon: Icons.local_shipping_outlined,
            onTap: onProcessingTap,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const Spacer(),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }
}

class _OrderListTile extends StatelessWidget {
  const _OrderListTile({required this.order, required this.onTap});
  final AbeniOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text('#${order.id}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${order.items.length} items · ${order.fulfillmentType.label}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_money(order.total),
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            const SizedBox(height: 2),
            _StatusChip(status: order.status),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final OrderStatus status;

  Color get _color {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Text(message,
          style: const TextStyle(color: AppColors.error, fontSize: 12)),
    );
  }
}
