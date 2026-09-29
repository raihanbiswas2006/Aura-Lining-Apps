import 'order_status.dart';
import 'order_components.dart';

/// Core Order Entity per PRD Section 6.5 & Section 8
class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final ShippingAddress shippingAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double discountAmount;
  final String? couponCode;
  final double shippingFee;
  final double estimatedTax;
  final double totalAmount;
  final OrderStatus status;
  final String paymentMethod; // e.g. 'Card Online', 'Cash on Delivery'
  final String paymentStatus; // 'Paid', 'Pending', 'Refunded'
  final String? transactionReference;
  final String? trackingNumber;
  final String? courierPartner;
  final String? customerNote;
  final String? cancellationReason;
  final DateTime createdAt;
  final List<StatusLog> statusHistory;

  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.shippingAddress,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.couponCode,
    this.shippingFee = 0.0,
    this.estimatedTax = 0.0,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    this.transactionReference,
    this.trackingNumber,
    this.courierPartner,
    this.customerNote,
    this.cancellationReason,
    required this.createdAt,
    required this.statusHistory,
  });

  /// Short summary of items e.g., "2x Ceramic Vase, 1x Linen Throw"
  String get itemsSummary {
    if (items.isEmpty) return 'No items';
    return items.map((e) => '${e.quantity}x ${e.productTitle}').join(', ');
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    ShippingAddress? shippingAddress,
    List<OrderItem>? items,
    double? subtotal,
    double? discountAmount,
    String? couponCode,
    double? shippingFee,
    double? estimatedTax,
    double? totalAmount,
    OrderStatus? status,
    String? paymentMethod,
    String? paymentStatus,
    String? transactionReference,
    String? trackingNumber,
    String? courierPartner,
    String? customerNote,
    String? cancellationReason,
    DateTime? createdAt,
    List<StatusLog>? statusHistory,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      couponCode: couponCode ?? this.couponCode,
      shippingFee: shippingFee ?? this.shippingFee,
      estimatedTax: estimatedTax ?? this.estimatedTax,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transactionReference: transactionReference ?? this.transactionReference,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      courierPartner: courierPartner ?? this.courierPartner,
      customerNote: customerNote ?? this.customerNote,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }
}
