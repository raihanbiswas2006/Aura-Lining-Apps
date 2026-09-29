class Coupon {
  final String code;
  final String discountType; // "percentage" | "fixed" | "free_shipping"
  final double value;
  final double minimumOrderValue;

  const Coupon({
    required this.code,
    required this.discountType,
    required this.value,
    required this.minimumOrderValue,
  });

  bool get isPercentage => discountType == 'percentage';
  bool get isFixed => discountType == 'fixed';
  bool get isFreeShipping => discountType == 'free_shipping';

  double calculateDiscount(double subtotal, double shippingCost) {
    if (subtotal < minimumOrderValue) return 0.0;

    switch (discountType) {
      case 'percentage':
        return subtotal * (value / 100.0);
      case 'fixed':
        return value > subtotal ? subtotal : value;
      case 'free_shipping':
        return shippingCost;
      default:
        return 0.0;
    }
  }

  Coupon copyWith({
    String? code,
    String? discountType,
    double? value,
    double? minimumOrderValue,
  }) {
    return Coupon(
      code: code ?? this.code,
      discountType: discountType ?? this.discountType,
      value: value ?? this.value,
      minimumOrderValue: minimumOrderValue ?? this.minimumOrderValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'discountType': discountType,
      'value': value,
      'minimumOrderValue': minimumOrderValue,
    };
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      code: json['code'] as String,
      discountType: json['discountType'] as String,
      value: (json['value'] as num).toDouble(),
      minimumOrderValue: (json['minimumOrderValue'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coupon &&
          runtimeType == other.runtimeType &&
          code.toUpperCase() == other.code.toUpperCase();

  @override
  int get hashCode => code.toUpperCase().hashCode;
}
