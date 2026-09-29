import '../../../domain/entities/category.dart';

const List<Category> mockCategories = [
  Category(
    id: 'cat-furniture',
    title: 'Furniture',
    slug: 'furniture',
    imageUrl:
        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=800&q=80',
  ),
  Category(
    id: 'cat-lighting',
    title: 'Lighting',
    slug: 'lighting',
    imageUrl:
        'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=800&q=80',
  ),
  Category(
    id: 'cat-textiles',
    title: 'Textiles',
    slug: 'textiles',
    imageUrl:
        'https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?auto=format&fit=crop&w=800&q=80',
  ),
  Category(
    id: 'cat-decor',
    title: 'Decor',
    slug: 'decor',
    imageUrl:
        'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=800&q=80',
  ),
  Category(
    id: 'cat-living',
    title: 'Living Room',
    slug: 'living',
    parentCategoryId: 'cat-furniture',
    imageUrl:
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=800&q=80',
  ),
  Category(
    id: 'cat-dining',
    title: 'Dining Room',
    slug: 'dining',
    parentCategoryId: 'cat-furniture',
    imageUrl:
        'https://images.unsplash.com/photo-1617806118233-18e1de247200?auto=format&fit=crop&w=800&q=80',
  ),
  Category(
    id: 'cat-bedroom',
    title: 'Bedroom',
    slug: 'bedroom',
    parentCategoryId: 'cat-furniture',
    imageUrl:
        'https://images.unsplash.com/photo-1540518614846-7eded433c457?auto=format&fit=crop&w=800&q=80',
  ),
  Category(
    id: 'cat-accents',
    title: 'Accents & Ceramics',
    slug: 'accents',
    parentCategoryId: 'cat-decor',
    imageUrl:
        'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?auto=format&fit=crop&w=800&q=80',
  ),
  Category(
    id: 'cat-sale',
    title: 'Curated Sale',
    slug: 'sale',
    imageUrl:
        'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?auto=format&fit=crop&w=800&q=80',
  ),
];
