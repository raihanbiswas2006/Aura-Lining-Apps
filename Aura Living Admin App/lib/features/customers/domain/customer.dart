import '../../orders/domain/order_components.dart';

/// Customer Entity per PRD Section 6.8
class Customer {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final ShippingAddress defaultAddress;
  final DateTime createdAt;
  final int totalOrdersCount;
  final double lifetimeSpend;

  const Customer({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.defaultAddress,
    required this.createdAt,
    required this.totalOrdersCount,
    required this.lifetimeSpend,
  });

  Customer copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    ShippingAddress? defaultAddress,
    DateTime? createdAt,
    int? totalOrdersCount,
    double? lifetimeSpend,
  }) {
    return Customer(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      createdAt: createdAt ?? this.createdAt,
      totalOrdersCount: totalOrdersCount ?? this.totalOrdersCount,
      lifetimeSpend: lifetimeSpend ?? this.lifetimeSpend,
    );
  }
}
