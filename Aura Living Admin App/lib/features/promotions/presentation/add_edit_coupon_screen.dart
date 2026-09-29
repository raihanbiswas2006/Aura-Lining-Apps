import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../domain/coupon.dart';
import 'promotions_controller.dart';

class AddEditCouponScreen extends ConsumerStatefulWidget {
  final String? couponId;

  const AddEditCouponScreen({super.key, this.couponId});

  @override
  ConsumerState<AddEditCouponScreen> createState() => _AddEditCouponScreenState();
}

class _AddEditCouponScreenState extends ConsumerState<AddEditCouponScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minSpendController = TextEditingController();
  final _usageLimitController = TextEditingController(text: '100');

  DiscountType _discountType = DiscountType.percentage;
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _isLoading = false;
  bool _isInit = false;

  @override
  void dispose() {
    _codeController.dispose();
    _discountValueController.dispose();
    _minSpendController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  void _populateData(Coupon coupon) {
    if (_isInit) return;
    _codeController.text = coupon.code;
    _discountValueController.text = coupon.discountValue.toStringAsFixed(
      coupon.discountValue % 1 == 0 ? 0 : 2,
    );
    _minSpendController.text = coupon.minimumSpend != null
        ? coupon.minimumSpend!.toStringAsFixed(coupon.minimumSpend! % 1 == 0 ? 0 : 2)
        : '';
    _usageLimitController.text = coupon.usageLimit.toString();
    _discountType = coupon.discountType;
    _expirationDate = coupon.expirationDate;
    _isActive = coupon.isActive;
    _isInit = true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate.isAfter(DateTime.now())
          ? _expirationDate
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryOlive,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _expirationDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );
      });
    }
  }

  Future<void> _saveCoupon() async {
    if (!_formKey.currentState!.validate()) return;

    if (_expirationDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expiration date cannot be in the past.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(promotionRepositoryProvider);
      final discountVal = double.parse(_discountValueController.text.trim());
      final minSpendVal = _minSpendController.text.trim().isNotEmpty
          ? double.tryParse(_minSpendController.text.trim())
          : null;
      final limitVal = int.parse(_usageLimitController.text.trim());

      final coupon = Coupon(
        id: widget.couponId ?? '',
        code: _codeController.text.trim().toUpperCase(),
        discountType: _discountType,
        discountValue: discountVal,
        minimumSpend: minSpendVal,
        expirationDate: _expirationDate,
        usageLimit: limitVal,
        isActive: _isActive,
        createdAt: DateTime.now(),
      );

      if (widget.couponId != null) {
        await repo.updateCoupon(coupon);
      } else {
        await repo.createCoupon(coupon);
      }

      ref.invalidate(couponsStreamProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.couponId != null ? 'Coupon updated.' : 'Coupon created successfully.',
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

  Future<void> _deleteCoupon(String couponId, String code) async {
    final confirmed = await showDestructiveConfirmDialog(
      context: context,
      title: 'Delete Coupon "$code"?',
      consequenceText:
          'This action cannot be undone and will immediately disable this promotional discount code for all customers.',
      confirmButtonText: 'Delete Forever',
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(promotionRepositoryProvider);
        await repo.deleteCoupon(couponId);
        ref.invalidate(couponsStreamProvider);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Coupon "$code" deleted.'),
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.couponId != null;

    if (isEditing) {
      final couponAsync = ref.watch(couponDetailProvider(widget.couponId!));
      return couponAsync.when(
        data: (coupon) {
          if (coupon != null) _populateData(coupon);
          return _buildForm(isEditing, coupon);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Coupon')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          appBar: AppBar(title: const Text('Edit Coupon')),
          body: Center(child: Text('Error: $err')),
        ),
      );
    }

    return _buildForm(false, null);
  }

  Widget _buildForm(bool isEditing, Coupon? coupon) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Coupon' : 'Create Promotion Code'),
        actions: [
          if (isEditing && coupon != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              tooltip: 'Delete Coupon',
              onPressed: () => _deleteCoupon(coupon.id, coupon.code),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Code & Active Toggle Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Coupon Code (Uppercase Alphanumeric) *',
                      hintText: 'e.g., AURA15, SPRING2026',
                      controller: _codeController,
                      validator: AppValidators.validateCouponCode,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Status: Active & Usable', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Toggle off to immediately pause this coupon', style: TextStyle(fontSize: 12)),
                      value: _isActive,
                      activeColor: AppColors.primaryOlive,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Discount Type & Value Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Discount Calculation *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Percentage (%)')),
                            selected: _discountType == DiscountType.percentage,
                            selectedColor: AppColors.primaryOlive,
                            labelStyle: TextStyle(
                              color: _discountType == DiscountType.percentage ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _discountType = DiscountType.percentage);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Fixed Amount (৳)')),
                            selected: _discountType == DiscountType.fixedAmount,
                            selectedColor: AppColors.primaryOlive,
                            labelStyle: TextStyle(
                              color: _discountType == DiscountType.fixedAmount ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _discountType = DiscountType.fixedAmount);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: _discountType == DiscountType.percentage ? 'Discount Value (%) *' : 'Discount Value (৳) *',
                      hintText: _discountType == DiscountType.percentage ? 'e.g., 15' : 'e.g., 500',
                      controller: _discountValueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: _discountType == DiscountType.fixedAmount
                          ? const Center(widthFactor: 1.0, child: Text('৳', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
                          : const Icon(Icons.percent, size: 18),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter discount value';
                        final num = double.tryParse(val.trim());
                        if (num == null || num <= 0) return 'Must be greater than 0';
                        if (_discountType == DiscountType.percentage && num > 100) {
                          return 'Discount cannot exceed 100%';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Minimum Spend Requirement (Optional)',
                      hintText: 'e.g., 50.00 (leave blank for no minimum)',
                      controller: _minSpendController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final num = double.tryParse(val.trim());
                          if (num == null || num < 0) return 'Enter valid positive amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Usage Limits & Expiration
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Usage Limits & Expiration *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Total Storewide Usage Limit *',
                      hintText: 'e.g., 500',
                      controller: _usageLimitController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.tag, size: 18),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter usage limit';
                        final num = int.tryParse(val.trim());
                        if (num == null || num <= 0) return 'Must be a positive integer';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('Expiration Date *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primaryOlive),
                            const SizedBox(width: 10),
                            Text(
                              AppFormatters.formatDate(_expirationDate),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            const Text('Change', style: TextStyle(fontSize: 12, color: AppColors.primaryOlive, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                text: isEditing ? 'Update Coupon' : 'Create Promotion Code',
                isLoading: _isLoading,
                onPressed: _saveCoupon,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
