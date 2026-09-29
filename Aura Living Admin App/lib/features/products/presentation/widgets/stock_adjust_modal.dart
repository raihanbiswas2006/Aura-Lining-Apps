import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/product.dart';

class StockAdjustModal extends StatefulWidget {
  final Product product;
  final Future<void> Function(int newQty, String? variantId) onSave;

  const StockAdjustModal({
    super.key,
    required this.product,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    required Future<void> Function(int newQty, String? variantId) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StockAdjustModal(
        product: product,
        onSave: onSave,
      ),
    );
  }

  @override
  State<StockAdjustModal> createState() => _StockAdjustModalState();
}

class _StockAdjustModalState extends State<StockAdjustModal> {
  String? _selectedVariantId;
  late int _currentQuantity;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product.hasVariants && widget.product.variants.isNotEmpty) {
      _selectedVariantId = widget.product.variants.first.id;
      _currentQuantity = widget.product.variants.first.stockQuantity;
    } else {
      _currentQuantity = widget.product.stockQuantity;
    }
  }

  void _onVariantChanged(String? variantId) {
    if (variantId == null) return;
    final v = widget.product.variants.firstWhere((x) => x.id == variantId);
    setState(() {
      _selectedVariantId = variantId;
      _currentQuantity = v.stockQuantity;
    });
  }

  void _increment([int amount = 1]) {
    setState(() {
      _currentQuantity += amount;
    });
  }

  void _decrement([int amount = 1]) {
    if (_currentQuantity - amount >= 0) {
      setState(() {
        _currentQuantity -= amount;
      });
    } else {
      setState(() {
        _currentQuantity = 0;
      });
    }
  }

  void _save() async {
    setState(() => _isLoading = true);
    try {
      await widget.onSave(_currentQuantity, _selectedVariantId);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock adjusted to $_currentQuantity units for ${widget.product.title}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update stock: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Product Info
          Text(
            'Quick Stock Adjustment',
            style: AppTypography.sectionHeader.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            widget.product.title,
            style: AppTypography.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Variant Selector if applicable
          if (widget.product.hasVariants && widget.product.variants.isNotEmpty) ...[
            Text('Select Variant:', style: AppTypography.dataLabel),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedVariantId,
                  isExpanded: true,
                  items: widget.product.variants.map((v) {
                    return DropdownMenuItem<String>(
                      value: v.id,
                      child: Text(
                        '${v.attributeName}: ${v.attributeValue} (Current: ${v.stockQuantity})',
                        style: AppTypography.body.copyWith(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: _onVariantChanged,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Stepper & Quantity Display
          Center(
            child: Column(
              children: [
                StatusBadge.stock(_currentQuantity),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stepperButton(
                      icon: Icons.remove,
                      onTap: () => _decrement(1),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 90,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '$_currentQuantity',
                        style: AppTypography.metricCallout.copyWith(fontSize: 26),
                      ),
                    ),
                    const SizedBox(width: 20),
                    _stepperButton(
                      icon: Icons.add,
                      onTap: () => _increment(1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quick +5 / +10 / Set 0 pills
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Set 0 (Out)'),
                      labelStyle: const TextStyle(fontSize: 11, color: AppColors.danger),
                      side: const BorderSide(color: AppColors.danger, width: 0.5),
                      onPressed: () => setState(() => _currentQuantity = 0),
                    ),
                    ActionChip(
                      label: const Text('+5'),
                      labelStyle: const TextStyle(fontSize: 11),
                      onPressed: () => _increment(5),
                    ),
                    ActionChip(
                      label: const Text('+10'),
                      labelStyle: const TextStyle(fontSize: 11),
                      onPressed: () => _increment(10),
                    ),
                    ActionChip(
                      label: const Text('+25'),
                      labelStyle: const TextStyle(fontSize: 11),
                      onPressed: () => _increment(25),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Cancel',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'Save Stock',
                  isLoading: _isLoading,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: AppColors.textPrimary),
        onPressed: onTap,
      ),
    );
  }
}
