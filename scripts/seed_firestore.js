const fs = require('fs');
const path = require('path');
const os = require('os');

const PROJECT_ID = 'aura-living-6885e';
const FIRESTORE_BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function getAccessToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  if (!fs.existsSync(configPath)) {
    throw new Error(`Firebase credentials not found at ${configPath}`);
  }
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const token = config.tokens?.access_token;
  if (!token) {
    throw new Error('Access token not found in firebase-tools.json');
  }
  return token;
}

function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: val.toString() };
    return { doubleValue: val };
  }
  if (typeof val === 'string') return { stringValue: val };
  if (val instanceof Date) return { timestampValue: val.toISOString() };
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(toFirestoreValue) } };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      if (v !== undefined) {
        fields[k] = toFirestoreValue(v);
      }
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

async function setDocument(collection, docId, data, token) {
  const url = `${FIRESTORE_BASE_URL}/${collection}/${docId}`;
  const fields = {};
  for (const [key, value] of Object.entries(data)) {
    if (value !== undefined) {
      fields[key] = toFirestoreValue(value);
    }
  }

  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`Failed to save document ${collection}/${docId}: ${response.status} ${errText}`);
  }

  console.log(`✓ Saved ${collection}/${docId}`);
}

const categories = [
  {
    id: 'cat-living',
    name: 'Living Room',
    title: 'Living Room',
    slug: 'living',
    imageUrl: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=800&q=80',
    description: 'Minimalist seating, lounge chairs, and ambient coffee tables.',
    icon: 'chair_outlined',
    productCount: 4,
  },
  {
    id: 'cat-dining',
    name: 'Dining',
    title: 'Dining',
    slug: 'dining',
    imageUrl: 'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=800&q=80',
    description: 'Solid wood dining tables, crafted chairs, and sculptural benches.',
    icon: 'table_restaurant_outlined',
    productCount: 3,
  },
  {
    id: 'cat-bedroom',
    name: 'Bedroom',
    title: 'Bedroom',
    slug: 'bedroom',
    imageUrl: 'https://images.unsplash.com/photo-1540518614846-7eded433c457?auto=format&fit=crop&w=800&q=80',
    description: 'Low platform bed frames, nightstands, and organic linens.',
    icon: 'bed_outlined',
    productCount: 2,
  },
  {
    id: 'cat-workspace',
    name: 'Workspace',
    title: 'Workspace',
    slug: 'workspace',
    imageUrl: 'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?auto=format&fit=crop&w=800&q=80',
    description: 'Ergonomic task chairs, solid desks, and minimalist organizing solutions.',
    icon: 'desk_outlined',
    productCount: 2,
  },
  {
    id: 'cat-lighting',
    name: 'Lighting',
    title: 'Lighting',
    slug: 'lighting',
    imageUrl: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=800&q=80',
    description: 'Washi paper floor lamps, brass pendants, and architectural ambient lights.',
    icon: 'lightbulb_outlined',
    productCount: 3,
  },
  {
    id: 'cat-decor',
    name: 'Decor',
    title: 'Decor',
    slug: 'decor',
    imageUrl: 'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=800&q=80',
    description: 'Handmade stoneware ceramics, vases, and organic accents.',
    icon: 'spa_outlined',
    productCount: 2,
  },
  {
    id: 'cat-furniture',
    name: 'Furniture',
    title: 'Furniture',
    slug: 'furniture',
    imageUrl: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=800&q=80',
    description: 'Scandinavian and Japanese minimalist furniture craftsmanship.',
    icon: 'weekend_outlined',
    productCount: 6,
  },
];

const products = [
  {
    id: 'prod-001',
    name: 'Nordic Lounge Chair',
    title: 'Nordic Lounge Chair',
    brand: 'Aura Studio',
    slug: 'nordic-lounge-chair',
    description: 'Engineered with honest materials and refined proportions. Features a hand-shaped solid oak frame paired with plush Italian wool bouclé upholstery. Designed to bring a serene architectural silhouette to quiet reading nooks and modern living spaces across Bangladesh.',
    shortDescription: 'Solid European oak lounge chair with Italian wool bouclé.',
    price: 34900,
    basePrice: 34900,
    compareAtPrice: 38000,
    categoryId: 'cat-living',
    category: 'Living Room',
    categoryName: 'Living Room',
    tags: ['featured', 'new-arrival', 'living', 'furniture'],
    rating: 4.9,
    reviewCount: 48,
    isFeatured: true,
    inStock: true,
    stock: 10,
    stockQuantity: 10,
    totalStock: 10,
    status: 'Active',
    images: [
      'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1580481077190-736be5693e6f?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1567538096630-e0c55bd6374c?auto=format&fit=crop&w=1000&q=80',
    ],
    imageUrls: [
      'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1580481077190-736be5693e6f?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1567538096630-e0c55bd6374c?auto=format&fit=crop&w=1000&q=80',
    ],
    specifications: {
      'Dimensions': '78cm W × 82cm D × 74cm H',
      'Seat Height': '42cm',
      'Weight': '16.5 kg',
      'Materials': 'FSC-Certified Solid European Oak, Italian Wool Bouclé',
      'Origin': 'Handcrafted in Portugal',
    },
    variants: [
      {
        id: 'var-001-cream',
        sku: 'AL-NLC-CRM-OAK',
        title: 'Cream Bouclé / Solid Oak',
        attributes: { Color: 'Cream', Size: 'Standard' },
        price: 34900,
        compareAtPrice: 38000,
        stockQuantity: 8,
        imageUrls: [
          'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?auto=format&fit=crop&w=1000&q=80',
        ],
      },
      {
        id: 'var-001-charcoal',
        sku: 'AL-NLC-CHR-WAL',
        title: 'Charcoal / Dark Walnut',
        attributes: { Color: 'Charcoal', Size: 'Standard' },
        price: 36000,
        stockQuantity: 2,
        imageUrls: [
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=1000&q=80',
        ],
      },
    ],
    createdAt: '2026-08-15T00:00:00.000Z',
    updatedAt: '2026-09-30T00:00:00.000Z',
  },
  {
    id: 'prod-002',
    name: 'Akari Sculptural Floor Lamp',
    title: 'Akari Sculptural Floor Lamp',
    brand: 'Noguchi Edition',
    slug: 'akari-sculptural-floor-lamp',
    description: 'Handmade from traditional Mino washi paper and lightweight bamboo ribbing. This ambient sculptural luminaire casts a diffuse, warm lantern light that softens brutalist concrete or austere contemporary interiors.',
    shortDescription: 'Ambient Japanese washi paper and bamboo floor luminaire.',
    price: 18500,
    basePrice: 18500,
    compareAtPrice: 21000,
    categoryId: 'cat-lighting',
    category: 'Lighting',
    categoryName: 'Lighting',
    tags: ['featured', 'lighting', 'living'],
    rating: 4.8,
    reviewCount: 36,
    isFeatured: true,
    inStock: true,
    stock: 5,
    stockQuantity: 5,
    totalStock: 5,
    status: 'Active',
    images: [
      'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?auto=format&fit=crop&w=1000&q=80',
    ],
    imageUrls: [
      'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?auto=format&fit=crop&w=1000&q=80',
    ],
    specifications: {
      'Height': '145cm',
      'Diameter': '42cm',
      'Weight': '3.2 kg',
      'Materials': 'Handmade Japanese Washi Paper, Bamboo, Cast Iron Base',
      'Bulb': 'E26 LED (Included, 2700K Warm Glow)',
      'Cord Length': '2.5m Braided Linen Cord',
    },
    variants: [
      {
        id: 'var-002-washi',
        sku: 'AL-AKR-WSH-BAM',
        title: 'Washi Paper / Bamboo Stem',
        attributes: { Color: 'Natural Washi', Size: 'Tall' },
        price: 18500,
        compareAtPrice: 21000,
        stockQuantity: 5,
        imageUrls: [
          'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=1000&q=80',
        ],
      },
    ],
    createdAt: '2026-08-20T00:00:00.000Z',
    updatedAt: '2026-09-30T00:00:00.000Z',
  },
  {
    id: 'prod-003',
    name: 'Kyoto Solid Oak Dining Table',
    title: 'Kyoto Solid Oak Dining Table',
    brand: 'Aura Studio',
    slug: 'kyoto-solid-oak-dining-table',
    description: 'Exemplifying Japanese woodcraft joinery with softly chamfered bullnose edges. The Kyoto table comfortably seats six to eight guests for intimate gatherings and quiet shared meals.',
    shortDescription: 'Solid white oak dining table with traditional mortise & tenon joinery.',
    price: 68000,
    basePrice: 68000,
    compareAtPrice: 75000,
    categoryId: 'cat-dining',
    category: 'Dining',
    categoryName: 'Dining',
    tags: ['featured', 'dining', 'furniture'],
    rating: 5.0,
    reviewCount: 22,
    isFeatured: true,
    inStock: true,
    stock: 4,
    stockQuantity: 4,
    totalStock: 4,
    status: 'Active',
    images: [
      'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1530018607912-eff2daa1bac4?auto=format&fit=crop&w=1000&q=80',
    ],
    imageUrls: [
      'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1530018607912-eff2daa1bac4?auto=format&fit=crop&w=1000&q=80',
    ],
    specifications: {
      'Dimensions': '200cm L × 95cm W × 75cm H',
      'Weight': '52 kg',
      'Materials': 'FSC Solid White Oak, Matte Organic Polyurethane Seal',
      'Capacity': '6-8 Seats',
    },
    variants: [
      {
        id: 'var-003-oak-200',
        sku: 'AL-KYO-OAK-200',
        title: 'Natural Oak (200cm)',
        attributes: { Length: '200cm', Finish: 'Natural Oak' },
        price: 68000,
        compareAtPrice: 75000,
        stockQuantity: 4,
        imageUrls: [
          'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=1000&q=80',
        ],
      },
    ],
    createdAt: '2026-08-25T00:00:00.000Z',
    updatedAt: '2026-09-30T00:00:00.000Z',
  },
  {
    id: 'prod-004',
    name: 'Kanso Minimalist Platform Bed',
    title: 'Kanso Minimalist Platform Bed',
    brand: 'Aura Bedroom',
    slug: 'kanso-minimalist-platform-bed',
    description: 'A low-profile sanctuary designed around the Zen concept of simplicity (Kanso). Floats subtly above the floor with an integrated cantilevered headboard and solid birch slat support system.',
    shortDescription: 'Low-profile solid walnut platform bed with floating silhouette.',
    price: 85000,
    basePrice: 85000,
    compareAtPrice: 92000,
    categoryId: 'cat-bedroom',
    category: 'Bedroom',
    categoryName: 'Bedroom',
    tags: ['featured', 'bedroom', 'furniture'],
    rating: 4.9,
    reviewCount: 19,
    isFeatured: true,
    inStock: true,
    stock: 3,
    stockQuantity: 3,
    totalStock: 3,
    status: 'Active',
    images: [
      'https://images.unsplash.com/photo-1540518614846-7eded433c457?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1000&q=80',
    ],
    imageUrls: [
      'https://images.unsplash.com/photo-1540518614846-7eded433c457?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1000&q=80',
    ],
    specifications: {
      'Mattress Size': 'King (180cm × 200cm)',
      'Dimensions': '218cm L × 198cm W × 78cm H',
      'Materials': 'Solid American Walnut, Birch Slats',
    },
    variants: [
      {
        id: 'var-004-king-walnut',
        sku: 'AL-KAN-WAL-KNG',
        title: 'King / Solid Walnut',
        attributes: { Size: 'King', Wood: 'American Walnut' },
        price: 85000,
        compareAtPrice: 92000,
        stockQuantity: 3,
        imageUrls: [
          'https://images.unsplash.com/photo-1540518614846-7eded433c457?auto=format&fit=crop&w=1000&q=80',
        ],
      },
    ],
    createdAt: '2026-09-01T00:00:00.000Z',
    updatedAt: '2026-09-30T00:00:00.000Z',
  },
  {
    id: 'prod-005',
    name: 'Wabi-Sabi Stoneware Ceramic Vase',
    title: 'Wabi-Sabi Stoneware Ceramic Vase',
    brand: 'Hasami Craft',
    slug: 'wabi-sabi-stoneware-ceramic-vase',
    description: 'Wheel-thrown by master artisans using coarse speckled clay. Finished with a raw textured matte glaze that celebrates natural imperfections and tactile serenity.',
    shortDescription: 'Hand-thrown coarse stoneware vase with organic matte glaze.',
    price: 4200,
    basePrice: 4200,
    compareAtPrice: 4800,
    categoryId: 'cat-decor',
    category: 'Decor',
    categoryName: 'Decor',
    tags: ['decor', 'ceramics', 'featured'],
    rating: 4.7,
    reviewCount: 54,
    isFeatured: true,
    inStock: true,
    stock: 15,
    stockQuantity: 15,
    totalStock: 15,
    status: 'Active',
    images: [
      'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?auto=format&fit=crop&w=1000&q=80',
    ],
    imageUrls: [
      'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?auto=format&fit=crop&w=1000&q=80',
    ],
    specifications: {
      'Height': '28cm',
      'Diameter': '16cm',
      'Material': 'High-Fire Stoneware Clay',
      'Waterproof': 'Yes, fully glazed interior',
    },
    variants: [
      {
        id: 'var-005-matte-chalk',
        sku: 'AL-WBI-VAS-CHK',
        title: 'Chalk White / Medium',
        attributes: { Color: 'Chalk White', Size: '28cm' },
        price: 4200,
        compareAtPrice: 4800,
        stockQuantity: 15,
        imageUrls: [
          'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=1000&q=80',
        ],
      },
    ],
    createdAt: '2026-09-05T00:00:00.000Z',
    updatedAt: '2026-09-30T00:00:00.000Z',
  },
  {
    id: 'prod-006',
    name: 'Stockholm Minimalist Work Desk',
    title: 'Stockholm Minimalist Work Desk',
    brand: 'Aura Studio',
    slug: 'stockholm-minimalist-work-desk',
    description: 'An architectural work table stripped of all distraction. Features concealed cable routing channels, a brushed aluminium grommet, and a durable soft-touch matte linoleum work surface.',
    shortDescription: 'Solid ash work desk with integrated cable routing and linoleum top.',
    price: 42000,
    basePrice: 42000,
    compareAtPrice: 46000,
    categoryId: 'cat-workspace',
    category: 'Workspace',
    categoryName: 'Workspace',
    tags: ['workspace', 'furniture', 'featured'],
    rating: 4.9,
    reviewCount: 28,
    isFeatured: true,
    inStock: true,
    stock: 6,
    stockQuantity: 6,
    totalStock: 6,
    status: 'Active',
    images: [
      'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=1000&q=80',
    ],
    imageUrls: [
      'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=1000&q=80',
    ],
    specifications: {
      'Dimensions': '140cm L × 70cm W × 74cm H',
      'Materials': 'Solid Ash Legs, Forbo Desktop Linoleum',
      'Cable Management': 'Integrated beneath desktop',
    },
    variants: [
      {
        id: 'var-006-olive-ash',
        sku: 'AL-STK-DSK-OLV',
        title: 'Olive Linoleum / Ash Frame',
        attributes: { Finish: 'Olive', Frame: 'Solid Ash' },
        price: 42000,
        compareAtPrice: 46000,
        stockQuantity: 6,
        imageUrls: [
          'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?auto=format&fit=crop&w=1000&q=80',
        ],
      },
    ],
    createdAt: '2026-09-10T00:00:00.000Z',
    updatedAt: '2026-09-30T00:00:00.000Z',
  },
];

const settings = {
  storeName: 'Aura Living',
  tagline: 'Luxury Minimalist Living & Furniture Ecosystem',
  currency: 'BDT',
  currencySymbol: '৳',
  freeShippingThreshold: 5000,
  deliveryFeeInsideDhaka: 80,
  deliveryFeeOutsideDhaka: 150,
  supportPhone: '+880 1712-345678',
  supportEmail: 'support@auraliving.bd',
  address: 'Gulshan 2, Dhaka 1212, Bangladesh',
  market: 'Bangladesh (BDT)',
  updatedAt: new Date().toISOString(),
};

async function runSeed() {
  console.log('🚀 Starting Cloud Firestore Seeding for project:', PROJECT_ID);
  const token = getAccessToken();

  console.log('\n--- Seeding Categories ---');
  for (const cat of categories) {
    await setDocument('categories', cat.id, cat, token);
  }

  console.log('\n--- Seeding Products ---');
  for (const prod of products) {
    await setDocument('products', prod.id, prod, token);
  }

  console.log('\n--- Seeding Settings ---');
  await setDocument('settings', 'store', settings, token);

  console.log('\n🎉 Successfully seeded all categories, products, and settings into Cloud Firestore!');
}

runSeed().catch((err) => {
  console.error('❌ Seeding failed:', err);
  process.exit(1);
});
