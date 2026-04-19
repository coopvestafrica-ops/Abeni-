/// Static reference data for Abeni Mart.
class AppConstants {
  AppConstants._();

  static const String appName = 'Abeni Mart';
  static const String appTagline = 'Your Neighbourhood Foodstuff Market';
  static const String currencySymbol = '\u20a6'; // ₦

  /// Measurement units supported across the catalog.
  /// Congo units are used for major grain / staple products.
  static const List<String> congoUnits = [
    'Congo',
    'Half Congo',
    'Paint Bucket',
    'Half Paint',
    'Bag',
  ];

  /// Pack-style units used for packaged / bottled goods.
  static const List<String> packUnits = [
    'Piece',
    'Pack',
    'Carton',
    'Bottle',
    'Sachet',
  ];

  /// All possible units — used in admin-style product creation.
  static List<String> get allUnits => [...congoUnits, ...packUnits, 'Derica'];

  /// Product categories shown on the home screen.
  static const List<CategoryMeta> categories = [
    CategoryMeta(id: 'rice', name: 'Rice', emoji: '🍚'),
    CategoryMeta(id: 'beans', name: 'Beans', emoji: '🫘'),
    CategoryMeta(id: 'garri', name: 'Garri', emoji: '🥣'),
    CategoryMeta(id: 'sugar', name: 'Sugar', emoji: '🧂'),
    CategoryMeta(id: 'grains', name: 'Grains', emoji: '🌾'),
    CategoryMeta(id: 'pasta', name: 'Pasta', emoji: '🍝'),
    CategoryMeta(id: 'noodles', name: 'Noodles', emoji: '🍜'),
    CategoryMeta(id: 'beverages', name: 'Beverages', emoji: '🥤'),
    CategoryMeta(id: 'oil', name: 'Cooking Oil', emoji: '🫒'),
    CategoryMeta(id: 'flour', name: 'Flour', emoji: '🌾'),
    CategoryMeta(id: 'semovita', name: 'Semovita', emoji: '🥘'),
    CategoryMeta(id: 'seasonings', name: 'Seasonings', emoji: '🧄'),
    CategoryMeta(id: 'others', name: 'Others', emoji: '🛒'),
  ];
}

class CategoryMeta {
  final String id;
  final String name;
  final String emoji;
  const CategoryMeta({
    required this.id,
    required this.name,
    required this.emoji,
  });
}
