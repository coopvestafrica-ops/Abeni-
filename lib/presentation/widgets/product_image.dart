import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Displays a product image from either a local asset path (prefix
/// `assets/`) or a remote network URL. Provides a consistent placeholder and
/// error fallback.
class ProductImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  bool get _isAsset =>
      imageUrl.startsWith('assets/') || imageUrl.startsWith('asset://');

  @override
  Widget build(BuildContext context) {
    final error = Container(
      color: AppColors.divider.withOpacity(0.3),
      child: const Center(
        child: Icon(Icons.shopping_basket_rounded,
            size: 48, color: AppColors.textMuted),
      ),
    );
    final placeholder = Container(color: AppColors.divider.withOpacity(0.3));
    if (_isAsset) {
      final path = imageUrl.replaceFirst('asset://', '');
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => error,
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => error,
    );
  }
}
