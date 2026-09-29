import '../../../domain/entities/product.dart';

final List<Product> mockProducts = [
  Product(
    id: 'prod-001',
    title: 'Nordic Lounge Chair',
    brand: 'Aura Studio',
    description:
        'Engineered with honest materials and refined proportions. The Nordic Lounge Chair features a hand-shaped solid oak frame paired with plush Italian bouclé upholstery. Designed to bring a serene architectural silhouette to quiet reading nooks and modern living spaces across Bangladesh.',
    categoryId: 'cat-furniture',
    tags: ['featured', 'new-arrival', 'living', 'furniture'],
    rating: 4.9,
    reviewCount: 48,
    createdAt: DateTime(2026, 8, 15),
    specifications: {
      'Dimensions': '78cm W × 82cm D × 74cm H',
      'Seat Height': '42cm',
      'Weight': '16.5 kg',
      'Materials': 'FSC-Certified Solid European Oak, Italian Wool Bouclé',
      'Origin': 'Handcrafted in Portugal',
    },
    variants: [
      ProductVariant(
        id: 'var-001-cream',
        sku: 'AL-NLC-CRM-OAK',
        title: 'Cream Bouclé / Solid Oak',
        attributes: {'Color': 'Cream', 'Size': 'Standard'},
        price: 34900.0,
        compareAtPrice: 38000.0,
        stockQuantity: 8,
        imageUrls: [
          'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?auto=format&fit=crop&w=1000&q=80',
          'https://images.unsplash.com/photo-1580481077190-736be5693e6f?auto=format&fit=crop&w=1000&q=80',
          'https://images.unsplash.com/photo-1567538096630-e0c55bd6374c?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
      ProductVariant(
        id: 'var-001-charcoal',
        sku: 'AL-NLC-CHR-WAL',
        title: 'Charcoal / Dark Walnut',
        attributes: {'Color': 'Charcoal', 'Size': 'Standard'},
        price: 36000.0,
        compareAtPrice: null,
        stockQuantity: 2, // Low stock test
        imageUrls: [
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=1000&q=80',
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
      ProductVariant(
        id: 'var-001-terracotta',
        sku: 'AL-NLC-TER-OAK',
        title: 'Terracotta / Solid Oak',
        attributes: {'Color': 'Terracotta', 'Size': 'Standard'},
        price: 35000.0,
        compareAtPrice: null,
        stockQuantity: 0, // Sold out test
        imageUrls: [
          'https://images.unsplash.com/photo-1580481077190-736be5693e6f?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
    ],
  ),
  Product(
    id: 'prod-002',
    title: 'Akari Sculptural Floor Lamp',
    brand: 'Noguchi Edition',
    description:
        'Handmade from traditional Mino washi paper and lightweight bamboo ribbing. This ambient sculptural luminaire casts a diffuse, warm lantern light that softens brutalist concrete or austere contemporary interiors.',
    categoryId: 'cat-lighting',
    tags: ['featured', 'living', 'lighting'],
    rating: 4.8,
    reviewCount: 36,
    createdAt: DateTime(2026, 8, 20),
    specifications: {
      'Height': '145cm',
      'Diameter': '42cm',
      'Weight': '3.2 kg',
      'Materials': 'Handmade Japanese Washi Paper, Bamboo, Cast Iron Base',
      'Bulb': 'E26 LED (Included, 2700K Warm Glow)',
      'Cord Length': '2.5m Braided Linen Cord',
    },
    variants: [
      ProductVariant(
        id: 'var-002-washi',
        sku: 'AL-AKR-WSH-BAM',
        title: 'Washi Paper / Bamboo Stem',
        attributes: {'Color': 'Natural Washi', 'Size': 'Tall'},
        price: 18500.0,
        compareAtPrice: 21000.0,
        stockQuantity: 5,
        imageUrls: [
          'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=1000&q=80',
          'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
      ProductVariant(
        id: 'var-002-black',
        sku: 'AL-AKR-BLK-BRS',
        title: 'Matte Black / Brass',
        attributes: {'Color': 'Matte Black', 'Size': 'Tall'},
        price: 21000.0,
        compareAtPrice: null,
        stockQuantity: 4,
        imageUrls: [
          'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
    ],
  ),
  Product(
    id: 'prod-003',
    title: 'Belgian Organic Linen Duvet',
    brand: 'Aura Atelier',
    description:
        'Woven from 100% certified organic French flax in Flanders, Belgium. Pre-washed with volcanic stones for an exceptionally soft drape that grows gentler and more tactile with every launder.',
    categoryId: 'cat-textiles',
    tags: ['new-arrival', 'bedroom', 'textiles'],
    rating: 4.9,
    reviewCount: 62,
    createdAt: DateTime(2026, 9, 01),
    specifications: {
      'Weave': '175 GSM French Flax Linen',
      'Closure': 'Natural Horn Buttons',
      'Care': 'Machine wash cold on gentle cycle, tumble dry low or air dry',
      'Certification': 'OEKO-TEX Standard 100 Certified',
    },
    variants: [
      ProductVariant(
        id: 'var-003-flax-q',
        sku: 'AL-LIN-FLX-QN',
        title: 'Natural Flax / Queen',
        attributes: {'Color': 'Flax', 'Size': 'Queen'},
        price: 14500.0,
        compareAtPrice: 17500.0,
        stockQuantity: 12,
        imageUrls: [
          'https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?auto=format&fit=crop&w=1000&q=80',
          'https://images.unsplash.com/photo-1540518614846-7eded433c457?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
      ProductVariant(
        id: 'var-003-white-k',
        sku: 'AL-LIN-WHT-KG',
        title: 'Chalk White / King',
        attributes: {'Color': 'Chalk White', 'Size': 'King'},
        price: 16500.0,
        compareAtPrice: null,
        stockQuantity: 7,
        imageUrls: [
          'https://images.unsplash.com/photo-1540518614846-7eded433c457?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
      ProductVariant(
        id: 'var-003-sage-f',
        sku: 'AL-LIN-SGE-FL',
        title: 'Sage Earth / Full',
        attributes: {'Color': 'Sage Earth', 'Size': 'Full'},
        price: 13500.0,
        compareAtPrice: null,
        stockQuantity: 3, // Low stock
        imageUrls: [
          'https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
    ],
  ),
  Product(
    id: 'prod-004',
    title: 'Sabi Stoneware Pedestal Vase',
    brand: 'Wabi Ceramics',
    description:
        'Thrown on a manual kick wheel and finished with unrefined matte wood-ash glaze. Embracing subtle variations in tone and texture, celebrating quiet wabi-sabi aesthetics.',
    categoryId: 'cat-decor',
    tags: ['featured', 'accents', 'decor'],
    rating: 4.7,
    reviewCount: 29,
    createdAt: DateTime(2026, 7, 10),
    specifications: {
      'Dimensions': '18cm Diameter × 28cm Height',
      'Weight': '1.8 kg',
      'Material': 'High-Fire Terracotta Stoneware, Raw Feldspathic Glaze',
      'Origin': 'Shigaraki, Japan',
    },
    variants: [
      ProductVariant(
        id: 'var-004-sandstone',
        sku: 'AL-VAS-SND-MED',
        title: 'Sandstone / Medium',
        attributes: {'Color': 'Sandstone', 'Size': 'Medium'},
        price: 6800.0,
        compareAtPrice: 8500.0,
        stockQuantity: 15,
        imageUrls: [
          'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=1000&q=80',
          'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
      ProductVariant(
        id: 'var-004-terracotta',
        sku: 'AL-VAS-TER-LRG',
        title: 'Terracotta / Large',
        attributes: {'Color': 'Terracotta', 'Size': 'Large'},
        price: 8800.0,
        compareAtPrice: null,
        stockQuantity: 1, // Only 1 left
        imageUrls: [
          'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
      ProductVariant(
        id: 'var-004-basalt',
        sku: 'AL-VAS-BST-SML',
        title: 'Raw Basalt / Small',
        attributes: {'Color': 'Raw Basalt', 'Size': 'Small'},
        price: 5400.0,
        compareAtPrice: null,
        stockQuantity: 6,
        imageUrls: [
          'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
    ],
  ),
  Product(
    id: 'prod-005',
    title: 'Kyoto Travertine Coffee Table',
    brand: 'Aura Studio',
    description:
        'Carved from solid slabs of Italian honed ivory travertine with gentle chamfered edges. A monolithic statement piece celebrating the natural porous cavities and organic veining of mineral stone.',
    categoryId: 'cat-furniture',
    tags: ['featured', 'living', 'furniture'],
    rating: 5.0,
    reviewCount: 18,
    createdAt: DateTime(2026, 8, 25),
    specifications: {
      'Dimensions': '110cm L × 65cm W × 34cm H',
      'Weight': '48.0 kg',
      'Material': 'Solid Roman Travertine, Honed Matte Sealant',
      'Care': 'Clean with pH-neutral stone cleaner only',
    },
    variants: [
      ProductVariant(
        id: 'var-005-ivory',
        sku: 'AL-KTR-IVR-STD',
        title: 'Honed Ivory / Standard',
        attributes: {'Color': 'Ivory', 'Size': 'Standard'},
        price: 52000.0,
        compareAtPrice: 60000.0,
        stockQuantity: 4,
        imageUrls: [
          'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?auto=format&fit=crop&w=1000&q=80',
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
      ProductVariant(
        id: 'var-005-walnut',
        sku: 'AL-KTR-WAL-LRG',
        title: 'Walnut Inlay / Large',
        attributes: {'Color': 'Walnut Inlay', 'Size': 'Large'},
        price: 64000.0,
        compareAtPrice: null,
        stockQuantity: 0, // Sold out
        imageUrls: [
          'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
    ],
  ),
  Product(
    id: 'prod-006',
    title: 'Kinfolk Oak Dining Bench',
    brand: 'Nordic Guild',
    description:
        'A minimalist bench pairing Scandinavian joinery with generous proportions. Comfortably seats three guests, doubling seamlessly as an entrance hall accent piece.',
    categoryId: 'cat-furniture',
    tags: ['dining', 'furniture'],
    rating: 4.8,
    reviewCount: 22,
    createdAt: DateTime(2026, 7, 28),
    specifications: {
      'Dimensions': '140cm W × 38cm D × 45cm H',
      'Weight': '14 kg',
      'Material': 'Solid White Oiled European Oak',
      'Capacity': 'Max load 240 kg',
    },
    variants: [
      ProductVariant(
        id: 'var-006-oak-140',
        sku: 'AL-KB-OAK-140',
        title: 'White Oiled Oak / 140cm',
        attributes: {'Color': 'Natural Oak', 'Size': '140cm'},
        price: 28000.0,
        compareAtPrice: null,
        stockQuantity: 6,
        imageUrls: [
          'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
      ProductVariant(
        id: 'var-006-smoke-160',
        sku: 'AL-KB-SMK-160',
        title: 'Smoked Oak / 160cm',
        attributes: {'Color': 'Smoked Oak', 'Size': '160cm'},
        price: 32000.0,
        compareAtPrice: null,
        stockQuantity: 3,
        imageUrls: [
          'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
    ],
  ),
  Product(
    id: 'prod-007',
    title: 'Brutalist Stoneware Cup Set',
    brand: 'Wabi Ceramics',
    description:
        'Set of four unglazed tactile ceramic cups designed for espresso, matcha, or ceremonial tea. Tactile grog clay surface with smooth food-grade interior slip.',
    categoryId: 'cat-decor',
    tags: ['new-arrival', 'accents', 'dining'],
    rating: 4.9,
    reviewCount: 41,
    createdAt: DateTime(2026, 9, 05),
    specifications: {
      'Volume': '180 ml each',
      'Set Count': '4 cups',
      'Material': 'High-temperature Stoneware Clay',
      'Dishwasher Safe': 'Yes, top rack recommended',
    },
    variants: [
      ProductVariant(
        id: 'var-007-chalk',
        sku: 'AL-CUP-CHK-SET4',
        title: 'Matte Chalk / Set of 4',
        attributes: {'Color': 'Matte Chalk', 'Size': 'Set of 4'},
        price: 4200.0,
        compareAtPrice: null,
        stockQuantity: 20,
        imageUrls: [
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
      ProductVariant(
        id: 'var-007-ash',
        sku: 'AL-CUP-ASH-SET4',
        title: 'Charcoal Ash / Set of 4',
        attributes: {'Color': 'Charcoal Ash', 'Size': 'Set of 4'},
        price: 4200.0,
        compareAtPrice: null,
        stockQuantity: 9,
        imageUrls: [
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
    ],
  ),
  Product(
    id: 'prod-008',
    title: 'Atelier Wool Woven Area Rug',
    brand: 'Aura Atelier',
    description:
        'Hand-knotted from unbleached New Zealand wool with organic high-low loop pile. Provides acoustic softness, warmth, and subtle geometric rhythm to wooden floors.',
    categoryId: 'cat-textiles',
    tags: ['living', 'textiles'],
    rating: 4.8,
    reviewCount: 19,
    createdAt: DateTime(2026, 8, 12),
    specifications: {
      'Dimensions': '150cm × 240cm (5x8 ft)',
      'Pile Height': '18mm',
      'Material': '100% Pure New Zealand Wool, Cotton Warp',
      'Care': 'Vacuum regularly on low suction without beater brush',
    },
    variants: [
      ProductVariant(
        id: 'var-008-oatmeal-5x8',
        sku: 'AL-RUG-OTM-58',
        title: 'Oatmeal Berber / 5×8 ft',
        attributes: {'Color': 'Oatmeal', 'Size': '5×8 ft'},
        price: 29500.0,
        compareAtPrice: 34000.0,
        stockQuantity: 4,
        imageUrls: [
          'https://images.unsplash.com/photo-1600121848594-d8644e57abab?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
      ProductVariant(
        id: 'var-008-olive-8x10',
        sku: 'AL-RUG-OLV-810',
        title: 'Olive Earth / 8×10 ft',
        attributes: {'Color': 'Olive Earth', 'Size': '8×10 ft'},
        price: 48000.0,
        compareAtPrice: null,
        stockQuantity: 2, // Low stock
        imageUrls: [
          'https://images.unsplash.com/photo-1600121848594-d8644e57abab?auto=format&fit=crop&w=1000&q=80',
        ],
      ),
    ],
  ),
];
