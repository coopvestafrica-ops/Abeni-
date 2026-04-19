import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order.dart';
import '../../widgets/primary_button.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  final AbeniOrder order;
  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Order Confirmed'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.primary, size: 56),
              ),
              const SizedBox(height: 20),
              const Text(
                'Thank you!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your order has been placed.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        _row('Order ID', '#${order.id}'),
                        _row('Status', order.status.label,
                            accent: AppColors.statusPending),
                        _row(
                          'Fulfillment',
                          order.fulfillmentType.label,
                        ),
                        _row('Payment', order.paymentMethod.label),
                        if (order.fulfillmentType == FulfillmentType.delivery)
                          _row('Address', order.deliveryAddress),
                        const Divider(height: 24),
                        for (final line in order.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${line.productName} • ${line.unitName} × ${line.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(formatNaira(line.lineTotal)),
                              ],
                            ),
                          ),
                        const Divider(height: 24),
                        _row('Subtotal', formatNaira(order.subtotal)),
                        _row(
                          'Delivery',
                          order.deliveryFee > 0
                              ? formatNaira(order.deliveryFee)
                              : 'Free',
                        ),
                        const SizedBox(height: 6),
                        _row(
                          'Total',
                          formatNaira(order.total),
                          emphasize: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Back to Home',
                icon: Icons.home_rounded,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool emphasize = false, Color? accent}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: accent ?? (emphasize ? AppColors.primary : null),
                fontSize: emphasize ? 16 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
