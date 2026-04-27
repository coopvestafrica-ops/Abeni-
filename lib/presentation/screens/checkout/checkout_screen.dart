import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/store_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order.dart';
import '../../providers/providers.dart';
import '../../widgets/primary_button.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  FulfillmentType _fulfillment = FulfillmentType.delivery;
  PaymentMethod _payment = PaymentMethod.payOnDelivery;
  final _address = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;

  static const double _deliveryFee = 1500;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _address.text = user?.deliveryAddress ?? '';
    _phone.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final user = ref.read(currentUserProvider);
    final cart = ref.read(cartProvider);
    if (user == null || cart.items.isEmpty) return;

    if (_fulfillment == FulfillmentType.delivery) {
      if (_address.text.trim().isEmpty || _phone.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide a delivery address and phone number.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final order = await ref.read(orderRepositoryProvider).placeOrder(
            userId: user.id,
            items: cart.items,
            fulfillmentType: _fulfillment,
            paymentMethod: _payment,
            deliveryAddress: _address.text.trim(),
            phone: _phone.text.trim(),
            deliveryFee: _deliveryFee,
          );
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
      if (!mounted) return;
      context.pushReplacement('/order-confirmation', extra: order);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place order: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final subtotal = cart.subtotal;
    final total = subtotal +
        (_fulfillment == FulfillmentType.delivery ? _deliveryFee : 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _Section(title: 'Fulfillment'),
          _OptionTile(
            icon: Icons.delivery_dining_rounded,
            title: 'Delivery',
            subtitle: 'We deliver to your address',
            trailing: formatNaira(_deliveryFee),
            selected: _fulfillment == FulfillmentType.delivery,
            onTap: () =>
                setState(() => _fulfillment = FulfillmentType.delivery),
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.storefront_rounded,
            title: 'Pickup',
            subtitle: 'Pick up at Abeni Mart store',
            trailing: 'Free',
            selected: _fulfillment == FulfillmentType.pickup,
            onTap: () => setState(() => _fulfillment = FulfillmentType.pickup),
          ),
          if (_fulfillment == FulfillmentType.delivery) ...[
            const SizedBox(height: 24),
            const _Section(title: 'Delivery details'),
            TextField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const _Section(title: 'Payment method'),
          _OptionTile(
            icon: Icons.payments_outlined,
            title: 'Pay on Delivery',
            subtitle: 'Cash when order arrives',
            selected: _payment == PaymentMethod.payOnDelivery,
            onTap: () =>
                setState(() => _payment = PaymentMethod.payOnDelivery),
          ),
          const SizedBox(height: 10),
          _OptionTile(
            icon: Icons.account_balance_outlined,
            title: 'Bank Transfer',
            subtitle: 'Transfer to Abeni Mart account',
            selected: _payment == PaymentMethod.bankTransfer,
            onTap: () =>
                setState(() => _payment = PaymentMethod.bankTransfer),
          ),
          if (_payment == PaymentMethod.bankTransfer) ...[
            const SizedBox(height: 12),
            const _BankTransferDetails(account: StoreInfo.payoutAccount),
          ],
          const SizedBox(height: 24),
          const _Section(title: 'Order summary'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _summaryRow('Subtotal', formatNaira(subtotal)),
                const SizedBox(height: 6),
                _summaryRow(
                  'Delivery',
                  _fulfillment == FulfillmentType.delivery
                      ? formatNaira(_deliveryFee)
                      : 'Free',
                ),
                const Divider(height: 20),
                _summaryRow(
                  'Total',
                  formatNaira(total),
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Place Order',
            icon: Icons.check_circle_rounded,
            onPressed: cart.items.isEmpty ? null : _placeOrder,
            loading: _loading,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 16 : 14,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 18 : 14,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
            color: emphasize ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _BankTransferDetails extends StatelessWidget {
  final BankAccount account;
  const _BankTransferDetails({required this.account});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transfer to:',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 10),
          _row('Bank', account.bankName),
          _row('Account Name', account.accountName),
          Row(
            children: [
              Expanded(
                child: _row('Account Number', account.accountNumber),
              ),
              IconButton(
                tooltip: 'Copy account number',
                icon: const Icon(Icons.copy_rounded,
                    size: 18, color: AppColors.primary),
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: account.accountNumber));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account number copied'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'After transfer, please keep your receipt. Your order will be '
            'confirmed once we receive payment.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(width: 6),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
