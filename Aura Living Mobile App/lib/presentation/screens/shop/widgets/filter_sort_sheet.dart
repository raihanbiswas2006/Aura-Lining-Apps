import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/aura_button.dart';
import '../../../blocs/catalog/catalog_cubit.dart';

class FilterSortBottomSheet extends StatefulWidget {
  final CatalogFilter initialFilter;
  final String initialSortBy;
  final List<String> availableColors;
  final int totalMatchingItems;
  final void Function(CatalogFilter filter, String sortBy) onApply;

  const FilterSortBottomSheet({
    super.key,
    required this.initialFilter,
    required this.initialSortBy,
    required this.availableColors,
    required this.totalMatchingItems,
    required this.onApply,
  });

  @override
  State<FilterSortBottomSheet> createState() => _FilterSortBottomSheetState();
}

class _FilterSortBottomSheetState extends State<FilterSortBottomSheet> {
  late RangeValues _currentRangeValues;
  late List<String> _selectedColors;
  late bool _inStockOnly;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _currentRangeValues = RangeValues(
      widget.initialFilter.minPrice.clamp(0.0, 1000.0),
      widget.initialFilter.maxPrice.clamp(0.0, 1000.0),
    );
    _selectedColors = List.from(widget.initialFilter.selectedColors);
    _inStockOnly = widget.initialFilter.inStockOnly;
    _sortBy = widget.initialSortBy;
  }

  void _reset() {
    setState(() {
      _currentRangeValues = const RangeValues(0.0, 1000.0);
      _selectedColors.clear();
      _inStockOnly = false;
      _sortBy = 'featured';
    });
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
    final filterCount = (_currentRangeValues.start > 0 || _currentRangeValues.end < 1000 ? 1 : 0) +
        _selectedColors.length +
        (_inStockOnly ? 1 : 0);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters & Sort', style: AppTypography.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(),

          // Filter Content (scrollable)
          Flexible(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shrinkWrap: true,
              children: [
                // Sort By
                Text('SORT BY', style: AppTypography.overline),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSortChip('featured', 'Featured'),
                    _buildSortChip('price_asc', 'Price: Low to High'),
                    _buildSortChip('price_desc', 'Price: High to Low'),
                    _buildSortChip('newest', 'Newest First'),
                    _buildSortChip('rating', 'Customer Rating'),
                  ],
                ),
                const SizedBox(height: 24),

                // Price Range
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PRICE RANGE', style: AppTypography.overline),
                    Text(
                      '${CurrencyFormatter.format(_currentRangeValues.start)} — ${CurrencyFormatter.format(_currentRangeValues.end)}',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RangeSlider(
                  values: _currentRangeValues,
                  min: 0.0,
                  max: 1000.0,
                  divisions: 20,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  labels: RangeLabels(
                    CurrencyFormatter.format(_currentRangeValues.start),
                    CurrencyFormatter.format(_currentRangeValues.end),
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _currentRangeValues = values;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Colors
                if (widget.availableColors.isNotEmpty) ...[
                  Text('PALETTE & COLORWAYS', style: AppTypography.overline),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableColors.map((colorName) {
                      final isSelected = _selectedColors.contains(colorName);
                      final swatchColor = _getColorFromLabel(colorName);

                      return FilterChip(
                        selected: isSelected,
                        avatar: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: swatchColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.borderDark,
                              width: 0.8,
                            ),
                          ),
                        ),
                        label: Text(
                          colorName,
                          style: AppTypography.bodySmall.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceSecondary,
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedColors.add(colorName);
                            } else {
                              _selectedColors.remove(colorName);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // In-Stock Only Toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'In-Stock Only',
                            style: AppTypography.titleSmall.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hide currently sold-out items',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _inStockOnly,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _inStockOnly = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Bottom sticky action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AuraOutlineButton(
                    label: 'Reset All',
                    onPressed: _reset,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: AuraPrimaryButton(
                    label: filterCount > 0
                        ? 'Apply Filters ($filterCount)'
                        : 'Apply Filters',
                    onPressed: () {
                      final updatedFilter = widget.initialFilter.copyWith(
                        minPrice: _currentRangeValues.start,
                        maxPrice: _currentRangeValues.end,
                        selectedColors: _selectedColors,
                        inStockOnly: _inStockOnly,
                      );
                      widget.onApply(updatedFilter, _sortBy);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String key, String title) {
    final isSelected = _sortBy == key;
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        title,
        style: AppTypography.bodySmall.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceSecondary,
      onSelected: (val) {
        if (val) {
          setState(() {
            _sortBy = key;
          });
        }
      },
    );
  }
}
