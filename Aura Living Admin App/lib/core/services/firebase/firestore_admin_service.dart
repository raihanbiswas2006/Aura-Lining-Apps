import 'dart:async';
import 'firestore_collections.dart';
import '../../../features/products/domain/product.dart';
import '../../../features/orders/domain/order.dart';
import '../../../features/orders/domain/order_status.dart';

/// Abstraction layer for Firestore Admin operations (Products, Orders, Inventory)
/// Designed to drop in `cloud_firestore` when backend connectivity is initialized.
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

/// Mock implementation of [IFirestoreAdminService]
/// Conforms to Firestore collections schema:
/// - `products`: /products/{productId}
/// - `orders`: /orders/{orderId}
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
    // Simulates Firestore batch write:
    // await FirebaseFirestore.instance.collection(FirestoreCollections.orders).doc(orderId).update(...)
    assert(FirestoreCollections.orders.isNotEmpty);
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> updateProductStock({
    required String productId,
    required int newQuantity,
    String? variantId,
  }) async {
    // Simulates Firestore field update:
    // await FirebaseFirestore.instance.collection(FirestoreCollections.products).doc(productId).update(...)
    assert(FirestoreCollections.products.isNotEmpty);
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> saveProduct(Product product) async {
    // await FirebaseFirestore.instance.collection(FirestoreCollections.products).doc(product.id).set(product.toMap(), SetOptions(merge: true))
    assert(FirestoreCollections.products.isNotEmpty);
    await Future.delayed(const Duration(milliseconds: 250));
  }

  @override
  Future<void> deleteProduct(String productId) async {
    // await FirebaseFirestore.instance.collection(FirestoreCollections.products).doc(productId).delete()
    assert(FirestoreCollections.products.isNotEmpty);
    await Future.delayed(const Duration(milliseconds: 200));
  }

  void dispose() {
    _orderController.close();
  }
}
