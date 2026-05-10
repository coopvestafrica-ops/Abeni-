import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_unit.dart';
import '../../../presentation/widgets/product_image.dart';
import '../../data/admin_providers.dart';

/// All product images bundled in assets/images/products/.
/// Update this list whenever you add new images to the folder.
const _kProductAssets = [
  'assets/images/products/annyb_spag.jpg',
  'assets/images/products/beans_oloyin.jpg',
  'assets/images/products/beans_white.jpg',
  'assets/images/products/bournvita_refill.jpg',
  'assets/images/products/bournvita_sachet.jpg',
  'assets/images/products/close_up.jpg',
  'assets/images/products/colgate_herbal.jpg',
  'assets/images/products/derica_paste.jpg',
  'assets/images/products/dettol_cool.jpg',
  'assets/images/products/dettol_original.jpg',
  'assets/images/products/emperor_25l.jpg',
  'assets/images/products/eva_soap.jpg',
  'assets/images/products/flour.jpg',
  'assets/images/products/garri.jpg',
  'assets/images/products/gino_paste.jpg',
  'assets/images/products/golden_morn.jpg',
  'assets/images/products/gp_jollof.jpg',
  'assets/images/products/gp_noodles.jpg',
  'assets/images/products/gp_soya_oil.jpg',
  'assets/images/products/hot_pepper.jpg',
  'assets/images/products/indomie_super.jpg',
  'assets/images/products/king_oil_1000.jpg',
  'assets/images/products/maggi_know.jpg',
  'assets/images/products/magnate_tomato.jpg',
  'assets/images/products/milo_3in1.jpg',
  'assets/images/products/milo_400.jpg',
  'assets/images/products/milo_800.jpg',
  'assets/images/products/nasco_cornflakes.jpg',
  'assets/images/products/nittol.jpg',
  'assets/images/products/oralb.jpg',
  'assets/images/products/party_jollof.jpg',
  'assets/images/products/peak_refill.jpg',
  'assets/images/products/peak_sachet.jpg',
  'assets/images/products/pepsodent_123.jpg',
  'assets/images/products/pepsodent_ord.jpg',
  'assets/images/products/rice.jpg',
  'assets/images/products/semovita_10kg.jpg',
  'assets/images/products/semovita_2kg.jpg',
  'assets/images/products/semovita_5kg.jpg',
  'assets/images/products/septo.jpg',
  'assets/images/products/spaghetti_gp_8mm.jpg',
  'assets/images/products/sugar.jpg',
  'assets/images/products/three_crown_can.jpg',
  'assets/images/products/three_crown_refill.jpg',
  'assets/images/products/three_crown_sachet.jpg',
  'assets/images/products/tissue_paper.jpg',
  'assets/images/products/top_tea.jpg',
  'assets/images/products/waw.jpg',
];

/// Turns an asset path like `assets/images/products/garri.jpg`
/// into a readable label like `Garri`.
String _labelFromAsset(String path) {
  final filename = path.split('/').last; // garri.jpg
  final noExt = filename.contains('.')
      ? filename.substring(0, filename.lastIndexOf('.'))
      : filename; // garri
  return noExt
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

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
  String _imageUrl = '';
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
      _imageUrl = p.imageUrl;
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
        imageUrl: _imageUrl.trim(),
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

  Future<void> _pickImage() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImagePickerSheet(current: _imageUrl),
    );
    if (picked != null) {
      setState(() => _imageUrl = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageUrl.isNotEmpty;
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

          // ── Image picker ──────────────────────────────────────────
          const Text('Product image',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.divider.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ProductImage(imageUrl: _imageUrl, fit: BoxFit.cover),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: _ChangeImageBadge(),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 40, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text('Tap to choose an image',
                            style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
            ),
          ),
          // ── End image picker ──────────────────────────────────────
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

class _ChangeImageBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ImagePickerSheet extends StatefulWidget {
  const _ImagePickerSheet({required this.current});
  final String current;

  @override
  State<_ImagePickerSheet> createState() => _ImagePickerSheetState();
}

class _ImagePickerSheetState extends State<_ImagePickerSheet> {
  late String _selected;
  final _customController = TextEditingController();
  bool _showCustom = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    // If the current value is not one of the bundled assets, show custom field
    if (_selected.isNotEmpty && !_kProductAssets.contains(_selected)) {
      _customController.text = _selected;
      _showCustom = true;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      height: mq.size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('Choose an image',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_selected.isNotEmpty ? _selected : null),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _kProductAssets.length + 1,
              itemBuilder: (ctx, index) {
                // Last cell = custom URL option
                if (index == _kProductAssets.length) {
                  return _CustomUrlCell(
                    controller: _customController,
                    expanded: _showCustom,
                    onTap: () => setState(() => _showCustom = !_showCustom),
                    onConfirm: () {
                      final v = _customController.text.trim();
                      if (v.isNotEmpty) {
                        setState(() {
                          _selected = v;
                          _showCustom = false;
                        });
                      }
                    },
                  );
                }
                final path = _kProductAssets[index];
                final isSelected = _selected == path;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selected = path;
                    _showCustom = false;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(path, fit: BoxFit.cover),
                        if (isSelected)
                          Container(
                            color: AppColors.primary.withOpacity(0.15),
                            child: const Center(
                              child: Icon(Icons.check_circle,
                                  color: AppColors.primary, size: 28),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 3),
                            color: Colors.black.withOpacity(0.45),
                            child: Text(
                              _labelFromAsset(path),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomUrlCell extends StatelessWidget {
  const _CustomUrlCell({
    required this.controller,
    required this.expanded,
    required this.onTap,
    required this.onConfirm,
  });

  final TextEditingController controller;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.all(8),
        child: expanded
            ? Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(fontSize: 11),
                      decoration: const InputDecoration(
                        hintText: 'Paste URL…',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4)),
                      child: const Text('Use', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.link, color: AppColors.textMuted),
                  SizedBox(height: 4),
                  Text('Custom\nURL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
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
          const SizedBox(height: 8),
          // Quick restock row — tap to add to current stock without typing.
          Row(
            children: [
              const Text(
                'Quick restock:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              for (final amount in [10, 25, 50]) ...[
                _RestockChip(
                  amount: amount,
                  onTap: () {
                    final current =
                        int.tryParse(draft.stock.text.trim()) ?? 0;
                    draft.stock.text = (current + amount).toString();
                    onChanged();
                  },
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RestockChip extends StatelessWidget {
  const _RestockChip({required this.amount, required this.onTap});

  final int amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Text(
          '+$amount',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
