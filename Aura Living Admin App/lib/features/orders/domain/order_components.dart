import 'order_status.dart';

/// Shipping Address Model localized for Bangladesh Delivery
class ShippingAddress {
  final String recipientName;
  final String streetAddress;
  final String? apartment;
  final String city;
  final String state;
  final String division;
  final String district;
  final String thana;
  final String postalCode;
  final String country;
  final String phone;

  const ShippingAddress({
    required this.recipientName,
    required this.streetAddress,
    this.apartment,
    required this.city,
    required this.state,
    this.division = 'Dhaka',
    this.district = 'Dhaka',
    this.thana = 'Gulshan',
    required this.postalCode,
    this.country = 'Bangladesh',
    this.phone = '+8801700000000',
  });

  String get formattedAddress {
    final apt = apartment != null && apartment!.isNotEmpty ? ', $apartment' : '';
    final loc = thana.isNotEmpty ? '$thana, ' : '';
    final dist = district.isNotEmpty ? '$district, ' : '';
    return '$streetAddress$apt, $loc$dist$division $postalCode, $country';
  }

  String get fullFormatted => formattedAddress;

  String get area => district.isNotEmpty ? '$district, $division' : '$city, $state';
}

/// Order Item Model per PRD Section 8
class OrderItem {
  final String productId;
  final String productTitle;
  final String? variantId;
  final String? variantAttributes; // e.g. "Color: Nordic Oak"
  final double unitPrice;
  final int quantity;
  final String imageUrl;

  const OrderItem({
    required this.productId,
    required this.productTitle,
    this.variantId,
    this.variantAttributes,
    required this.unitPrice,
    required this.quantity,
    required this.imageUrl,
  });

  double get subtotal => unitPrice * quantity;
}

/// Status Transition Audit Log per PRD Section 6.5 & 8
class StatusLog {
  final OrderStatus status;
  final DateTime timestamp;
  final String staffIdentifier;
  final String? note;

  const StatusLog({
    required this.status,
    required this.timestamp,
    required this.staffIdentifier,
    this.note,
  });
}
