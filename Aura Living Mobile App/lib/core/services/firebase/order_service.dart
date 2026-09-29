import 'dart:async';
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
  final List<Order> _localOrders;
  final _ordersStream = StreamController<List<Order>>.broadcast();

  FirestoreOrderService({List<Order> initialOrders = const []})
      : _localOrders = List.from(initialOrders) {
    _ordersStream.add(_localOrders);
  }

  String get collectionPath => FirestoreCollections.orders;

  @override
  Future<Order> createOrder(Order order) async {
    // In full Firestore integration:
    // await FirebaseFirestore.instance
    //     .collection(FirestoreCollections.orders)
    //     .doc(order.id)
    //     .set(order.toJson());
    _localOrders.insert(0, order);
    _ordersStream.add(_localOrders);
    return order;
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    try {
      return _localOrders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Order>> getOrdersByUser(String userId) async {
    return _localOrders.where((o) => o.userId == userId).toList();
  }

  @override
  Stream<List<Order>> watchOrdersByUser(String userId) {
    // In full Firestore integration:
    // return FirebaseFirestore.instance
    //     .collection(FirestoreCollections.orders)
    //     .where('userId', isEqualTo: userId)
    //     .orderBy('createdAt', descending: true)
    //     .snapshots()
    //     .map((s) => s.docs.map((d) => Order.fromJson(d.data())).toList());
    return _ordersStream.stream.map((list) => list.where((o) => o.userId == userId).toList());
  }

  @override
  Future<void> updateFulfillmentStatus(String orderId, String newStatus) async {
    final idx = _localOrders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final existing = _localOrders[idx];
      _localOrders[idx] = existing.copyWith(fulfillmentStatus: newStatus);
      _ordersStream.add(_localOrders);
    }
  }
}
