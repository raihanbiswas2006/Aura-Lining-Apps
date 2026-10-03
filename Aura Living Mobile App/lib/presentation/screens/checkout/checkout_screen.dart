import '../../../core/utils/input_sanitizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/bangladesh_regions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/aura_button.dart';
import '../../../core/widgets/aura_text_field.dart';
import '../../../domain/entities/address.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/checkout/checkout_cubit.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final VoidCallback onOrderComplete;
  final VoidCallback onViewOrders;

  const CheckoutScreen({
    super.key,
    required this.onOrderComplete,
    required this.onViewOrders,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressFormKey = GlobalKey<FormState>();

  // Bangladesh Address Controllers
  final _nameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _postalController = TextEditingController(text: '1212');
  final _phoneController = TextEditingController(text: '+8801712345678');
  
  String _selectedDivision = 'Dhaka';
  String _selectedDistrict = 'Dhaka';
  String _selectedThana = 'Gulshan';

  // Payment Controllers
  final _cardNumberController = TextEditingController(text: '4242 •••• •••• 4242');
  final _expiryController = TextEditingController(text: '08/28');
  final _cvvController = TextEditingController(text: '888');
  final _cardHolderController = TextEditingController();
  final _mfsNumberController = TextEditingController();
  final _mfsTrxController = TextEditingController();

  bool _isNewAddress = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      final defaultAddr = authState.user.defaultAddress;
      if (defaultAddr != null) {
        context.read<CheckoutCubit>().setInitialAddress(defaultAddr);
        _cardHolderController.text = authState.user.name;
        _selectedDivision = defaultAddr.division;
        _selectedDistrict = defaultAddr.district;
        _selectedThana = defaultAddr.thana;
      } else {
        _isNewAddress = true;
        _nameController.text = authState.user.name;
        _cardHolderController.text = authState.user.name;
      }
    } else {
      _isNewAddress = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _postalController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _mfsNumberController.dispose();
    _mfsTrxController.dispose();
    super.dispose();
  }

  void _proceedFromAddress() {
    final checkoutCubit = context.read<CheckoutCubit>();
    if (_isNewAddress) {
      if (!_addressFormKey.currentState!.validate()) {
        return;
      }

      final address = Address(
        id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
        fullName: InputSanitizer.sanitizeText(_nameController.text, maxLength: 100),
        addressLine1: InputSanitizer.sanitizeText(_address1Controller.text, maxLength: 200),
        addressLine2: InputSanitizer.sanitizeText(_address2Controller.text, maxLength: 200),
        city: _selectedDistrict,
        division: _selectedDivision,
        district: _selectedDistrict,
        thana: _selectedThana,
        postalCode: InputSanitizer.sanitizeText(_postalController.text, maxLength: 20),
        country: BangladeshRegions.country,
        phone: BangladeshRegions.normalizePhone(_phoneController.text.trim()) ?? _phoneController.text.trim(),
        isDefault: true,
      );

      checkoutCubit.selectAddress(address);
    } else {
      if (checkoutCubit.state.shippingAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or add a delivery address')),
        );
        return;
      }
      checkoutCubit.goToStep(CheckoutStep.shippingMethod);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state.completedOrder != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OrderConfirmationScreen(
                order: state.completedOrder!,
                onContinueShopping: widget.onOrderComplete,
                onViewOrders: widget.onViewOrders,
              ),
            ),
          );
        }
      },
      builder: (context, checkoutState) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Checkout — Aura Living BD'),
          ),
          body: Column(
            children: [
              // Step Progress Tracker
              _buildProgressTracker(checkoutState.currentStep),

              // Active Step Form Container
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    if (checkoutState.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.discountBadge.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.discountBadge),
                        ),
                        child: Text(
                          checkoutState.error!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.discountBadge,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    if (checkoutState.currentStep == CheckoutStep.shippingAddress)
                      _buildStep1ShippingAddress(context, checkoutState)
                    else if (checkoutState.currentStep == CheckoutStep.shippingMethod)
                      _buildStep2ShippingMethod(context, checkoutState)
                    else if (checkoutState.currentStep == CheckoutStep.paymentMethod)
                      _buildStep3PaymentMethod(context, checkoutState)
                    else if (checkoutState.currentStep == CheckoutStep.review)
                      _buildStep4Review(context, checkoutState),
                  ],
                ),
              ),

              // Sticky Bottom Navigation CTA
              _buildBottomBar(context, checkoutState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressTracker(CheckoutStep currentStep) {
    final steps = [
      {'step': CheckoutStep.shippingAddress, 'label': 'Address'},
      {'step': CheckoutStep.shippingMethod, 'label': 'Courier'},
      {'step': CheckoutStep.paymentMethod, 'label': 'Payment'},
      {'step': CheckoutStep.review, 'label': 'Review'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: steps.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final step = item['step'] as CheckoutStep;
          final isCurrent = currentStep == step;
          final isPast = currentStep.index > step.index;

          return Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent || isPast
                      ? AppColors.primary
                      : AppColors.surfaceSecondary,
                  border: Border.all(
                    color: isCurrent || isPast
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Center(
                  child: isPast
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item['label'] as String,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              if (idx < steps.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    width: 16,
                    height: 1,
                    color: isPast ? AppColors.primary : AppColors.border,
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStep1ShippingAddress(BuildContext context, CheckoutState state) {
    final authState = context.watch<AuthCubit>().state;
    final savedAddresses = authState is Authenticated ? authState.user.addresses : <Address>[];

    final availableDistricts = BangladeshRegions.districtsByDivision[_selectedDivision] ?? ['Dhaka'];
    final availableThanas = BangladeshRegions.getThanasForDistrict(_selectedDistrict);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Bangladesh Delivery Address', style: AppTypography.titleLarge),
        const SizedBox(height: 6),
        Text(
          'We deliver nationwide across all 64 districts with verified courier tracking.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 20),

        if (savedAddresses.isNotEmpty && !_isNewAddress) ...[
          ...savedAddresses.map((addr) {
            final isSelected = state.shippingAddress?.id == addr.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: RadioListTile<String>(
                  value: addr.id,
                  groupValue: state.shippingAddress?.id,
                  activeColor: AppColors.primary,
                  title: Text(addr.fullName, style: AppTypography.titleSmall),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(addr.formattedAddress, style: AppTypography.bodySmall),
                      Text('Mobile: ${addr.phone}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  onChanged: (_) {
                    context.read<CheckoutCubit>().setInitialAddress(addr);
                  },
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Deliver to a Different Address'),
            onPressed: () {
              setState(() {
                _isNewAddress = true;
              });
            },
          ),
        ] else ...[
          Form(
            key: _addressFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (savedAddresses.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Use Saved Address'),
                    onPressed: () {
                      setState(() {
                        _isNewAddress = false;
                      });
                    },
                  ),
                AuraTextField(
                  label: 'RECIPIENT FULL NAME *',
                  hintText: 'e.g. Raihan Biswas',
                  controller: _nameController,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Recipient name is required' : null,
                ),
                const SizedBox(height: 14),
                AuraTextField(
                  label: 'BANGLADESH MOBILE NUMBER *',
                  hintText: '+880 1712-345678 or 017XXXXXXXX',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Mobile number is required for courier delivery';
                    }
                    if (!BangladeshRegions.phoneRegex.hasMatch(v.replaceAll(RegExp(r'[\s\-]'), ''))) {
                      return 'Enter a valid BD number (e.g., +88017XXXXXXXX or 017XXXXXXXX)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

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
                const SizedBox(height: 14),

                // Thana & Postal Code
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
                        hintText: 'e.g. 1213',
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
                const SizedBox(height: 14),

                AuraTextField(
                  label: 'STREET / AREA / ROAD / HOUSE *',
                  hintText: 'e.g. House 42, Road 11, Block D',
                  controller: _address1Controller,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Street address is required' : null,
                ),
                const SizedBox(height: 14),

                AuraTextField(
                  label: 'APARTMENT, FLOOR, LANDMARK (OPTIONAL)',
                  hintText: 'e.g. Apt 4B, Opposite to City Bank',
                  controller: _address2Controller,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2ShippingMethod(BuildContext context, CheckoutState state) {
    final cartState = context.watch<CartCubit>().state;
    final isFreeThreshold = cartState.subtotal >= 5000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Courier & Delivery Options', style: AppTypography.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Handcrafted pieces are carefully inspected and packaged with recyclable honeycomb wrap.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 20),

        if (isFreeThreshold)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accentForest.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.accentForest.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: AppColors.accentForest, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Complimentary Delivery unlocked! (Orders over ৳5,000)',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.accentForest,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Option 1: Inside Dhaka
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: state.shippingMethod == 'dhaka'
                    ? AppColors.primary
                    : AppColors.border,
                width: state.shippingMethod == 'dhaka' ? 1.5 : 1,
              ),
            ),
            child: RadioListTile<String>(
              value: 'dhaka',
              groupValue: state.shippingMethod,
              activeColor: AppColors.primary,
              title: Text(
                isFreeThreshold ? 'Inside Dhaka Metro — FREE' : 'Inside Dhaka Metro — ৳80.00',
                style: AppTypography.titleSmall,
              ),
              subtitle: Text(
                'Delivered in 1–2 business days via Aura In-House fleet or Pathao Courier.',
                style: AppTypography.bodySmall,
              ),
              onChanged: (_) {
                context.read<CheckoutCubit>().selectShippingMethod('dhaka', subtotal: cartState.subtotal);
              },
            ),
          ),
        ),

        // Option 2: Outside Dhaka (Nationwide)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: state.shippingMethod == 'outside_dhaka'
                    ? AppColors.primary
                    : AppColors.border,
                width: state.shippingMethod == 'outside_dhaka' ? 1.5 : 1,
              ),
            ),
            child: RadioListTile<String>(
              value: 'outside_dhaka',
              groupValue: state.shippingMethod,
              activeColor: AppColors.primary,
              title: Text(
                isFreeThreshold ? 'Outside Dhaka (Nationwide) — FREE' : 'Outside Dhaka (Nationwide) — ৳150.00',
                style: AppTypography.titleSmall,
              ),
              subtitle: Text(
                'Delivered in 2–4 business days across all districts via Steadfast Courier.',
                style: AppTypography.bodySmall,
              ),
              onChanged: (_) {
                context.read<CheckoutCubit>().selectShippingMethod('outside_dhaka', subtotal: cartState.subtotal);
              },
            ),
          ),
        ),

        // Option 3: Express Same-Day
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: state.shippingMethod == 'express'
                  ? AppColors.primary
                  : AppColors.border,
              width: state.shippingMethod == 'express' ? 1.5 : 1,
            ),
          ),
          child: RadioListTile<String>(
            value: 'express',
            groupValue: state.shippingMethod,
            activeColor: AppColors.primary,
            title: Text(
              'Express Same-Day Dhaka — ৳250.00',
              style: AppTypography.titleSmall,
            ),
            subtitle: Text(
              'Guaranteed delivery within 12 hours for urgent installations.',
              style: AppTypography.bodySmall,
            ),
            onChanged: (_) {
              context.read<CheckoutCubit>().selectShippingMethod('express', subtotal: cartState.subtotal);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep3PaymentMethod(BuildContext context, CheckoutState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 3: Payment Method', style: AppTypography.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Select your preferred Bangladesh payment method. Transactions are encrypted.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 20),

        // 1. Cash on Delivery (COD)
        _buildPaymentOption(
          context: context,
          currentValue: state.paymentMethod,
          targetValue: 'cod',
          title: 'Cash on Delivery (COD)',
          subtitle: 'Pay with cash upon door inspection across all Bangladesh districts',
          badgeColor: AppColors.primary,
          badgeText: 'POPULAR',
        ),

        // 2. bKash MFS
        _buildPaymentOption(
          context: context,
          currentValue: state.paymentMethod,
          targetValue: 'bkash',
          title: 'bKash Mobile Payment',
          subtitle: 'Instant checkout via Bangladesh\'s premier MFS wallet',
          badgeColor: const Color(0xFFD8226B), // bKash Pink
          badgeText: 'bKash',
          child: state.paymentMethod == 'bkash' ? _buildMfsInput('bKash') : null,
        ),

        // 3. Nagad
        _buildPaymentOption(
          context: context,
          currentValue: state.paymentMethod,
          targetValue: 'nagad',
          title: 'Nagad Digital Payment',
          subtitle: 'Post-office digital banking checkout with instant verification',
          badgeColor: const Color(0xFFF7941D), // Nagad Orange
          badgeText: 'Nagad',
          child: state.paymentMethod == 'nagad' ? _buildMfsInput('Nagad') : null,
        ),

        // 4. Rocket (DBBL)
        _buildPaymentOption(
          context: context,
          currentValue: state.paymentMethod,
          targetValue: 'rocket',
          title: 'DBBL Rocket',
          subtitle: 'Dutch-Bangla Bank mobile banking account payment',
          badgeColor: const Color(0xFF8C3494), // Rocket Purple
          badgeText: 'Rocket',
          child: state.paymentMethod == 'rocket' ? _buildMfsInput('Rocket') : null,
        ),

        // 5. Credit / Debit Card
        _buildPaymentOption(
          context: context,
          currentValue: state.paymentMethod,
          targetValue: 'card',
          title: 'Credit / Debit Card',
          subtitle: 'Visa, Mastercard, Amex (SSLCommerz Gateway simulation)',
          badgeColor: AppColors.accentForest,
          badgeText: 'CARD',
          child: state.paymentMethod == 'card' ? _buildCardInputs() : null,
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required String currentValue,
    required String targetValue,
    required String title,
    required String subtitle,
    required Color badgeColor,
    required String badgeText,
    Widget? child,
  }) {
    final isSelected = currentValue == targetValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            value: targetValue,
            groupValue: currentValue,
            activeColor: AppColors.primary,
            title: Row(
              children: [
                Text(title, style: AppTypography.titleSmall),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
              ],
            ),
            subtitle: Text(subtitle, style: AppTypography.bodySmall),
            onChanged: (val) {
              if (val != null) {
                context.read<CheckoutCubit>().selectPaymentMethod(
                  val,
                  mfsTransactionId: _mfsTrxController.text.trim().isNotEmpty
                      ? _mfsTrxController.text.trim()
                      : null,
                );
              }
            },
          ),
          ?child,
        ],
      ),
    );
  }

  Widget _buildMfsInput(String providerName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'Merchant Wallet Number: 01712-345678 (Personal / Counter 1)',
            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.accentForest),
          ),
          const SizedBox(height: 10),
          AuraTextField(
            label: 'YOUR $providerName ACCOUNT NUMBER',
            hintText: '01XXXXXXXXX',
            controller: _mfsNumberController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          AuraTextField(
            label: 'TRANSACTION ID (TRXID) *',
            hintText: 'e.g. 9K284L01 or auto-generated',
            controller: _mfsTrxController,
            onChanged: (val) {
              context.read<CheckoutCubit>().selectPaymentMethod(
                providerName.toLowerCase(),
                mfsTransactionId: val.trim(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardInputs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          AuraTextField(
            label: 'CARD NUMBER',
            controller: _cardNumberController,
            hintText: '4242 •••• •••• 4242',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AuraTextField(
                  label: 'EXPIRY',
                  controller: _expiryController,
                  hintText: 'MM/YY',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuraTextField(
                  label: 'CVV',
                  controller: _cvvController,
                  hintText: '123',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Review(BuildContext context, CheckoutState state) {
    final cartState = context.watch<CartCubit>().state;
    final finalTotal = cartState.subtotal - cartState.discountAmount + state.shippingCost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 4: Review Order', style: AppTypography.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Please verify shipping and payment details before completing purchase.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 20),

        // Address Summary
        Container(
          padding: const EdgeInsets.all(16),
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
                  Text('BANGLADESH SHIPPING DESTINATION', style: AppTypography.overline),
                  InkWell(
                    onTap: () => context.read<CheckoutCubit>().goToStep(CheckoutStep.shippingAddress),
                    child: Text(
                      'Edit',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentForest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(state.shippingAddress?.fullName ?? '', style: AppTypography.titleSmall),
              Text(state.shippingAddress?.formattedAddress ?? '', style: AppTypography.bodySmall),
              Text('Mobile: ${state.shippingAddress?.phone ?? ''}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Shipping & Payment Summary
        Container(
          padding: const EdgeInsets.all(16),
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
                  Text('COURIER & PAYMENT METHOD', style: AppTypography.overline),
                  InkWell(
                    onTap: () => context.read<CheckoutCubit>().goToStep(CheckoutStep.paymentMethod),
                    child: Text(
                      'Edit',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentForest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(state.shippingMethodTitle, style: AppTypography.bodySmall),
              const SizedBox(height: 4),
              Text(
                'Payment: ${state.paymentMethod.toUpperCase()}${state.mfsTransactionId != null ? ' (Trx: ${state.mfsTransactionId})' : ''}',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.accentForest),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Items Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ORDER SUMMARY (${cartState.itemCount} PIECES)', style: AppTypography.overline),
              const SizedBox(height: 10),
              ...cartState.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.product.title} (${item.selectedVariant.title}) × ${item.quantity}',
                          style: AppTypography.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(item.subtotal),
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: AppTypography.bodySmall),
                  Text(CurrencyFormatter.format(cartState.subtotal), style: AppTypography.bodySmall),
                ],
              ),
              if (cartState.discountAmount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Discount (${cartState.appliedCoupon?.code ?? ""})',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.discountBadge)),
                    Text('-${CurrencyFormatter.format(cartState.discountAmount)}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.discountBadge)),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Courier Shipping', style: AppTypography.bodySmall),
                  Text(
                    state.shippingCost == 0 ? 'FREE' : CurrencyFormatter.format(state.shippingCost),
                    style: AppTypography.bodySmall.copyWith(
                      color: state.shippingCost == 0 ? AppColors.accentForest : AppColors.textPrimary,
                      fontWeight: state.shippingCost == 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Grand Total', style: AppTypography.titleMedium),
                  Text(
                    CurrencyFormatter.format(finalTotal),
                    style: AppTypography.price.copyWith(color: AppColors.accentForest),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, CheckoutState state) {
    final cartCubit = context.watch<CartCubit>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: AuraPrimaryButton(
          label: _getButtonText(state.currentStep),
          isLoading: state.isPlacingOrder,
          onPressed: () => _handleNextStep(context, state, cartCubit),
        ),
      ),
    );
  }

  String _getButtonText(CheckoutStep step) {
    switch (step) {
      case CheckoutStep.shippingAddress:
        return 'Continue to Delivery Options';
      case CheckoutStep.shippingMethod:
        return 'Continue to Payment';
      case CheckoutStep.paymentMethod:
        return 'Review Order';
      case CheckoutStep.review:
        return 'Confirm & Place Order (BDT)';
    }
  }

  void _handleNextStep(
    BuildContext context,
    CheckoutState state,
    CartCubit cartCubit,
  ) {
    if (state.isPlacingOrder) return;
    final cubit = context.read<CheckoutCubit>();

    switch (state.currentStep) {
      case CheckoutStep.shippingAddress:
        _proceedFromAddress();
        break;
      case CheckoutStep.shippingMethod:
        cubit.goToStep(CheckoutStep.paymentMethod);
        break;
      case CheckoutStep.paymentMethod:
        cubit.selectPaymentMethod(
          state.paymentMethod,
          mfsTransactionId: _mfsTrxController.text.trim().isNotEmpty
              ? _mfsTrxController.text.trim()
              : null,
        );
        break;
      case CheckoutStep.review:
        final authState = context.read<AuthCubit>().state;
        final userId = authState is Authenticated ? authState.user.id : 'guest-user';
        cubit.placeOrder(
          cartState: cartCubit.state,
          userId: userId,
          onOrderSuccess: () async {
            cartCubit.clearCart();
          },
        );
        break;
    }
  }
}
