import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_unit.dart';
import '../../providers/providers.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/product_image.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  ProductUnit? _selected;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    if (widget.product.units.isNotEmpty) {
      _selected = widget.product.units.firstWhere(
        (u) => u.inStock,
        orElse: () => widget.product.units.first,
      );
    }
  }

  void _changeQty(int delta) {
    if (_selected == null) return;
    final next = _qty + delta;
    if (next < 1) return;
    if (next > _selected!.stock && _selected!.stock > 0) return;
    setState(() => _qty = next);
  }

  Future<void> _addToCart() async {
    final unit = _selected;
    if (unit == null) return;
    ref.read(cartProvider.notifier).addItem(widget.product, unit, _qty);
    await Fluttertoast.showToast(
      msg: 'Added $_qty × ${unit.unitName} ${widget.product.name} to cart',
      backgroundColor: AppColors.primaryDark,
      textColor: Colors.white,
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final unit = _selected;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                child: ProductImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            leading: _CircleIcon(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (unit != null)
                    Text(
                      '${formatNaira(unit.price)} / ${unit.unitName}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    product.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Select Unit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      for (final u in product.units)
                        _UnitOption(
                          unit: u,
                          selected: _selected?.unitName == u.unitName,
                          onTap: u.inStock
                              ? () => setState(() {
                                    _selected = u;
                                    _qty = 1;
                                  })
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _QtyButton(
                        icon: Icons.remove_rounded,
                        onTap: () => _changeQty(-1),
                      ),
                      Container(
                        width: 56,
                        alignment: Alignment.center,
                        child: Text(
                          '$_qty',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _QtyButton(
                        icon: Icons.add_rounded,
                        onTap: () => _changeQty(1),
                      ),
                      const Spacer(),
                      if (unit != null)
                        Text(
                          unit.stock > 0 ? '${unit.stock} in stock' : 'Out of stock',
                          style: TextStyle(
                            color: unit.stock > 0
                                ? AppColors.textSecondary
                                : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (unit != null)
                    _TotalRow(total: unit.price * _qty),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Add to cart',
                    icon: Icons.shopping_bag_rounded,
                    onPressed: (unit == null || !unit.inStock) ? null : _addToCart,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _UnitOption extends StatelessWidget {
  final ProductUnit unit;
  final bool selected;
  final VoidCallback? onTap;
  const _UnitOption({
    required this.unit,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
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
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.divider,
                    width: 2,
                  ),
                  color: selected ? AppColors.primary : Colors.white,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  unit.unitName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: disabled
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                formatNaira(unit.price),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: disabled ? AppColors.textMuted : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final double total;
  const _TotalRow({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text(
            'Subtotal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            formatNaira(total),
            style: const TextStyle(
              fontSize: 20,
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
