import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../domain/category.dart';
import '../../auth/presentation/auth_controller.dart';

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final productRepo = ref.watch(productRepositoryProvider);
  return productRepo.watchCategories();
});

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditCategoryModal({Category? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryFormSheet(
        category: existing,
        onSaved: () {
          ref.invalidate(categoriesProvider);
        },
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDestructiveConfirmDialog(
      context: context,
      title: 'Delete "${category.name}"?',
      consequenceText:
          'This will permanently remove this category. Categories with active products cannot be deleted.',
      confirmButtonText: 'Delete Category',
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(productRepositoryProvider);
        await repo.deleteCategory(category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "${category.name}" deleted.'),
              backgroundColor: AppColors.primaryOlive,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  IconData _resolveIcon(String iconName) {
    switch (iconName) {
      case 'chair_outlined':
        return Icons.chair_outlined;
      case 'yard_outlined':
        return Icons.yard_outlined;
      case 'lightbulb_outlined':
        return Icons.lightbulb_outlined;
      case 'bed_outlined':
        return Icons.bed_outlined;
      case 'table_restaurant_outlined':
        return Icons.table_restaurant_outlined;
      case 'kitchen_outlined':
        return Icons.kitchen_outlined;
      case 'spa_outlined':
        return Icons.spa_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final canManage = user?.role.canManageCatalog ?? false;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Category Management'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Category',
              onPressed: () => _showAddEditCategoryModal(),
            ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final filtered = categories.where((c) {
            if (_searchQuery.isEmpty) return true;
            return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.slug.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              // Search Header
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Categories List
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyStateView(
                        title: 'No Categories Found',
                        subtitle: 'No categories match your search criteria.',
                        icon: Icons.category_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final cat = filtered[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _resolveIcon(cat.icon),
                                  color: AppColors.primaryOlive,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                cat.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                'slug: ${cat.slug}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceSecondary,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      '${cat.productCount} items',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  if (canManage) ...[
                                    const SizedBox(width: 4),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          _showAddEditCategoryModal(existing: cat);
                                        } else if (action == 'delete') {
                                          _deleteCategory(cat);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                                              SizedBox(width: 8),
                                              Text('Edit Category'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: cat.productCount > 0 ? AppColors.textMuted : AppColors.danger,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                cat.productCount > 0 ? 'Delete (Guarded)' : 'Delete Category',
                                                style: TextStyle(
                                                  color: cat.productCount > 0 ? AppColors.textMuted : AppColors.danger,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, __) => const ShimmerCard(height: 64),
        ),
        error: (err, stack) => Center(
          child: Text('Error loading categories: $err'),
        ),
      ),
    );
  }
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  final Category? category;
  final VoidCallback onSaved;

  const _CategoryFormSheet({this.category, required this.onSaved});

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late String _selectedIcon;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _iconOptions = const [
    {'name': 'chair_outlined', 'icon': Icons.chair_outlined, 'label': 'Furniture'},
    {'name': 'yard_outlined', 'icon': Icons.yard_outlined, 'label': 'Decor'},
    {'name': 'lightbulb_outlined', 'icon': Icons.lightbulb_outlined, 'label': 'Lighting'},
    {'name': 'bed_outlined', 'icon': Icons.bed_outlined, 'label': 'Textiles'},
    {'name': 'table_restaurant_outlined', 'icon': Icons.table_restaurant_outlined, 'label': 'Dining'},
    {'name': 'kitchen_outlined', 'icon': Icons.kitchen_outlined, 'label': 'Kitchen'},
    {'name': 'spa_outlined', 'icon': Icons.spa_outlined, 'label': 'Wellness'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _slugController = TextEditingController(text: widget.category?.slug ?? '');
    _selectedIcon = widget.category?.icon ?? 'chair_outlined';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  void _onNameChanged(String val) {
    if (widget.category == null) {
      final slug = val
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      _slugController.text = slug;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(productRepositoryProvider);
      final category = Category(
        id: widget.category?.id ?? '',
        name: _nameController.text.trim(),
        slug: _slugController.text.trim(),
        icon: _selectedIcon,
        productCount: widget.category?.productCount ?? 0,
      );

      if (widget.category != null) {
        await repo.updateCategory(category);
      } else {
        await repo.addCategory(category);
      }

      widget.onSaved();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.category != null ? 'Category updated' : 'Category created',
            ),
            backgroundColor: AppColors.primaryOlive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Category' : 'Add New Category',
                    style: AppTypography.sectionHeader,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Category Name',
                hintText: 'e.g., Dining & Kitchen',
                controller: _nameController,
                onChanged: _onNameChanged,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'URL Slug',
                hintText: 'e.g., dining-kitchen',
                controller: _slugController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter category slug';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'Category Icon',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _iconOptions.map((opt) {
                  final isSelected = _selectedIcon == opt['name'];
                  return ChoiceChip(
                    avatar: Icon(
                      opt['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    label: Text(opt['label'] as String),
                    selected: isSelected,
                    selectedColor: AppColors.primaryOlive,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedIcon = opt['name'] as String);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: isEditing ? 'Update Category' : 'Create Category',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
