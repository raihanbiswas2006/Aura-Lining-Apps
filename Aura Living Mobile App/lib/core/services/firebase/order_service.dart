import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../../domain/entities/order.dart';
import 'firestore_collections.dart';

/// Contract for Order Service (Firestore Real-time Streams ready)
abstract class OrderService {
  Future<Order> createOrder(Order order);
  Future<Order?> getOrderById(String orderId);
  Future<List<Order>> getOrdersByUser(String userId);
  Stream<List<Order>> watchOrdersByUser(String userId);
  Future<void> updateFulfillmentStatus(String orderId, String newStatus);
}

/// Firestore Order Service Implementation
class FirestoreOrderService implements OrderService {
  final FirebaseFirestore _firestore;
  final List<Order> _localOrders;
  final _ordersStream = StreamController<List<Order>>.broadcast();

  FirestoreOrderService({
    FirebaseFirestore? firestore,
    List<Order> initialOrders = const [],
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localOrders = List.from(initialOrders) {
    _ordersStream.add(_localOrders);
  }

  String get collectionPath => FirestoreCollections.orders;

  @override
  Future<Order> createOrder(Order order) async {
    _localOrders.insert(0, order);
    _ordersStream.add(_localOrders);

    try {
      await _firestore
          .collection(FirestoreCollections.orders)
          .doc(order.id)
          .set(order.toJson());
    } catch (_) {}

    return order;
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection(FirestoreCollections.orders).doc(orderId).get();
      if (doc.exists && doc.data() != null) {
        return Order.fromJson(doc.data()!);
      }
    } catch (_) {}

    try {
      return _localOrders.firstWhere((o) => o.id == orderId || o.orderNumber == orderId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Order>> getOrdersByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.orders)
          .where('userId', isEqualTo: userId)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((d) => Order.fromJson(d.data())).toList();
      }
    } catch (_) {}

    return _localOrders.where((o) => o.userId == userId).toList();
  }

  @override
  Stream<List<Order>> watchOrdersByUser(String userId) {
    try {
      return _firestore
          .collection(FirestoreCollections.orders)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs.map((d) => Order.fromJson(d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        }
        return _localOrders.where((o) => o.userId == userId).toList();
      });
    } catch (_) {
      return _ordersStream.stream.map((list) => list.where((o) => o.userId == userId).toList());
    }
  }

  @override
  Future<void> updateFulfillmentStatus(String orderId, String newStatus) async {
    final idx = _localOrders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final existing = _localOrders[idx];
      _localOrders[idx] = existing.copyWith(fulfillmentStatus: newStatus);
      _ordersStream.add(_localOrders);
    }

    try {
      await _firestore.collection(FirestoreCollections.orders).doc(orderId).update({
        'fulfillmentStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
