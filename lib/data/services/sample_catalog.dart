import '../models/product.dart';
import '../models/product_unit.dart';

/// Seed catalog used when the app runs in demo mode (no Firebase configured),
/// and for one-tap Firestore seeding from the Profile screen.
///
/// Follows the Abeni Mart product & unit rules:
/// - Staple foods (Rice, Beans, Garri, Sugar, Flour) → Congo / Half Congo /
///   Paint Bucket / Half Paint / Bag. No Piece.
/// - Semovita → Bag only.
/// - Milk & Beverages → Sachet / Pack / Carton.
/// - Cereals / Noodles / Spaghetti → Piece / Carton.
/// - Tomato & Seasonings → Piece / Pack / Carton.
/// - Cooking Oil → Bottle / Keg / Carton.
/// - Detergents & Cleaning → Piece / Pack / Carton.
/// - Personal Care → Piece / Tube / Bar / Pack / Carton.
/// - Tissue & Paper → Roll / Pack.
class SampleCatalog {
  SampleCatalog._();

  // --- Image URLs (Unsplash — royalty free) ---
  static const String _img =
      'https://images.unsplash.com/photo-1505253716362-afaea1d3d1af?w=800';
  static const String _imgRice =
      'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800';
  static const String _imgBeans =
      'https://images.unsplash.com/photo-1611575619236-12f74c5bbdaf?w=800';
  static const String _imgGarri =
      'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800';
  static const String _imgSugar =
      'https://images.unsplash.com/photo-1581006852262-e4307cf6283a?w=800';
  static const String _imgFlour =
      'https://images.unsplash.com/photo-1608198093002-ad4e005484ec?w=800';
  static const String _imgSemo =
      'https://images.unsplash.com/photo-1604908554049-01a1bf8b79f5?w=800';
  static const String _imgMilk =
      'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=800';
  static const String _imgCereal =
      'https://images.unsplash.com/photo-1517686469429-8bdb88b9f907?w=800';
  static const String _imgNoodles =
      'https://images.unsplash.com/photo-1555126634-323283e090fa?w=800';
  static const String _imgSpag =
      'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=800';
  static const String _imgTomato =
      'https://images.unsplash.com/photo-1546470427-e26264be0b0d?w=800';
  static const String _imgOil =
      'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=800';
  static const String _imgSoap =
      'https://images.unsplash.com/photo-1585238342024-78d387f4a707?w=800';
  static const String _imgCare =
      'https://images.unsplash.com/photo-1559591935-c6c92c6c6c52?w=800';
  static const String _imgTissue =
      'https://images.unsplash.com/photo-1583947582886-f40ec95dd752?w=800';

  static final List<Product> products = [
    // ========================================================
    // CATEGORY 1 — CONGO FOOD ITEMS (Congo / Half Congo /
    //             Paint Bucket / Half Paint / Bag)
    // ========================================================
    Product(
      id: 'rice_001',
      name: 'Premium Long Grain Rice',
      categoryId: 'rice',
      description:
          'Stone-free premium long grain rice. Cooks fluffy — perfect for jollof, fried rice or everyday meals.',
      imageUrl: _imgRice,
      featured: true,
      units: _congoUnits(congo: 2500, halfCongo: 1300, paint: 5200, halfPaint: 2700, bag: 78000),
    ),
    Product(
      id: 'beans_white',
      name: 'White Beans',
      categoryId: 'beans',
      description:
          'Clean, well-graded white beans. Great for moi-moi, akara and porridge.',
      imageUrl: _imgBeans,
      featured: true,
      units: _congoUnits(congo: 2600, halfCongo: 1350, paint: 5400, halfPaint: 2800, bag: 82000),
    ),
    Product(
      id: 'beans_oloyin',
      name: 'Oloyin (Honey) Beans',
      categoryId: 'beans',
      description:
          'Sweet Oloyin beans — soft, flavourful and perfect for beans porridge.',
      imageUrl: _imgBeans,
      units: _congoUnits(congo: 2800, halfCongo: 1450, paint: 5800, halfPaint: 3000, bag: 86000),
    ),
    Product(
      id: 'beans_drum',
      name: 'Drum Beans',
      categoryId: 'beans',
      description:
          'Full-bodied drum beans — clean and well-dried.',
      imageUrl: _imgBeans,
      units: _congoUnits(congo: 2700, halfCongo: 1400, paint: 5600, halfPaint: 2900, bag: 84000),
    ),
    Product(
      id: 'garri_001',
      name: 'White Garri Ijebu',
      categoryId: 'garri',
      description:
          'Dry, crunchy Ijebu garri — great for eba or soaking.',
      imageUrl: _imgGarri,
      units: _congoUnits(congo: 1600, halfCongo: 850, paint: 3400, halfPaint: 1750, bag: 52000),
    ),
    Product(
      id: 'sugar_001',
      name: 'Granulated Sugar',
      categoryId: 'sugar',
      description:
          'Pure refined granulated sugar — clean, fast-dissolving.',
      imageUrl: _imgSugar,
      featured: true,
      units: _congoUnits(congo: 2200, halfCongo: 1150, paint: 4500, halfPaint: 2300, bag: 68000),
    ),
    Product(
      id: 'flour_001',
      name: 'All Purpose Flour',
      categoryId: 'flour',
      description:
          'Finely milled all-purpose flour for baking, frying and general cooking.',
      imageUrl: _imgFlour,
      units: _congoUnits(congo: 2400, halfCongo: 1250, paint: 4900, halfPaint: 2500, bag: 72000),
    ),

    // ========================================================
    // CATEGORY 2 — SEMOVITA (Bag only)
    // ========================================================
    Product(
      id: 'semovita_10kg',
      name: 'Semovita 10kg',
      categoryId: 'semovita',
      description:
          'Soft, smooth semovita — perfect swallow with any soup. 10kg bag.',
      imageUrl: _imgSemo,
      featured: true,
      units: const [
        ProductUnit(unitName: 'Bag', price: 14500, stock: 40),
      ],
    ),
    Product(
      id: 'semovita_5kg',
      name: 'Semovita 5kg',
      categoryId: 'semovita',
      description:
          'Family size semovita — 5kg bag.',
      imageUrl: _imgSemo,
      units: const [
        ProductUnit(unitName: 'Bag', price: 7800, stock: 60),
      ],
    ),

    // ========================================================
    // CATEGORY 3 — MILK & BEVERAGES (Sachet / Pack / Carton)
    // ========================================================
    Product(
      id: 'milk_3in1',
      name: 'Milk 3-in-1',
      categoryId: 'beverages',
      description: 'Convenient 3-in-1 sachet — milk, sugar and cocoa in one.',
      imageUrl: _imgMilk,
      units: const [
        ProductUnit(unitName: 'Sachet', price: 100, stock: 500),
        ProductUnit(unitName: 'Pack', price: 1800, stock: 90),
        ProductUnit(unitName: 'Carton', price: 26000, stock: 12),
      ],
    ),
    Product(
      id: 'peak_sachet',
      name: 'Peak Milk (Sachet)',
      categoryId: 'beverages',
      description: 'Full cream Peak milk — convenient sachet size.',
      imageUrl: _imgMilk,
      featured: true,
      units: const [
        ProductUnit(unitName: 'Sachet', price: 150, stock: 600),
        ProductUnit(unitName: 'Pack', price: 2400, stock: 80),
        ProductUnit(unitName: 'Carton', price: 34000, stock: 10),
      ],
    ),
    Product(
      id: 'peak_refill',
      name: 'Peak Milk (Refill)',
      categoryId: 'beverages',
      description: 'Economy Peak milk refill pack.',
      imageUrl: _imgMilk,
      units: const [
        ProductUnit(unitName: 'Pack', price: 2200, stock: 70),
        ProductUnit(unitName: 'Carton', price: 31000, stock: 10),
      ],
    ),
    Product(
      id: 'three_crown_milk',
      name: 'Three Crown Milk',
      categoryId: 'beverages',
      description: 'Three Crown instant full cream milk — sachet.',
      imageUrl: _imgMilk,
      units: const [
        ProductUnit(unitName: 'Sachet', price: 140, stock: 500),
        ProductUnit(unitName: 'Pack', price: 2300, stock: 80),
        ProductUnit(unitName: 'Carton', price: 32500, stock: 10),
      ],
    ),
    Product(
      id: 'three_crown_refill',
      name: 'Three Crown Refill',
      categoryId: 'beverages',
      description: 'Three Crown economy refill pack.',
      imageUrl: _imgMilk,
      units: const [
        ProductUnit(unitName: 'Pack', price: 2100, stock: 70),
        ProductUnit(unitName: 'Carton', price: 30000, stock: 10),
      ],
    ),
    Product(
      id: 'bournvita',
      name: 'Bournvita',
      categoryId: 'beverages',
      description: 'Cadbury Bournvita chocolate malt drink.',
      imageUrl: _imgMilk,
      units: const [
        ProductUnit(unitName: 'Pack', price: 3200, stock: 80),
        ProductUnit(unitName: 'Carton', price: 36000, stock: 12),
      ],
    ),
    Product(
      id: 'bournvita_refill',
      name: 'Bournvita Refill',
      categoryId: 'beverages',
      description: 'Bournvita economy refill pack.',
      imageUrl: _imgMilk,
      units: const [
        ProductUnit(unitName: 'Pack', price: 2800, stock: 80),
        ProductUnit(unitName: 'Carton', price: 32000, stock: 12),
      ],
    ),
    Product(
      id: 'milo_400',
      name: 'Milo 400g',
      categoryId: 'beverages',
      description: 'Milo chocolate drink — 400g tin.',
      imageUrl: _imgMilk,
      featured: true,
      units: const [
        ProductUnit(unitName: 'Piece', price: 2300, stock: 150),
        ProductUnit(unitName: 'Carton', price: 26000, stock: 12),
      ],
    ),
    Product(
      id: 'milo_800',
      name: 'Milo 800g',
      categoryId: 'beverages',
      description: 'Milo chocolate drink — 800g tin.',
      imageUrl: _imgMilk,
      units: const [
        ProductUnit(unitName: 'Piece', price: 4200, stock: 120),
        ProductUnit(unitName: 'Carton', price: 48000, stock: 10),
      ],
    ),
    Product(
      id: 'top_tea',
      name: 'Top Tea',
      categoryId: 'beverages',
      description: 'Top Tea — black tea bags.',
      imageUrl: _imgMilk,
      units: const [
        ProductUnit(unitName: 'Pack', price: 700, stock: 200),
        ProductUnit(unitName: 'Carton', price: 14000, stock: 15),
      ],
    ),

    // ========================================================
    // CATEGORY 4 — CEREALS (Piece / Carton)
    // ========================================================
    Product(
      id: 'nasco_cornflakes',
      name: 'Nasco Cornflakes',
      categoryId: 'cereals',
      description: 'Nasco cornflakes — crispy breakfast cereal.',
      imageUrl: _imgCereal,
      units: const [
        ProductUnit(unitName: 'Piece', price: 1800, stock: 120),
        ProductUnit(unitName: 'Carton', price: 32000, stock: 12),
      ],
    ),
    Product(
      id: 'gm_300',
      name: 'Golden Morn 300g',
      categoryId: 'cereals',
      description: 'Golden Morn maize and soya cereal — 300g.',
      imageUrl: _imgCereal,
      units: const [
        ProductUnit(unitName: 'Piece', price: 1200, stock: 150),
        ProductUnit(unitName: 'Carton', price: 25000, stock: 12),
      ],
    ),
    Product(
      id: 'gm_600',
      name: 'Golden Morn 600g',
      categoryId: 'cereals',
      description: 'Golden Morn — 600g family pack.',
      imageUrl: _imgCereal,
      units: const [
        ProductUnit(unitName: 'Piece', price: 2300, stock: 120),
        ProductUnit(unitName: 'Carton', price: 38000, stock: 10),
      ],
    ),
    Product(
      id: 'gm_900',
      name: 'Golden Morn 900g',
      categoryId: 'cereals',
      description: 'Golden Morn — 900g economy size.',
      imageUrl: _imgCereal,
      featured: true,
      units: const [
        ProductUnit(unitName: 'Piece', price: 3300, stock: 100),
        ProductUnit(unitName: 'Carton', price: 52000, stock: 10),
      ],
    ),

    // ========================================================
    // CATEGORY 5 — NOODLES & SPAGHETTI (Piece / Carton)
    // ========================================================
    Product(
      id: 'gp_noodles_ord',
      name: 'Golden Penny Noodles (Ordinary)',
      categoryId: 'noodles',
      description: 'Golden Penny instant noodles — classic chicken flavour.',
      imageUrl: _imgNoodles,
      units: const [
        ProductUnit(unitName: 'Piece', price: 350, stock: 500),
        ProductUnit(unitName: 'Carton', price: 14500, stock: 25),
      ],
    ),
    Product(
      id: 'gp_noodles_jollof',
      name: 'Golden Penny Noodles (Jollof)',
      categoryId: 'noodles',
      description: 'Golden Penny jollof flavour instant noodles.',
      imageUrl: _imgNoodles,
      units: const [
        ProductUnit(unitName: 'Piece', price: 380, stock: 450),
        ProductUnit(unitName: 'Carton', price: 15500, stock: 25),
      ],
    ),
    Product(
      id: 'indomie_super',
      name: 'Indomie Super Pack',
      categoryId: 'noodles',
      description: 'Indomie Super Pack — bigger size, same taste.',
      imageUrl: _imgNoodles,
      featured: true,
      units: const [
        ProductUnit(unitName: 'Piece', price: 500, stock: 500),
        ProductUnit(unitName: 'Carton', price: 18500, stock: 25),
      ],
    ),
    Product(
      id: 'spag_8mm',
      name: 'Spaghetti 8mm',
      categoryId: 'pasta',
      description: 'Thick spaghetti, 8mm cut — cooks firm.',
      imageUrl: _imgSpag,
      units: const [
        ProductUnit(unitName: 'Piece', price: 900, stock: 250),
        ProductUnit(unitName: 'Carton', price: 19500, stock: 20),
      ],
    ),
    Product(
      id: 'gp_spag_long',
      name: 'Golden Spaghetti Long',
      categoryId: 'pasta',
      description: 'Golden Penny long spaghetti — premium quality.',
      imageUrl: _imgSpag,
      units: const [
        ProductUnit(unitName: 'Piece', price: 950, stock: 220),
        ProductUnit(unitName: 'Carton', price: 20500, stock: 20),
      ],
    ),
    Product(
      id: 'annyb_spag',
      name: 'Anny B Spaghetti',
      categoryId: 'pasta',
      description: 'Anny B spaghetti — everyday family size.',
      imageUrl: _imgSpag,
      units: const [
        ProductUnit(unitName: 'Piece', price: 850, stock: 220),
        ProductUnit(unitName: 'Carton', price: 18500, stock: 20),
      ],
    ),

    // ========================================================
    // CATEGORY 6 — TOMATO & SEASONINGS (Piece / Pack / Carton)
    // ========================================================
    Product(
      id: 'gino_paste',
      name: 'Gino Tomato Paste',
      categoryId: 'seasonings',
      description: 'Gino tomato paste — rich and flavourful.',
      imageUrl: _imgTomato,
      units: const [
        ProductUnit(unitName: 'Piece', price: 250, stock: 600),
        ProductUnit(unitName: 'Pack', price: 2800, stock: 80),
        ProductUnit(unitName: 'Carton', price: 14500, stock: 18),
      ],
    ),
    Product(
      id: 'derica_paste',
      name: 'Derica Tomato Paste',
      categoryId: 'seasonings',
      description: 'Derica tomato paste — everyday jollof base.',
      imageUrl: _imgTomato,
      units: const [
        ProductUnit(unitName: 'Piece', price: 220, stock: 600),
        ProductUnit(unitName: 'Pack', price: 2500, stock: 80),
        ProductUnit(unitName: 'Carton', price: 12500, stock: 20),
      ],
    ),
    Product(
      id: 'party_jollof',
      name: 'Party Jollof Gino',
      categoryId: 'seasonings',
      description: 'Gino Party Jollof mix — the party-style tomato mix.',
      imageUrl: _imgTomato,
      featured: true,
      units: const [
        ProductUnit(unitName: 'Piece', price: 320, stock: 500),
        ProductUnit(unitName: 'Pack', price: 3400, stock: 70),
        ProductUnit(unitName: 'Carton', price: 16500, stock: 15),
      ],
    ),
    Product(
      id: 'magnate_tomato',
      name: 'Magnate Tomato',
      categoryId: 'seasonings',
      description: 'Magnate tomato paste — value for money.',
      imageUrl: _imgTomato,
      units: const [
        ProductUnit(unitName: 'Piece', price: 200, stock: 600),
        ProductUnit(unitName: 'Pack', price: 2200, stock: 80),
        ProductUnit(unitName: 'Carton', price: 11500, stock: 20),
      ],
    ),
    Product(
      id: 'hot_pepper',
      name: 'Hot Pepper',
      categoryId: 'seasonings',
      description: 'Dry ground hot pepper.',
      imageUrl: _imgTomato,
      units: const [
        ProductUnit(unitName: 'Piece', price: 300, stock: 400),
        ProductUnit(unitName: 'Pack', price: 3200, stock: 60),
        ProductUnit(unitName: 'Carton', price: 15000, stock: 12),
      ],
    ),
    Product(
      id: 'maggi_know',
      name: 'Maggi Know',
      categoryId: 'seasonings',
      description: 'Maggi Know seasoning cubes.',
      imageUrl: _imgTomato,
      units: const [
        ProductUnit(unitName: 'Piece', price: 100, stock: 800),
        ProductUnit(unitName: 'Pack', price: 1800, stock: 120),
        ProductUnit(unitName: 'Carton', price: 9500, stock: 18),
      ],
    ),

    // ========================================================
    // CATEGORY 7 — COOKING OIL (Bottle / Keg / Carton)
    // ========================================================
    Product(
      id: 'emperor_25l',
      name: 'Emperor Oil 25L',
      categoryId: 'oil',
      description: 'Emperor vegetable oil — 25L bulk keg.',
      imageUrl: _imgOil,
      featured: true,
      units: const [
        ProductUnit(unitName: 'Keg', price: 68000, stock: 15),
      ],
    ),
    Product(
      id: 'king_oil_1000',
      name: 'King Oil (1000ml × 12)',
      categoryId: 'oil',
      description: 'King Oil — 1L bottles, sold singly or by carton of 12.',
      imageUrl: _imgOil,
      units: const [
        ProductUnit(unitName: 'Bottle', price: 3800, stock: 120),
        ProductUnit(unitName: 'Carton', price: 42000, stock: 20),
      ],
    ),
    Product(
      id: 'gp_soya_oil',
      name: 'Golden Penny Soya Oil',
      categoryId: 'oil',
      description: 'Golden Penny soya oil — light, clean taste.',
      imageUrl: _imgOil,
      units: const [
        ProductUnit(unitName: 'Bottle', price: 4200, stock: 100),
        ProductUnit(unitName: 'Keg', price: 52000, stock: 20),
        ProductUnit(unitName: 'Carton', price: 46000, stock: 15),
      ],
    ),

    // ========================================================
    // CATEGORY 8 — DETERGENTS & CLEANING (Piece / Pack / Carton)
    // ========================================================
    Product(
      id: 'nittol_sachet',
      name: 'Nittol Sachet Detergent',
      categoryId: 'cleaning',
      description: 'Nittol sachet detergent — strong cleaning power.',
      imageUrl: _imgSoap,
      units: const [
        ProductUnit(unitName: 'Piece', price: 80, stock: 1000),
        ProductUnit(unitName: 'Pack', price: 1500, stock: 150),
        ProductUnit(unitName: 'Carton', price: 8500, stock: 25),
      ],
    ),
    Product(
      id: 'waw',
      name: 'WAW Detergent',
      categoryId: 'cleaning',
      description: 'WAW detergent — economy pack.',
      imageUrl: _imgSoap,
      units: const [
        ProductUnit(unitName: 'Piece', price: 350, stock: 400),
        ProductUnit(unitName: 'Pack', price: 3800, stock: 60),
        ProductUnit(unitName: 'Carton', price: 21500, stock: 15),
      ],
    ),
    Product(
      id: 'dettol_cool',
      name: 'Dettol Cool',
      categoryId: 'cleaning',
      description: 'Dettol Cool antiseptic liquid.',
      imageUrl: _imgSoap,
      units: const [
        ProductUnit(unitName: 'Piece', price: 1800, stock: 120),
        ProductUnit(unitName: 'Pack', price: 6500, stock: 40),
        ProductUnit(unitName: 'Carton', price: 42000, stock: 10),
      ],
    ),
    Product(
      id: 'dettol_original',
      name: 'Dettol Original',
      categoryId: 'cleaning',
      description: 'Dettol Original antiseptic liquid.',
      imageUrl: _imgSoap,
      featured: true,
      units: const [
        ProductUnit(unitName: 'Piece', price: 1700, stock: 120),
        ProductUnit(unitName: 'Pack', price: 6300, stock: 40),
        ProductUnit(unitName: 'Carton', price: 41000, stock: 10),
      ],
    ),
    Product(
      id: 'septo',
      name: 'Septo Disinfectant',
      categoryId: 'cleaning',
      description: 'Septo disinfectant — keeps your home germ free.',
      imageUrl: _imgSoap,
      units: const [
        ProductUnit(unitName: 'Piece', price: 900, stock: 200),
        ProductUnit(unitName: 'Pack', price: 4500, stock: 45),
        ProductUnit(unitName: 'Carton', price: 22000, stock: 12),
      ],
    ),

    // ========================================================
    // CATEGORY 9 — PERSONAL CARE
    //    (Piece / Tube / Bar / Pack / Carton)
    // ========================================================
    Product(
      id: 'colgate_herbal',
      name: 'Colgate Herbal',
      categoryId: 'personal_care',
      description: 'Colgate Herbal toothpaste — natural ingredients.',
      imageUrl: _imgCare,
      units: const [
        ProductUnit(unitName: 'Tube', price: 950, stock: 300),
        ProductUnit(unitName: 'Pack', price: 5200, stock: 60),
        ProductUnit(unitName: 'Carton', price: 32000, stock: 12),
      ],
    ),
    Product(
      id: 'pepsodent_123',
      name: 'Pepsodent 123',
      categoryId: 'personal_care',
      description: 'Pepsodent 123 toothpaste.',
      imageUrl: _imgCare,
      units: const [
        ProductUnit(unitName: 'Tube', price: 1100, stock: 280),
        ProductUnit(unitName: 'Pack', price: 6000, stock: 55),
        ProductUnit(unitName: 'Carton', price: 35000, stock: 12),
      ],
    ),
    Product(
      id: 'pepsodent_ord',
      name: 'Pepsodent Ordinary',
      categoryId: 'personal_care',
      description: 'Pepsodent standard toothpaste.',
      imageUrl: _imgCare,
      units: const [
        ProductUnit(unitName: 'Tube', price: 900, stock: 300),
        ProductUnit(unitName: 'Pack', price: 5000, stock: 60),
        ProductUnit(unitName: 'Carton', price: 29500, stock: 12),
      ],
    ),
    Product(
      id: 'oralb_large',
      name: 'Oral B Large',
      categoryId: 'personal_care',
      description: 'Oral B toothbrush — large.',
      imageUrl: _imgCare,
      units: const [
        ProductUnit(unitName: 'Piece', price: 700, stock: 400),
        ProductUnit(unitName: 'Pack', price: 4000, stock: 70),
        ProductUnit(unitName: 'Carton', price: 24000, stock: 15),
      ],
    ),
    Product(
      id: 'eva_soap',
      name: 'Eva Soap',
      categoryId: 'personal_care',
      description: 'Eva beauty soap.',
      imageUrl: _imgCare,
      featured: true,
      units: const [
        ProductUnit(unitName: 'Bar', price: 650, stock: 500),
        ProductUnit(unitName: 'Pack', price: 3600, stock: 80),
        ProductUnit(unitName: 'Carton', price: 22000, stock: 18),
      ],
    ),
    Product(
      id: 'close_up_big',
      name: 'Close Up (Big)',
      categoryId: 'personal_care',
      description: 'Close Up toothpaste — big tube.',
      imageUrl: _imgCare,
      units: const [
        ProductUnit(unitName: 'Tube', price: 1200, stock: 250),
        ProductUnit(unitName: 'Pack', price: 6500, stock: 50),
        ProductUnit(unitName: 'Carton', price: 38500, stock: 12),
      ],
    ),
    Product(
      id: 'close_up_small',
      name: 'Close Up (Small)',
      categoryId: 'personal_care',
      description: 'Close Up toothpaste — small tube.',
      imageUrl: _imgCare,
      units: const [
        ProductUnit(unitName: 'Tube', price: 700, stock: 300),
        ProductUnit(unitName: 'Pack', price: 3800, stock: 60),
        ProductUnit(unitName: 'Carton', price: 22500, stock: 12),
      ],
    ),

    // ========================================================
    // CATEGORY 10 — TISSUE & PAPER (Roll / Pack)
    // ========================================================
    Product(
      id: 'tissue_small',
      name: 'Tissue Paper (Small)',
      categoryId: 'tissue',
      description: 'Soft tissue paper — small roll.',
      imageUrl: _imgTissue,
      units: const [
        ProductUnit(unitName: 'Roll', price: 200, stock: 600),
        ProductUnit(unitName: 'Pack', price: 2000, stock: 80),
      ],
    ),
    Product(
      id: 'tissue_large',
      name: 'Tissue Paper (Large)',
      categoryId: 'tissue',
      description: 'Soft tissue paper — large family roll.',
      imageUrl: _imgTissue,
      units: const [
        ProductUnit(unitName: 'Roll', price: 350, stock: 500),
        ProductUnit(unitName: 'Pack', price: 3500, stock: 70),
      ],
    ),

    // ========================================================
    // GRAINS (bonus — millet for pap / kunu)
    // ========================================================
    Product(
      id: 'millet_001',
      name: 'Millet Grains',
      categoryId: 'grains',
      description:
          'Clean, well-dried millet grains — great for pap, kunu and porridge.',
      imageUrl: _img,
      units: _congoUnits(congo: 1800, halfCongo: 950, paint: 3800, halfPaint: 2000, bag: 55000),
    ),
  ];

  /// Helper: build the standard Congo unit set with sensible stock levels.
  static List<ProductUnit> _congoUnits({
    required double congo,
    required double halfCongo,
    required double paint,
    required double halfPaint,
    required double bag,
  }) =>
      [
        ProductUnit(unitName: 'Congo', price: congo, stock: 100),
        ProductUnit(unitName: 'Half Congo', price: halfCongo, stock: 70),
        ProductUnit(unitName: 'Paint Bucket', price: paint, stock: 40),
        ProductUnit(unitName: 'Half Paint', price: halfPaint, stock: 50),
        ProductUnit(unitName: 'Bag', price: bag, stock: 18),
      ];
}
