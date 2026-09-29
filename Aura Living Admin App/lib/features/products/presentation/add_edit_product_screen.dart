import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/admin_user.dart';
import '../domain/product.dart';
import '../domain/product_variant.dart';
import '../domain/category.dart';
import 'products_controller.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId; // null for Add, populated for Edit

  const AddEditProductScreen({super.key, this.productId});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  bool _isInit = false;
  bool _isSaving = false;
  bool _isEdit = false;
  Product? _existingProduct;

  // Form Fields
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  String? _selectedCategoryId;
  final _shortDescController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _status = 'Active';
  bool _isFeatured = false;

  // Media
  final List<String> _imageUrls = [];
  final _imageUrlInputController = TextEditingController();

  // Pricing
  final _basePriceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  double _calculatedFinalPrice = 0.0;

  // Variants & Inventory
  bool _hasVariants = false;
  final _singleStockController = TextEditingController(text: '10');
  final List<ProductVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _isEdit = widget.productId != null;

    _titleController.addListener(_onTitleChanged);
    _basePriceController.addListener(_updateCalculatedPrice);
    _discountController.addListener(_updateCalculatedPrice);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProductData());
  }

  void _onTitleChanged() {
    if (!_isEdit && _titleController.text.isNotEmpty) {
      final slug = _titleController.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      _slugController.text = slug;
    }
  }

  void _updateCalculatedPrice() {
    final base = double.tryParse(_basePriceController.text.replaceAll('\$', '').replaceAll('৳', '').replaceAll(',', '').trim()) ?? 0.0;
    final discount = double.tryParse(_discountController.text.replaceAll('%', '').trim()) ?? 0.0;
    setState(() {
      _calculatedFinalPrice = base * (1 - (discount / 100));
    });
  }

  Future<void> _loadProductData() async {
    if (_isEdit) {
      final repo = ref.read(productRepositoryProvider);
      final product = await repo.getProductById(widget.productId!);
      if (product != null) {
        _existingProduct = product;
        _titleController.text = product.title;
        _slugController.text = product.slug;
        _selectedCategoryId = product.categoryId;
        _shortDescController.text = product.shortDescription;
        _descriptionController.text = product.description;
        _status = product.status;
        _isFeatured = product.isFeatured;
        _imageUrls.addAll(product.imageUrls);
        _basePriceController.text = product.basePrice.toStringAsFixed(2);
        _discountController.text = product.discountPercentage.toStringAsFixed(0);
        _hasVariants = product.hasVariants;
        _singleStockController.text = product.stockQuantity.toString();
        _variants.addAll(product.variants);
        _updateCalculatedPrice();
      }
    } else {
      // Default sample images for quick catalog creation
      _imageUrls.add(
        'https://images.unsplash.com/photo-1592078615290-033ee584e267?auto=format&fit=crop&w=600&q=80',
      );
    }

    // Default category if none selected
    final cats = await ref.read(categoriesListProvider.future);
    if (_selectedCategoryId == null && cats.isNotEmpty) {
      _selectedCategoryId = cats.first.id;
    }

    setState(() => _isInit = true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _slugController.dispose();
    _shortDescController.dispose();
    _descriptionController.dispose();
    _imageUrlInputController.dispose();
    _basePriceController.dispose();
    _discountController.dispose();
    _singleStockController.dispose();
    super.dispose();
  }

  void _addImage(String url) {
    if (url.trim().isEmpty) return;
    if (_imageUrls.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 images allowed per product.')),
      );
      return;
    }
    setState(() {
      _imageUrls.add(url.trim());
      _imageUrlInputController.clear();
    });
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  void _setPrimaryImage(int index) {
    if (index > 0 && index < _imageUrls.length) {
      setState(() {
        final img = _imageUrls.removeAt(index);
        _imageUrls.insert(0, img);
      });
    }
  }

  void _addVariant() {
    const uuid = Uuid();
    final count = _variants.length + 1;
    setState(() {
      _variants.add(
        ProductVariant(
          id: 'var-custom-${uuid.v4().substring(0, 6)}',
          sku: '${_slugController.text.toUpperCase()}-V$count',
          attributeName: 'Color',
          attributeValue: 'Nordic Oak',
          stockQuantity: 10,
        ),
      );
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    // 1. Validate Form Fields
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    // 2. Validate Images
    if (_status.toLowerCase() == 'active' && _imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product must have at least one primary image before setting status to Active.'),
          backgroundColor: AppColors.danger,
        ),
      );
      _tabController.animateTo(1);
      return;
    }

    // 3. Validate Variants if enabled
    if (_hasVariants) {
      if (_variants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add at least one variant or toggle off "Has Variants?".'),
            backgroundColor: AppColors.danger,
          ),
        );
        _tabController.animateTo(3);
        return;
      }
      for (final v in _variants) {
        if (v.sku.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All variants must have a valid SKU.'),
              backgroundColor: AppColors.danger,
            ),
          );
          _tabController.animateTo(3);
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(productRepositoryProvider);
      final base = double.parse(_basePriceController.text.replaceAll('\$', '').replaceAll('৳', '').replaceAll(',', '').trim());
      final discount = double.tryParse(_discountController.text.replaceAll('%', '').trim()) ?? 0.0;
      final stock = int.tryParse(_singleStockController.text.trim()) ?? 0;

      final now = DateTime.now();
      final product = Product(
        id: _isEdit ? _existingProduct!.id : '',
        title: _titleController.text.trim(),
        slug: _slugController.text.trim(),
        categoryId: _selectedCategoryId ?? 'cat-furniture',
        shortDescription: _shortDescController.text.trim(),
        description: _descriptionController.text.trim(),
        basePrice: base,
        discountPercentage: discount,
        imageUrls: _imageUrls.isNotEmpty
            ? _imageUrls
            : ['https://images.unsplash.com/photo-1592078615290-033ee584e267?auto=format&fit=crop&w=600&q=80'],
        hasVariants: _hasVariants,
        variants: _hasVariants ? _variants : const [],
        stockQuantity: _hasVariants ? 0 : stock,
        status: _status,
        isFeatured: _isFeatured,
        createdAt: _isEdit ? _existingProduct!.createdAt : now,
        updatedAt: now,
      );

      if (_isEdit) {
        await repo.updateProduct(product);
      } else {
        await repo.createProduct(product);
      }

      ref.invalidate(productsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Product updated successfully.' : 'Product created successfully.'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleHardDelete() async {
    if (_existingProduct == null) return;
    final confirmed = await ConfirmDialog.show(
      context,
      title: "Permanently delete '${_existingProduct!.title}'?",
      message:
          'This action cannot be undone and will detach product history from unfulfilled orders.',
      confirmLabel: 'Delete Forever',
      isDestructive: true,
    );

    if (confirmed) {
      final repo = ref.read(productRepositoryProvider);
      await repo.hardDeleteProduct(_existingProduct!.id);
      ref.invalidate(productsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Permanently deleted '${_existingProduct!.title}'.")),
        );
        context.go('/products');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add New Product'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryOlive,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryOlive,
          indicatorWeight: 2,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Basic Details'),
            Tab(text: 'Media (Images)'),
            Tab(text: 'Pricing & Discount'),
            Tab(text: 'Variants & Stock'),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Cancel',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  text: _isEdit ? 'Save Changes' : 'Create Product',
                  isLoading: _isSaving,
                  onPressed: _submitForm,
                ),
              ),
            ],
          ),
        ),
      ),
      body: !_isInit
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Basic Details
                  _buildBasicDetailsTab(categoriesAsync),

                  // Tab 2: Media
                  _buildMediaTab(),

                  // Tab 3: Pricing & Discount
                  _buildPricingTab(),

                  // Tab 4: Variants & Inventory
                  _buildVariantsTab(user),
                ],
              ),
            ),
    );
  }

  Widget _buildBasicDetailsTab(AsyncValue<List<Category>> categoriesAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            AppTextField(
              controller: _titleController,
              label: 'Product Title *',
              hintText: 'e.g. Nordic Minimalist Oak Chair',
              validator: (v) => AppValidators.validateRequired(v, 'Product Title'),
            ),
            const SizedBox(height: 16),

            // Slug / SKU
            AppTextField(
              controller: _slugController,
              label: 'Slug / Catalog SKU *',
              hintText: 'e.g. nordic-minimalist-oak-chair',
              validator: (v) => AppValidators.validateRequired(v, 'Catalog SKU / Slug'),
            ),
            const SizedBox(height: 16),

            // Category picker
            Text('Category *', style: AppTypography.dataLabel.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            categoriesAsync.when(
              loading: () => const ShimmerLoader(height: 48),
              error: (_, __) => const Text('Error loading categories'),
              data: (categories) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    items: categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Text(cat.name, style: AppTypography.body),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Short Description
            AppTextField(
              controller: _shortDescController,
              label: 'Short Description (max 250 characters) *',
              hintText: 'Brief summary displayed on cards...',
              maxLines: 2,
              validator: (v) => AppValidators.validateRequired(v, 'Short Description'),
            ),
            const SizedBox(height: 16),

            // Long Description / Specifications
            AppTextField(
              controller: _descriptionController,
              label: 'Long Description & Specifications *',
              hintText: 'Full materials, dimensions, care instructions...',
              maxLines: 5,
              validator: (v) => AppValidators.validateRequired(v, 'Full Description'),
            ),
            const SizedBox(height: 20),

            // Status picker
            Text('Product Status', style: AppTypography.dataLabel.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _statusChoice('Active', 'Active'),
                const SizedBox(width: 8),
                _statusChoice('Draft', 'Draft'),
                const SizedBox(width: 8),
                _statusChoice('Archived', 'Archived'),
              ],
            ),
            const SizedBox(height: 16),

            // Featured Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Featured on Homepage', style: AppTypography.bodyMedium),
              subtitle: Text(
                'Showcases this product in prime storefront carousels.',
                style: AppTypography.caption,
              ),
              activeColor: AppColors.primaryOlive,
              value: _isFeatured,
              onChanged: (val) => setState(() => _isFeatured = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChoice(String label, String value) {
    final isSelected = _status == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _status = value),
      selectedColor: AppColors.primaryOlive,
      backgroundColor: AppColors.surfaceSecondary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Product Images', style: AppTypography.sectionHeader),
                Text('${_imageUrls.length}/6 Images', style: AppTypography.dataLabel),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Add image URLs. The first image will be set as the primary thumbnail.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),

            // Add Image input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageUrlInputController,
                    decoration: const InputDecoration(
                      hintText: 'https://images.unsplash.com/...',
                      labelText: 'New Image URL',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  text: 'Add',
                  width: 70,
                  onPressed: () => _addImage(_imageUrlInputController.text),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Images Grid
            if (_imageUrls.isEmpty)
              const EmptyStateView(
                icon: Icons.image_outlined,
                title: 'No Images Added',
                subtitle: 'Active products require at least one primary image.',
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _imageUrls.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final isPrimary = index == 0;
                  final url = _imageUrls[index];

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPrimary ? AppColors.primaryOlive : AppColors.border,
                        width: isPrimary ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        ),
                        // Primary badge
                        if (isPrimary)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOlive,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PRIMARY',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        // Delete / Set primary action bar
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withOpacity(0.6),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (!isPrimary)
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 30),
                                    ),
                                    onPressed: () => _setPrimaryImage(index),
                                    child: const Text(
                                      'Make Primary',
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  )
                                else
                                  const SizedBox(width: 50),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                                  onPressed: () => _removeImage(index),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingTab() {
    final discountVal = double.tryParse(_discountController.text.replaceAll('%', '').trim()) ?? 0;
    final isHighDiscount = discountVal > 50;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pricing & Discounts', style: AppTypography.sectionHeader),
            const SizedBox(height: 6),
            Text(
              'Set the regular retail price and optional promotional discount.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 20),

            // Base Price
            AppTextField(
              controller: _basePriceController,
              label: 'Base Price (\$) *',
              hintText: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: AppValidators.validateBasePrice,
            ),
            const SizedBox(height: 16),

            // Discount Percentage
            AppTextField(
              controller: _discountController,
              label: 'Discount Percentage (%)',
              hintText: '0',
              keyboardType: TextInputType.number,
              validator: AppValidators.validateDiscount,
            ),
            if (isHighDiscount) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'High discount alert: Over 50% retail discount applied.',
                    style: AppTypography.caption.copyWith(color: AppColors.warning),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Calculated Final Price Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calculated Final Price', style: AppTypography.dataLabel),
                      Text(
                        'Customer visible retail price',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  Text(
                    AppFormatters.currency(_calculatedFinalPrice),
                    style: AppTypography.metricCallout.copyWith(
                      fontSize: 22,
                      color: AppColors.primaryOlive,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsTab(AdminUser? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Variants & Inventory', style: AppTypography.sectionHeader),
                        Text(
                          'Configure multiple attributes (color, size, material)',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    Switch(
                      value: _hasVariants,
                      activeColor: AppColors.primaryOlive,
                      onChanged: (val) => setState(() => _hasVariants = val),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // If no variants: single inventory count
                if (!_hasVariants) ...[
                  AppTextField(
                    controller: _singleStockController,
                    label: 'Total Stock Quantity *',
                    hintText: '10',
                    keyboardType: TextInputType.number,
                    validator: AppValidators.validateStock,
                  ),
                ] else ...[
                  // Dynamic variant list builder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Variant Breakdown (${_variants.length})',
                        style: AppTypography.dataLabel.copyWith(fontWeight: FontWeight.w600),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Add Variant', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(110, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: _addVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _variants.length,
                    itemBuilder: (context, index) {
                      final variant = _variants[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Variant #${index + 1}',
                                  style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                                  onPressed: () => _removeVariant(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: variant.attributeName,
                                    decoration: const InputDecoration(labelText: 'Attribute (e.g. Color)'),
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (val) {
                                      _variants[index] = variant.copyWith(attributeName: val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: variant.attributeValue,
                                    decoration: const InputDecoration(labelText: 'Value (e.g. Natural Oak)'),
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (val) {
                                      _variants[index] = variant.copyWith(attributeValue: val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: variant.sku,
                                    decoration: const InputDecoration(labelText: 'Variant SKU *'),
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (val) {
                                      _variants[index] = variant.copyWith(sku: val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: variant.stockQuantity.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Stock Qty *'),
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (val) {
                                      final qty = int.tryParse(val) ?? 0;
                                      _variants[index] = variant.copyWith(stockQuantity: qty);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // In Edit mode: Destructive Hard Delete button per PRD Section 6.3
          if (_isEdit && (user?.role.canHardDeleteProduct ?? false)) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Danger Zone',
                    style: AppTypography.sectionHeader.copyWith(color: AppColors.danger),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Permanently delete this product from the store catalog. This action cannot be undone.',
                    style: AppTypography.caption.copyWith(color: AppColors.danger),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Permanently Delete Product',
                    variant: AppButtonVariant.destructive,
                    onPressed: _handleHardDelete,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
