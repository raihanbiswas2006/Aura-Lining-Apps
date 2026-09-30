import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'firestore_collections.dart';
import '../../../features/products/domain/product.dart';
import '../../../features/orders/domain/order.dart';
import '../../../features/orders/domain/order_status.dart';
import '../../../features/orders/domain/order_components.dart';

/// Abstraction layer for Firestore Admin operations (Products, Orders, Inventory)
abstract class IFirestoreAdminService {
  /// Stream of active orders from Firestore
  Stream<List<Order>> watchOrdersStream();

  /// Updates an order's status and courier tracking info
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    String? courierPartner,
    String? trackingNumber,
    String? adminNotes,
  });

  /// Quick stock update in Firestore
  Future<void> updateProductStock({
    required String productId,
    required int newQuantity,
    String? variantId,
  });

  /// Upsert product document to Firestore
  Future<void> saveProduct(Product product);

  /// Soft or hard delete product
  Future<void> deleteProduct(String productId);
}

/// Production implementation of [IFirestoreAdminService] connected to Cloud Firestore
class FirestoreAdminService implements IFirestoreAdminService {
  final FirebaseFirestore _firestore;

  FirestoreAdminService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Order>> watchOrdersStream() {
    return _firestore.collection(FirestoreCollections.orders).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return <Order>[];

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _mapFirestoreDocToOrder(doc.id, data);
      }).toList();
    });
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    String? courierPartner,
    String? trackingNumber,
    String? adminNotes,
  }) async {
    final statusMap = {
      'status': status.name,
      'statusLabel': status.label,
      'timestamp': FieldValue.serverTimestamp(),
      'staffIdentifier': 'Admin Operations',
      'note': adminNotes,
    };

    final updates = <String, dynamic>{
      'status': status.name,
      'fulfillmentStatus': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([statusMap]),
    };

    if (courierPartner != null && courierPartner.isNotEmpty) {
      updates['courierPartner'] = courierPartner;
    }
    if (trackingNumber != null && trackingNumber.isNotEmpty) {
      updates['trackingNumber'] = trackingNumber;
    }
    if (adminNotes != null && adminNotes.isNotEmpty) {
      updates['adminNotes'] = adminNotes;
    }

    await _firestore.collection(FirestoreCollections.orders).doc(orderId).update(updates);
  }

  @override
  Future<void> updateProductStock({
    required String productId,
    required int newQuantity,
    String? variantId,
  }) async {
    await _firestore.collection(FirestoreCollections.products).doc(productId).update({
      'stock': newQuantity,
      'stockQuantity': newQuantity,
      'totalStock': newQuantity,
      'inStock': newQuantity > 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> saveProduct(Product product) async {
    final data = <String, dynamic>{
      'id': product.id,
      'title': product.title,
      'name': product.title,
      'slug': product.slug,
      'categoryId': product.categoryId,
      'description': product.description,
      'shortDescription': product.shortDescription,
      'price': product.basePrice,
      'basePrice': product.basePrice,
      'discountPercentage': product.discountPercentage,
      'imageUrls': product.imageUrls,
      'images': product.imageUrls,
      'hasVariants': product.hasVariants,
      'variants': product.variants.map((v) => {
        'id': v.id,
        'sku': v.sku,
        'attributeName': v.attributeName,
        'attributeValue': v.attributeValue,
        'priceOverride': v.priceOverride,
        'stockQuantity': v.stockQuantity,
      }).toList(),
      'stockQuantity': product.stockQuantity,
      'stock': product.totalStock,
      'totalStock': product.totalStock,
      'inStock': product.totalStock > 0,
      'status': product.status,
      'isFeatured': product.isFeatured,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection(FirestoreCollections.products)
        .doc(product.id)
        .set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection(FirestoreCollections.products).doc(productId).delete();
  }

  Order _mapFirestoreDocToOrder(String id, Map<String, dynamic> data) {
    // Helper to parse status safely
    OrderStatus parseStatus(dynamic val) {
      final s = (val as String? ?? 'pending').toLowerCase();
      if (s.contains('pending')) return OrderStatus.pending;
      if (s.contains('confirm')) return OrderStatus.confirmed;
      if (s.contains('process')) return OrderStatus.processing;
      if (s.contains('ship') || s.contains('courier')) return OrderStatus.shipped;
      if (s.contains('deliver')) return OrderStatus.delivered;
      if (s.contains('cancel')) return OrderStatus.cancelled;
      if (s.contains('return')) return OrderStatus.returned;
      return OrderStatus.pending;
    }

    final shippingRaw = data['shippingAddress'] as Map<String, dynamic>? ?? {};
    final shippingAddress = ShippingAddress(
      recipientName: shippingRaw['fullName'] ?? shippingRaw['recipientName'] ?? data['customerName'] ?? 'Customer',
      streetAddress: shippingRaw['addressLine1'] ?? shippingRaw['streetAddress'] ?? '',
      apartment: shippingRaw['addressLine2'] ?? shippingRaw['apartment'],
      city: shippingRaw['city'] ?? 'Dhaka',
      state: shippingRaw['division'] ?? shippingRaw['state'] ?? 'Dhaka',
      division: shippingRaw['division'] ?? 'Dhaka',
      district: shippingRaw['district'] ?? 'Dhaka',
      thana: shippingRaw['thana'] ?? '',
      postalCode: shippingRaw['postalCode'] ?? '',
      country: shippingRaw['country'] ?? 'Bangladesh',
      phone: shippingRaw['phone'] ?? data['customerPhone'] ?? '',
    );

    final rawItems = (data['items'] as List<dynamic>? ?? []);
    final items = rawItems.map((item) {
      final map = item as Map<String, dynamic>;
      final imageUrl = map['imageUrl'] ??
          (map['imageUrls'] is List && (map['imageUrls'] as List).isNotEmpty ? map['imageUrls'][0] : null) ??
          'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?auto=format&fit=crop&w=300&q=80';
      return OrderItem(
        productId: map['productId'] ?? map['id'] ?? '',
        productTitle: map['title'] ?? map['name'] ?? map['productTitle'] ?? 'Product',
        unitPrice: (map['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        imageUrl: imageUrl,
        variantId: map['variantId'],
        variantAttributes: map['variantAttributes'] ?? map['color'] ?? map['sku'],
      );
    }).toList();

    DateTime createdAt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    }

    final rawHistory = (data['statusHistory'] as List<dynamic>? ?? []);
    final statusHistory = rawHistory.map((h) {
      final hm = h as Map<String, dynamic>;
      DateTime ts = DateTime.now();
      if (hm['timestamp'] is Timestamp) {
        ts = (hm['timestamp'] as Timestamp).toDate();
      } else if (hm['timestamp'] is String) {
        ts = DateTime.tryParse(hm['timestamp']) ?? DateTime.now();
      }
      return StatusLog(
        status: parseStatus(hm['status']),
        timestamp: ts,
        staffIdentifier: hm['staffIdentifier'] ?? 'Staff',
        note: hm['note'],
      );
    }).toList();

    return Order(
      id: id,
      customerId: data['userId'] ?? data['customerId'] ?? 'guest',
      customerName: data['customerName'] ?? 'Customer',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      shippingAddress: shippingAddress,
      items: items,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? (data['total'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (data['discount'] as num?)?.toDouble() ?? (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
      couponCode: data['couponCode'],
      shippingFee: (data['shippingFee'] as num?)?.toDouble() ?? 0.0,
      estimatedTax: 0.0,
      totalAmount: (data['total'] as num?)?.toDouble() ?? (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: parseStatus(data['status']),
      paymentMethod: data['paymentMethod'] ?? 'Cash on Delivery',
      paymentStatus: data['paymentStatus'] ?? 'Unpaid',
      transactionReference: data['transactionReference'],
      trackingNumber: data['trackingNumber'],
      courierPartner: data['courierPartner'],
      customerNote: data['customerNote'],
      cancellationReason: data['cancellationReason'],
      createdAt: createdAt,
      statusHistory: statusHistory,
    );
  }
}

/// Mock implementation retained for offline fallback and preview testing
class MockFirestoreAdminService implements IFirestoreAdminService {
  final _orderController = StreamController<List<Order>>.broadcast();

  @override
  Stream<List<Order>> watchOrdersStream() {
    return _orderController.stream;
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    String? courierPartner,
    String? trackingNumber,
    String? adminNotes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> updateProductStock({
    required String productId,
    required int newQuantity,
    String? variantId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> saveProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 250));
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  void dispose() {
    _orderController.close();
  }
}
