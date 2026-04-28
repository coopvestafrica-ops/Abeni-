import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_unit.dart';
import '../../data/admin_providers.dart';

class ProductEditScreen extends ConsumerStatefulWidget {
  const ProductEditScreen({super.key, this.existing});

  final Product? existing;

  @override
  ConsumerState<ProductEditScreen> createState() =>
      _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  String _categoryId = AppConstants.categories.first.id;
  bool _featured = false;
  late List<_UnitDraft> _units;
  bool _busy = false;

  static const _uuid = Uuid();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _name.text = p.name;
      _description.text = p.description;
      _imageUrl.text = p.imageUrl;
      _categoryId = AppConstants.categories.any((c) => c.id == p.categoryId)
          ? p.categoryId
          : AppConstants.categories.first.id;
      _featured = p.featured;
      _units = p.units.map(_UnitDraft.fromUnit).toList();
    } else {
      _units = [_UnitDraft.empty()];
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _imageUrl.dispose();
    for (final u in _units) {
      u.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _toast('Product name is required');
      return;
    }
    final units = _units
        .where((u) => u.name.trim().isNotEmpty)
        .map((u) => u.toUnit())
        .toList();
    if (units.isEmpty) {
      _toast('Add at least one unit (price + stock)');
      return;
    }
    setState(() => _busy = true);
    try {
      final product = Product(
        id: widget.existing?.id ?? _uuid.v4().substring(0, 8),
        name: _name.text.trim(),
        categoryId: _categoryId,
        description: _description.text.trim(),
        imageUrl: _imageUrl.text.trim(),
        featured: _featured,
        units: units,
      );
      await ref.read(adminRepositoryProvider).upsertProduct(product);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isEditing ? 'Product updated' : 'Product created'),
            backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final p = widget.existing;
    if (p == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this product?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).deleteProduct(p.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit product' : 'New product'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Product name',
              prefixIcon: Icon(Icons.shopping_basket_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _categoryId,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final c in AppConstants.categories)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) =>
                setState(() => _categoryId = v ?? _categoryId),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _imageUrl,
            decoration: const InputDecoration(
              labelText: 'Image URL or asset path',
              hintText: 'assets/images/products/... or https://...',
              prefixIcon: Icon(Icons.image_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _featured,
            onChanged: (v) => setState(() => _featured = v),
            title: const Text('Featured product'),
            subtitle: const Text('Show in the home carousel'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          const Text('Units & prices',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (var i = 0; i < _units.length; i++)
            _UnitEditor(
              draft: _units[i],
              onRemove: _units.length == 1
                  ? null
                  : () {
                      setState(() {
                        _units.removeAt(i).dispose();
                      });
                    },
              onChanged: () => setState(() {}),
            ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _units.add(_UnitDraft.empty())),
            icon: const Icon(Icons.add),
            label: const Text('Add unit'),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _busy ? null : _save,
            icon: _busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isEditing ? 'Save changes' : 'Create product'),
          ),
        ],
      ),
    );
  }
}

class _UnitDraft {
  String name;
  final TextEditingController price;
  final TextEditingController stock;

  _UnitDraft({
    required this.name,
    required this.price,
    required this.stock,
  });

  factory _UnitDraft.empty() => _UnitDraft(
        name: AppConstants.allUnits.first,
        price: TextEditingController(),
        stock: TextEditingController(text: '0'),
      );

  factory _UnitDraft.fromUnit(ProductUnit u) => _UnitDraft(
        name: u.unitName,
        price: TextEditingController(text: u.price.toStringAsFixed(0)),
        stock: TextEditingController(text: u.stock.toString()),
      );

  ProductUnit toUnit() => ProductUnit(
        unitName: name,
        price: double.tryParse(price.text.trim()) ?? 0,
        stock: int.tryParse(stock.text.trim()) ?? 0,
      );

  void dispose() {
    price.dispose();
    stock.dispose();
  }
}

class _UnitEditor extends StatelessWidget {
  const _UnitEditor({
    required this.draft,
    required this.onRemove,
    required this.onChanged,
  });

  final _UnitDraft draft;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: AppConstants.allUnits.contains(draft.name)
                      ? draft.name
                      : AppConstants.allUnits.first,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: [
                    for (final u in AppConstants.allUnits)
                      DropdownMenuItem(value: u, child: Text(u)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      draft.name = v;
                      onChanged();
                    }
                  },
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, color: AppColors.error),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.price,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixText: '${AppConstants.currencySymbol} ',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: draft.stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
