import '../models/product.dart';
import '../models/product_unit.dart';

/// Seed catalog used when the app runs in demo mode (no Firebase configured),
/// and for one-tap Firestore seeding from the Profile screen.
class SampleCatalog {
  SampleCatalog._();

  static const String _placeholderImage =
      'https://images.unsplash.com/photo-1505253716362-afaea1d3d1af?w=800';

  static final List<Product> products = [
    Product(
      id: 'rice_001',
      name: 'Premium Long Grain Rice',
      categoryId: 'rice',
      description:
          'Stone-free, premium long grain rice. Cooks fluffy — perfect for jollof, fried rice or everyday meals.',
      imageUrl:
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800',
      featured: true,
      units: const [
        ProductUnit(unitName: 'Congo', price: 2500, stock: 120),
        ProductUnit(unitName: 'Half Congo', price: 1300, stock: 80),
        ProductUnit(unitName: 'Paint Bucket', price: 5200, stock: 40),
        ProductUnit(unitName: 'Bag', price: 78000, stock: 25),
      ],
    ),
    Product(
      id: 'beans_001',
      name: 'Honey Beans (Oloyin)',
      categoryId: 'beans',
      description:
          'Sweet Oloyin beans — clean, well-graded and ready for moi-moi, akara or porridge.',
      imageUrl:
          'https://images.unsplash.com/photo-1611575619236-12f74c5bbdaf?w=800',
      featured: true,
      units: const [
        ProductUnit(unitName: 'Congo', price: 2800, stock: 90),
        ProductUnit(unitName: 'Half Congo', price: 1450, stock: 60),
        ProductUnit(unitName: 'Paint Bucket', price: 5800, stock: 30),
        ProductUnit(unitName: 'Bag', price: 86000, stock: 18),
      ],
    ),
    Product(
      id: 'garri_001',
      name: 'White Garri Ijebu',
      categoryId: 'garri',
      description:
          'Dry, crunchy Ijebu garri. Great for eba, soaking or cassava flakes.',
      imageUrl:
          'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800',
      units: const [
        ProductUnit(unitName: 'Congo', price: 1600, stock: 100),
        ProductUnit(unitName: 'Half Congo', price: 850, stock: 70),
        ProductUnit(unitName: 'Paint Bucket', price: 3400, stock: 45),
        ProductUnit(unitName: 'Bag', price: 52000, stock: 20),
      ],
    ),
    Product(
      id: 'sugar_001',
      name: 'Granulated Sugar',
      categoryId: 'sugar',
      description:
          'Pure refined granulated sugar. Clean, fast-dissolving — ideal for tea, baking and drinks.',
      imageUrl:
          'https://images.unsplash.com/photo-1581006852262-e4307cf6283a?w=800',
      featured: true,
      units: const [
        ProductUnit(unitName: 'Congo', price: 2200, stock: 85),
        ProductUnit(unitName: 'Half Congo', price: 1150, stock: 60),
        ProductUnit(unitName: 'Paint Bucket', price: 4500, stock: 30),
        ProductUnit(unitName: 'Bag', price: 68000, stock: 15),
      ],
    ),
    Product(
      id: 'semovita_001',
      name: 'Semovita',
      categoryId: 'semovita',
      description:
          'Soft, smooth semovita — perfect swallow with any soup.',
      imageUrl:
          'https://images.unsplash.com/photo-1604908554049-01a1bf8b79f5?w=800',
      units: const [
        ProductUnit(unitName: 'Congo', price: 2000, stock: 70),
        ProductUnit(unitName: 'Half Congo', price: 1050, stock: 55),
        ProductUnit(unitName: 'Bag', price: 60000, stock: 12),
      ],
    ),
    Product(
      id: 'flour_001',
      name: 'All Purpose Flour',
      categoryId: 'flour',
      description:
          'Finely milled all-purpose flour for baking, frying and general cooking.',
      imageUrl:
          'https://images.unsplash.com/photo-1608198093002-ad4e005484ec?w=800',
      units: const [
        ProductUnit(unitName: 'Congo', price: 2400, stock: 60),
        ProductUnit(unitName: 'Half Congo', price: 1250, stock: 40),
        ProductUnit(unitName: 'Bag', price: 72000, stock: 10),
      ],
    ),
    Product(
      id: 'oil_001',
      name: 'Pure Vegetable Oil',
      categoryId: 'oil',
      description:
          'Pure, light and odourless vegetable oil — great for frying and everyday cooking.',
      imageUrl:
          'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=800',
      featured: true,
      units: const [
        ProductUnit(unitName: 'Bottle', price: 3500, stock: 120),
        ProductUnit(unitName: 'Carton', price: 38000, stock: 25),
      ],
    ),
    Product(
      id: 'noodles_001',
      name: 'Indomie Instant Noodles',
      categoryId: 'noodles',
      description:
          'The classic family favourite — quick, tasty instant noodles.',
      imageUrl:
          'https://images.unsplash.com/photo-1555126634-323283e090fa?w=800',
      units: const [
        ProductUnit(unitName: 'Pack', price: 450, stock: 300),
        ProductUnit(unitName: 'Carton', price: 18500, stock: 30),
      ],
    ),
    Product(
      id: 'spaghetti_001',
      name: 'Golden Penny Spaghetti',
      categoryId: 'pasta',
      description:
          'Premium quality spaghetti — cooks firm and fresh.',
      imageUrl:
          'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=800',
      units: const [
        ProductUnit(unitName: 'Pack', price: 900, stock: 200),
        ProductUnit(unitName: 'Carton', price: 19500, stock: 20),
      ],
    ),
    Product(
      id: 'milo_001',
      name: 'Milo Chocolate Drink',
      categoryId: 'beverages',
      description:
          'Nourishing chocolate energy drink — loved by the whole family.',
      imageUrl: _placeholderImage,
      units: const [
        ProductUnit(unitName: 'Sachet', price: 120, stock: 500),
        ProductUnit(unitName: 'Pack', price: 2200, stock: 80),
        ProductUnit(unitName: 'Carton', price: 32000, stock: 12),
      ],
    ),
    Product(
      id: 'maggi_001',
      name: 'Maggi Star Seasoning Cubes',
      categoryId: 'seasonings',
      description:
          'Classic seasoning cubes — the secret behind every great Nigerian meal.',
      imageUrl: _placeholderImage,
      units: const [
        ProductUnit(unitName: 'Sachet', price: 100, stock: 400),
        ProductUnit(unitName: 'Pack', price: 1800, stock: 100),
      ],
    ),
    Product(
      id: 'millet_001',
      name: 'Millet Grains',
      categoryId: 'grains',
      description:
          'Clean, well-dried millet grains — great for pap, kunu and porridge.',
      imageUrl: _placeholderImage,
      units: const [
        ProductUnit(unitName: 'Congo', price: 1800, stock: 60),
        ProductUnit(unitName: 'Half Congo', price: 950, stock: 40),
        ProductUnit(unitName: 'Bag', price: 55000, stock: 8),
      ],
    ),
  ];
}
