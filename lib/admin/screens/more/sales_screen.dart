import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../data/admin_providers.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(adminTodaySummaryProvider);
    final week = ref.watch(adminWeekSummaryProvider);
    final month = ref.watch(adminMonthSummaryProvider);
    final top = ref.watch(adminTopProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(label: 'Today', color: AppColors.primary, value: today),
          const SizedBox(height: 12),
          _SummaryCard(
              label: 'Last 7 days', color: AppColors.info, value: week),
          const SizedBox(height: 12),
          _SummaryCard(
              label: 'Last 30 days',
              color: AppColors.terracotta,
              value: month),
          const SizedBox(height: 24),
          const Text('Top selling products',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          top.when(
            data: (list) {
              if (list.isEmpty) {
                return _empty('No sales yet.');
              }
              return Column(
                children: [
                  for (final p in list)
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
                            child: Text(p.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          Text('${p.unitsSold} sold',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          const SizedBox(width: 12),
                          Text(
                            _money(p.revenue),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            loading: () =>
                const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('$e',
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
  final AsyncValue<SalesSummary> value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: value.when(
        data: (s) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            Text(_money(s.revenue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                )),
            Text('${s.orderCount} orders',
                style: TextStyle(color: Colors.white.withOpacity(0.9))),
          ],
        ),
        loading: () => const SizedBox(
          height: 60,
          child: Center(
              child: CircularProgressIndicator(color: Colors.white)),
        ),
        error: (e, _) => Text('$e',
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }
}

Widget _empty(String text) {
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

String _money(double amount) {
  final f = NumberFormat('#,##0', 'en_US');
  return '${AppConstants.currencySymbol}${f.format(amount)}';
}
