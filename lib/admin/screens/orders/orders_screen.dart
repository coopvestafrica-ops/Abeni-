import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/order.dart';
import '../../data/admin_providers.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(adminFilteredOrdersProvider);
    final filter = ref.watch(adminOrderStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  ref.read(adminOrderSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Search by order ID, phone, address, item...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref
                              .read(adminOrderSearchProvider.notifier)
                              .state = '';
                        },
                      ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filter == null,
                  onTap: () => ref
                      .read(adminOrderStatusFilterProvider.notifier)
                      .state = null,
                ),
                for (final s in OrderStatus.values) ...[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: s.label,
                    selected: filter == s,
                    onTap: () => ref
                        .read(adminOrderStatusFilterProvider.notifier)
                        .state = s,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: orders.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No orders match this filter.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final o = list[i];
                    return _OrderCard(
                      order: o,
                      onTap: () => context.push('/order-detail', extra: o),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final AbeniOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
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
                  Text(
                    '#${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('d MMM, h:mm a').format(order.createdAt),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
              const Divider(height: 18),
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    order.phone.isEmpty ? '—' : order.phone,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    order.fulfillmentType == FulfillmentType.delivery
                        ? Icons.local_shipping_outlined
                        : Icons.storefront_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(order.fulfillmentType.label,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
              if (order.deliveryAddress.isNotEmpty &&
                  order.fulfillmentType == FulfillmentType.delivery) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.deliveryAddress,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const Spacer(),
                  Text(
                    _money(order.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _money(double amount) {
  final f = NumberFormat('#,##0', 'en_US');
  return '${AppConstants.currencySymbol}${f.format(amount)}';
}
