import 'address.dart';
import 'cart_item.dart';

class OrderTimelineEvent {
  final String statusTitle;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;

  const OrderTimelineEvent({
    required this.statusTitle,
    required this.description,
    required this.timestamp,
    required this.isCompleted,
  });

  OrderTimelineEvent copyWith({
    String? statusTitle,
    String? description,
    DateTime? timestamp,
    bool? isCompleted,
  }) {
    return OrderTimelineEvent(
      statusTitle: statusTitle ?? this.statusTitle,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusTitle': statusTitle,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory OrderTimelineEvent.fromJson(Map<String, dynamic> json) {
    return OrderTimelineEvent(
      statusTitle: json['statusTitle'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isCompleted: json['isCompleted'] as bool,
    );
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final List<CartItem> items;
  final Address shippingAddress;
  final String shippingMethod;
  final double subtotal;
  final double discountAmount;
  final double shippingCost;
  final double taxAmount;
  final double totalAmount;
  final String paymentStatus; // "paid" | "pending"
  final String fulfillmentStatus; // "processing" | "shipped" | "delivered" | "cancelled"
  final DateTime createdAt;
  final List<OrderTimelineEvent> timeline;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.shippingMethod,
    required this.subtotal,
    required this.discountAmount,
    required this.shippingCost,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentStatus,
    required this.fulfillmentStatus,
    required this.createdAt,
    required this.timeline,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    String? id,
    String? orderNumber,
    String? userId,
    List<CartItem>? items,
    Address? shippingAddress,
    String? shippingMethod,
    double? subtotal,
    double? discountAmount,
    double? shippingCost,
    double? taxAmount,
    double? totalAmount,
    String? paymentStatus,
    String? fulfillmentStatus,
    DateTime? createdAt,
    List<OrderTimelineEvent>? timeline,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      shippingCost: shippingCost ?? this.shippingCost,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      fulfillmentStatus: fulfillmentStatus ?? this.fulfillmentStatus,
      createdAt: createdAt ?? this.createdAt,
      timeline: timeline ?? this.timeline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'userId': userId,
      'items': items.map((i) => i.toJson()).toList(),
      'shippingAddress': shippingAddress.toJson(),
      'shippingMethod': shippingMethod,
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'shippingCost': shippingCost,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'fulfillmentStatus': fulfillmentStatus,
      'createdAt': createdAt.toIso8601String(),
      'timeline': timeline.map((t) => t.toJson()).toList(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      userId: json['userId'] as String,
      items: (json['items'] as List)
          .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      shippingAddress:
          Address.fromJson(json['shippingAddress'] as Map<String, dynamic>),
      shippingMethod: json['shippingMethod'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num).toDouble(),
      shippingCost: (json['shippingCost'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentStatus: json['paymentStatus'] as String,
      fulfillmentStatus: json['fulfillmentStatus'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      timeline: (json['timeline'] as List)
          .map((t) => OrderTimelineEvent.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
