import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/aura_button.dart';
import '../../../core/widgets/stock_badge.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/wishlist/wishlist_cubit.dart';
import 'fullscreen_lightbox_screen.dart';
import 'reviews_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final VoidCallback onBack;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onBack,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductVariant _selectedVariant;
  late PageController _galleryPageController;
  int _currentImageIndex = 0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.product.defaultVariant;
    _galleryPageController = PageController();
    _quantity = _selectedVariant.isInStock ? 1 : 0;
  }

  @override
  void dispose() {
    _galleryPageController.dispose();
    super.dispose();
  }

  void _onSelectVariant(ProductVariant variant) {
    setState(() {
      _selectedVariant = variant;
      _currentImageIndex = 0;
      if (variant.isInStock) {
        _quantity = 1;
      } else {
        _quantity = 0;
      }
    });

    if (_galleryPageController.hasClients) {
      _galleryPageController.jumpToPage(0);
    }
  }

  void _openLightbox(int index) {
    final images = _selectedVariant.imageUrls.isNotEmpty
        ? _selectedVariant.imageUrls
        : widget.product.allImages;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenLightboxScreen(
          imageUrls: images,
          initialIndex: index,
        ),
      ),
    );
  }

  void _openReviewsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductReviewsScreen(product: widget.product),
      ),
    );
  }

  Color _getColorFromLabel(String colorLabel) {
    final lower = colorLabel.toLowerCase();
    if (lower.contains('cream') || lower.contains('washi') || lower.contains('ivory') || lower.contains('chalk')) {
      return const Color(0xFFF3ECE1);
    }
    if (lower.contains('charcoal') || lower.contains('black') || lower.contains('ash') || lower.contains('basalt')) {
      return const Color(0xFF2B2B2B);
    }
    if (lower.contains('terracotta') || lower.contains('rust')) {
      return const Color(0xFFB85D43);
    }
    if (lower.contains('flax') || lower.contains('sand') || lower.contains('oatmeal') || lower.contains('oak')) {
      return const Color(0xFFD6C6B0);
    }
    if (lower.contains('olive') || lower.contains('sage')) {
      return const Color(0xFF767F68);
    }
    if (lower.contains('walnut') || lower.contains('smoke')) {
      return const Color(0xFF5D483A);
    }
    return const Color(0xFF888888);
  }

  @override
  Widget build(BuildContext context) {
    final galleryImages = _selectedVariant.imageUrls.isNotEmpty
        ? _selectedVariant.imageUrls
        : widget.product.allImages;

    final hasDiscount = _selectedVariant.compareAtPrice != null &&
        _selectedVariant.compareAtPrice! > _selectedVariant.price;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
          tooltip: 'Back to catalog',
        ),
        title: Text(widget.product.brand.toUpperCase(), style: AppTypography.overline),
        actions: [
          BlocBuilder<WishlistCubit, WishlistState>(
            builder: (context, state) {
              final isFav = state.isWishlisted(widget.product.id);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppColors.discountBadge : AppColors.textPrimary,
                ),
                onPressed: () {
                  context.read<WishlistCubit>().toggleWishlist(widget.product);
                },
                tooltip: isFav ? 'Remove from Wishlist' : 'Add to Wishlist',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Gallery Carousel
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: PageView.builder(
                    controller: _galleryPageController,
                    itemCount: galleryImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openLightbox(index),
                        onDoubleTap: () => _openLightbox(index),
                        child: Container(
                          color: AppColors.surfaceSecondary,
                          child: Image.network(
                            galleryImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.image, size: 48, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Pill Counter
                if (galleryImages.length > 1)
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1} / ${galleryImages.length}',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Tap to zoom hint
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            // Product Details Block
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.product.title,
                    style: AppTypography.displaySmall,
                  ),
                  const SizedBox(height: 6),

                  // SKU & Rating Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SKU: ${_selectedVariant.sku}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                      InkWell(
                        onTap: _openReviewsScreen,
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: AppColors.gold),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.product.rating} (${widget.product.reviewCount} reviews)',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Price Block
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        CurrencyFormatter.format(_selectedVariant.price),
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 10),
                        Text(
                          CurrencyFormatter.format(_selectedVariant.compareAtPrice!),
                          style: AppTypography.priceOld.copyWith(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stock Status Indicator
                  StockBadge(stockQuantity: _selectedVariant.stockQuantity),
                  const Divider(height: 32),

                  // Variant Selection (Color Swatches)
                  Text('COLORWAY', style: AppTypography.overline),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: widget.product.variants.map((v) {
                      final isSelected = v.id == _selectedVariant.id;
                      final colorName = v.attributes['Color'] ?? v.title;
                      final swatchColor = _getColorFromLabel(colorName);
                      final isOutOfStock = v.stockQuantity <= 0;

                      return GestureDetector(
                        onTap: () => _onSelectVariant(v),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: swatchColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.borderDark,
                                    width: 0.8,
                                  ),
                                ),
                                child: isOutOfStock
                                    ? const Center(
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              colorName,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Size / Dimension Selection if available
                  if (widget.product.availableSizes.isNotEmpty) ...[
                    Text('SIZE / PROPORTION', style: AppTypography.overline),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.product.availableSizes.map((size) {
                        final matchingVar = widget.product.variants.firstWhere(
                          (v) => v.attributes['Size'] == size,
                          orElse: () => _selectedVariant,
                        );
                        final isSelected = _selectedVariant.attributes['Size'] == size;
                        final isOutOfStock = matchingVar.stockQuantity <= 0;

                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(
                            isOutOfStock ? '$size (Sold Out)' : size,
                            style: AppTypography.bodySmall.copyWith(
                              color: isOutOfStock
                                  ? AppColors.textMuted
                                  : (isSelected ? Colors.white : AppColors.textPrimary),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                          onSelected: isOutOfStock
                              ? null
                              : (_) => _onSelectVariant(matchingVar),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Editorial Story & Description Accordion
                  ExpansionTile(
                    initiallyExpanded: true,
                    title: Text('Description & Story', style: AppTypography.titleSmall),
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.description,
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                  const Divider(),

                  // Specifications Accordion
                  ExpansionTile(
                    title: Text('Dimensions & Craft Specifications', style: AppTypography.titleSmall),
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    children: widget.product.specifications.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                entry.key,
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(),

                  // Care & Maintenance Accordion
                  ExpansionTile(
                    title: Text('Care & Preservation', style: AppTypography.titleSmall),
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    children: [
                      Text(
                        'Wipe clean using a soft, dry cotton cloth. Protect natural wood and porous stone from direct heat sources and acidic liquids. Nourish wood surfaces with organic beeswax every 6 months.',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                  const Divider(),

                  // Shipping & White-Glove Delivery Accordion
                  ExpansionTile(
                    title: Text('Shipping & White-Glove Guarantee', style: AppTypography.titleSmall),
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    children: [
                      Text(
                        'Complimentary delivery across Bangladesh on orders over ৳5,000. Nationwide courier dispatch across all 64 districts with verified tracking (Steadfast / Pathao). 30-day mindful return window.',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                  const Divider(),

                  // Customer Reviews Preview Section
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Customer Reviews', style: AppTypography.titleSmall),
                      TextButton(
                        onPressed: _openReviewsScreen,
                        child: Text(
                          'View All (${widget.product.reviewCount})',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _openReviewsScreen,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Elena Rostova',
                                style: AppTypography.titleSmall.copyWith(fontSize: 13),
                              ),
                              Row(
                                children: List.generate(5, (_) => const Icon(
                                  Icons.star,
                                  size: 13,
                                  color: AppColors.gold,
                                )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '“The bouclé texture is exquisite and the oak joinery is flawless. It anchors our living room with calm architectural elegance.”',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),

      // Sticky Bottom Action Bar
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Row(
            children: [
              // Quantity Stepper (hidden/disabled if sold out per PRD 6.1)
              if (_selectedVariant.isInStock) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$_quantity',
                          style: AppTypography.titleSmall.copyWith(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add, size: 16),
                        // Capped at stockQuantity per AC-2.3
                        onPressed: _quantity < _selectedVariant.stockQuantity
                            ? () => setState(() => _quantity++)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Add to Cart Button (replaces with "Out of Stock" disabled state if sold out per AC-2.2 and QA-04)
              Expanded(
                child: AuraPrimaryButton(
                  label: _selectedVariant.isInStock
                      ? 'Add to Bag — ${CurrencyFormatter.format(_selectedVariant.price * (_quantity > 0 ? _quantity : 1))}'
                      : 'Out of Stock',
                  onPressed: _selectedVariant.isInStock
                      ? () {
                          context.read<CartCubit>().addItem(
                                widget.product,
                                _selectedVariant,
                                quantity: _quantity,
                              );
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added ${widget.product.title} ($_quantity) to bag',
                                style: AppTypography.bodySmall.copyWith(color: Colors.white),
                              ),
                              backgroundColor: AppColors.primary,
                              action: SnackBarAction(
                                label: 'View Bag',
                                textColor: AppColors.accentOlive,
                                onPressed: () {
                                  // Can trigger tab switch if needed
                                },
                              ),
                            ),
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
