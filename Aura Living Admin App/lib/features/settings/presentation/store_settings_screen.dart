import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/store_settings.dart';
import 'settings_controller.dart';
import '../../auth/presentation/auth_controller.dart';

class StoreSettingsScreen extends ConsumerStatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  ConsumerState<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _storeNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _currencySymbolController = TextEditingController();
  final _baseShippingFeeController = TextEditingController();
  final _freeShippingThresholdController = TextEditingController();

  bool _isOpenForOrders = true;
  bool _isInit = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _contactEmailController.dispose();
    _supportPhoneController.dispose();
    _currencySymbolController.dispose();
    _baseShippingFeeController.dispose();
    _freeShippingThresholdController.dispose();
    super.dispose();
  }

  void _populate(StoreSettings settings) {
    if (_isInit) return;
    _storeNameController.text = settings.storeName;
    _contactEmailController.text = settings.contactEmail;
    _supportPhoneController.text = settings.supportPhone;
    _currencySymbolController.text = settings.currencySymbol;
    _baseShippingFeeController.text = settings.baseShippingFee.toStringAsFixed(2);
    _freeShippingThresholdController.text = settings.freeShippingThreshold.toStringAsFixed(2);
    _isOpenForOrders = settings.isOpenForOrders;
    _isInit = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(settingsRepositoryProvider);
      final updated = StoreSettings(
        storeName: _storeNameController.text.trim(),
        isOpenForOrders: _isOpenForOrders,
        contactEmail: _contactEmailController.text.trim(),
        supportPhone: _supportPhoneController.text.trim(),
        currencySymbol: _currencySymbolController.text.trim(),
        baseShippingFee: double.tryParse(_baseShippingFeeController.text.trim()) ?? 15.0,
        freeShippingThreshold: double.tryParse(_freeShippingThresholdController.text.trim()) ?? 150.0,
      );

      await repo.updateStoreSettings(updated);
      ref.invalidate(storeSettingsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store settings updated successfully.'),
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
    final settingsAsync = ref.watch(storeSettingsStreamProvider);
    final user = ref.watch(authControllerProvider).user;
    final canEdit = user?.role.canManageStoreSettings ?? false;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Store Operations Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          _populate(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Master Storefront Status Switch
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isOpenForOrders ? AppColors.success.withOpacity(0.3) : AppColors.warning,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isOpenForOrders ? AppColors.success : AppColors.warning,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isOpenForOrders ? 'Store Active (Open)' : 'Store Paused (Maintenance)',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isOpenForOrders
                                      ? 'Customers can browse and place orders.'
                                      : 'Storefront checkouts are paused for maintenance.',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isOpenForOrders,
                              activeColor: AppColors.success,
                              onChanged: canEdit ? (val) => setState(() => _isOpenForOrders = val) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Store Identity & Contact Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Store Information & Support', style: AppTypography.sectionHeader),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Store Name',
                          controller: _storeNameController,
                          enabled: canEdit,
                          validator: (v) => v == null || v.isEmpty ? 'Store name required' : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Customer Support Email',
                          controller: _contactEmailController,
                          enabled: canEdit,
                          validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Support Phone Number',
                          controller: _supportPhoneController,
                          enabled: canEdit,
                          validator: (v) => v == null || v.isEmpty ? 'Phone number required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Shipping & Currency Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Currency & Shipping Fees', style: AppTypography.sectionHeader),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Currency Symbol',
                          controller: _currencySymbolController,
                          enabled: canEdit,
                          validator: (v) => v == null || v.isEmpty ? 'Currency required' : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Base Standard Shipping Fee (৳)',
                          controller: _baseShippingFeeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: canEdit,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Fee required';
                            if (double.tryParse(v) == null) return 'Must be a number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Free Shipping Threshold (৳)',
                          controller: _freeShippingThresholdController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: canEdit,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Threshold required';
                            if (double.tryParse(v) == null) return 'Must be a number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (canEdit)
                    AppButton(
                      text: 'Save Operational Settings',
                      isLoading: _isLoading,
                      onPressed: _save,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Store settings can only be modified by Super Admins.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
