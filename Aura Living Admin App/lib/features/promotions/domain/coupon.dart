enum DiscountType {
  percentage('Percentage (%)'),
  fixedAmount('Fixed Amount (৳)');

  final String label;
  const DiscountType(this.label);
}

/// Coupon / Promotion Entity per PRD Section 6.7
class Coupon {
  final String id;
  final String code;
  final DiscountType discountType;
  final double discountValue;
  final double? minimumSpend;
  final DateTime expirationDate;
  final int usageLimit;
  final int usageCount;
  final bool isActive;
  final DateTime createdAt;

  const Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minimumSpend,
    required this.expirationDate,
    required this.usageLimit,
    this.usageCount = 0,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expirationDate);
  bool get isLimitReached => usageCount >= usageLimit;
  bool get isEffectivelyValid => isActive && !isExpired && !isLimitReached;

  String get discountDisplay {
    if (discountType == DiscountType.percentage) {
      return '${discountValue.toStringAsFixed(discountValue % 1 == 0 ? 0 : 1)}%';
    }
    return '৳${discountValue.toStringAsFixed(0)}';
  }

  Coupon copyWith({
    String? id,
    String? code,
    DiscountType? discountType,
    double? discountValue,
    double? minimumSpend,
    DateTime? expirationDate,
    int? usageLimit,
    int? usageCount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Coupon(
      id: id ?? this.id,
      code: code ?? this.code,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minimumSpend: minimumSpend ?? this.minimumSpend,
      expirationDate: expirationDate ?? this.expirationDate,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
