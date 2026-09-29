import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/bangladesh_regions.dart';
import '../../../core/widgets/aura_button.dart';
import '../../../core/widgets/aura_text_field.dart';
import '../../../domain/entities/address.dart';
import '../../blocs/auth/auth_cubit.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  void _openAddressForm(BuildContext context, {Address? initialAddress}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressFormSheet(initialAddress: initialAddress),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Addresses — Bangladesh'),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final addresses = state is Authenticated ? state.user.addresses : <Address>[];

          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('No Saved Addresses', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Add your delivery locations across Bangladesh for instant checkout.',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Bangladesh Address'),
                      onPressed: () => _openAddressForm(context),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: addresses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: address.isDefault ? AppColors.primary : AppColors.border,
                    width: address.isDefault ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(address.fullName, style: AppTypography.titleSmall),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(address.formattedAddress, style: AppTypography.bodyMedium),
                    const SizedBox(height: 4),
                    Text('Mobile: ${address.phone}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _openAddressForm(context, initialAddress: address),
                          child: const Text('Edit'),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<AuthCubit>().deleteAddress(address.id);
                          },
                          child: Text(
                            'Delete',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.discountBadge,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add New Address'),
            onPressed: () => _openAddressForm(context),
          ),
        ),
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  final Address? initialAddress;

  const _AddressFormSheet({this.initialAddress});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _postalController;
  late TextEditingController _phoneController;

  late String _selectedDivision;
  late String _selectedDistrict;
  late String _selectedThana;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.initialAddress;
    _nameController = TextEditingController(text: addr?.fullName ?? '');
    _address1Controller = TextEditingController(text: addr?.addressLine1 ?? '');
    _address2Controller = TextEditingController(text: addr?.addressLine2 ?? '');
    _postalController = TextEditingController(text: addr?.postalCode ?? '1212');
    _phoneController = TextEditingController(text: addr?.phone ?? '+8801712345678');

    _selectedDivision = addr?.division ?? 'Dhaka';
    _selectedDistrict = addr?.district ?? 'Dhaka';
    _selectedThana = addr?.thana ?? 'Gulshan';
    _isDefault = addr?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _postalController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final address = Address(
      id: widget.initialAddress?.id ?? 'addr-${DateTime.now().millisecondsSinceEpoch}',
      fullName: _nameController.text.trim(),
      addressLine1: _address1Controller.text.trim(),
      addressLine2: _address2Controller.text.trim(),
      city: _selectedDistrict,
      division: _selectedDivision,
      district: _selectedDistrict,
      thana: _selectedThana,
      postalCode: _postalController.text.trim(),
      country: BangladeshRegions.country,
      phone: BangladeshRegions.normalizePhone(_phoneController.text.trim()) ?? _phoneController.text.trim(),
      isDefault: _isDefault,
    );

    final cubit = context.read<AuthCubit>();
    if (widget.initialAddress != null) {
      cubit.updateAddress(address);
    } else {
      cubit.addAddress(address);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final availableDistricts = BangladeshRegions.districtsByDivision[_selectedDivision] ?? ['Dhaka'];
    final availableThanas = BangladeshRegions.getThanasForDistrict(_selectedDistrict);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.initialAddress != null ? 'Edit Address' : 'Add Bangladesh Address',
                      style: AppTypography.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                AuraTextField(
                  label: 'FULL RECIPIENT NAME *',
                  hintText: 'e.g. Raihan Biswas',
                  controller: _nameController,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                AuraTextField(
                  label: 'BANGLADESH MOBILE NUMBER *',
                  hintText: '+880 1712-345678 or 017XXXXXXXX',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Mobile is required';
                    if (!BangladeshRegions.phoneRegex.hasMatch(v.replaceAll(RegExp(r'[\s\-]'), ''))) {
                      return 'Enter a valid BD number (+8801XXXXXXXXX or 01XXXXXXXXX)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Division and District Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DIVISION *', style: AppTypography.overline),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedDivision,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                items: BangladeshRegions.divisions.map((d) {
                                  return DropdownMenuItem(value: d, child: Text(d, style: AppTypography.bodyMedium));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedDivision = val;
                                      final districts = BangladeshRegions.districtsByDivision[val] ?? ['Dhaka'];
                                      _selectedDistrict = districts.first;
                                      final thanas = BangladeshRegions.getThanasForDistrict(_selectedDistrict);
                                      _selectedThana = thanas.first;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DISTRICT *', style: AppTypography.overline),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: availableDistricts.contains(_selectedDistrict)
                                    ? _selectedDistrict
                                    : availableDistricts.first,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                items: availableDistricts.map((d) {
                                  return DropdownMenuItem(value: d, child: Text(d, style: AppTypography.bodyMedium));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedDistrict = val;
                                      final thanas = BangladeshRegions.getThanasForDistrict(val);
                                      _selectedThana = thanas.first;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Thana and Postal Code
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('THANA / UPAZILA *', style: AppTypography.overline),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: availableThanas.contains(_selectedThana)
                                    ? _selectedThana
                                    : availableThanas.first,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                items: availableThanas.map((t) {
                                  return DropdownMenuItem(value: t, child: Text(t, style: AppTypography.bodyMedium));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedThana = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AuraTextField(
                        label: 'POSTAL CODE *',
                        hintText: '1213',
                        controller: _postalController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!BangladeshRegions.postalCodeRegex.hasMatch(v.trim())) {
                            return '4-digit code';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                AuraTextField(
                  label: 'STREET / AREA / HOUSE / ROAD *',
                  hintText: 'e.g. House 42, Road 11, Block D',
                  controller: _address1Controller,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                AuraTextField(
                  label: 'APARTMENT, SUITE, LANDMARK',
                  hintText: 'e.g. Apt 4B, Opposite to City Bank',
                  controller: _address2Controller,
                ),
                const SizedBox(height: 14),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isDefault,
                  activeColor: AppColors.primary,
                  title: const Text('Set as default delivery address'),
                  onChanged: (val) {
                    setState(() {
                      _isDefault = val ?? false;
                    });
                  },
                ),
                const SizedBox(height: 18),

                AuraPrimaryButton(
                  label: 'Save Bangladesh Address',
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
