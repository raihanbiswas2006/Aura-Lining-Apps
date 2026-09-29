export 'staff_member.dart';

/// Store Settings Model per PRD Section 6.8
class StoreSettings {
  final bool isOpenForOrders;
  final String contactEmail;
  final String supportPhone;
  final String currencySymbol;
  final double baseShippingFee;
  final double freeShippingThreshold;
  final String storeName;

  const StoreSettings({
    this.isOpenForOrders = true,
    this.contactEmail = 'support@auraliving.bd',
    this.supportPhone = '+880 1712-345678',
    this.currencySymbol = '৳',
    this.baseShippingFee = 80.0,
    this.freeShippingThreshold = 5000.0,
    this.storeName = 'Aura Living',
  });

  StoreSettings copyWith({
    bool? isOpenForOrders,
    String? contactEmail,
    String? supportPhone,
    String? currencySymbol,
    double? baseShippingFee,
    double? freeShippingThreshold,
    String? storeName,
  }) {
    return StoreSettings(
      isOpenForOrders: isOpenForOrders ?? this.isOpenForOrders,
      contactEmail: contactEmail ?? this.contactEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      baseShippingFee: baseShippingFee ?? this.baseShippingFee,
      freeShippingThreshold: freeShippingThreshold ?? this.freeShippingThreshold,
      storeName: storeName ?? this.storeName,
    );
  }
}
