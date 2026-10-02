import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../domain/entities/order.dart';
import '../../domain/repositories/i_order_repository.dart';
import '../datasources/local_storage_service.dart';
import '../datasources/mock/mock_orders.dart';

class FirebaseOrderRepository implements IOrderRepository {
  final FirebaseFirestore? _firestoreOverride;
  final LocalStorageService _storage;
  List<Order> _localOrders = [];

  FirebaseFirestore? get _firestore {
    if (_firestoreOverride != null) return _firestoreOverride;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  FirebaseOrderRepository({
    FirebaseFirestore? firestore,
    required LocalStorageService storage,
  })  : _firestoreOverride = firestore,
        _storage = storage {
    _initLocal();
  }

  void _initLocal() {
    final rawList = _storage.getOrdersRaw();
    if (rawList.isNotEmpty) {
      _localOrders = rawList.map((m) => Order.fromJson(m)).toList();
    } else {
      _localOrders = List<Order>.from(mockInitialOrders);
      _storage.saveOrdersRaw(_localOrders.map((o) => o.toJson()).toList());
    }
  }

  @override
  Future<List<Order>> getOrders({String? userId, String? fulfillmentStatus}) async {
    final db = _firestore;
    if (db != null) {
      try {
        Query<Map<String, dynamic>> query = db.collection('orders');
        if (userId != null && userId.isNotEmpty) {
          query = query.where('userId', isEqualTo: userId);
        }
        if (fulfillmentStatus != null &&
            fulfillmentStatus.isNotEmpty &&
            fulfillmentStatus != 'all') {
          query = query.where('fulfillmentStatus', isEqualTo: fulfillmentStatus);
        }

        final snapshot = await query.get().timeout(const Duration(seconds: 4));
        if (snapshot.docs.isNotEmpty) {
          final remoteOrders = snapshot.docs.map((doc) => Order.fromJson(doc.data())).toList();
          remoteOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _localOrders = remoteOrders;
          await _storage.saveOrdersRaw(remoteOrders.map((o) => o.toJson()).toList());
          return remoteOrders;
        }
      } catch (_) {
        // Fallback to local storage if offline or during setup
      }
    }

    var result = List<Order>.from(_localOrders);
    if (userId != null && userId.isNotEmpty) {
      result = result.where((o) => o.userId == userId).toList();
    }
    if (fulfillmentStatus != null &&
        fulfillmentStatus.isNotEmpty &&
        fulfillmentStatus != 'all') {
      result = result.where((o) => o.fulfillmentStatus == fulfillmentStatus).toList();
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    final db = _firestore;
    if (db != null) {
      try {
        final doc = await db.collection('orders').doc(orderId).get().timeout(const Duration(seconds: 4));
        if (doc.exists && doc.data() != null) {
          return Order.fromJson(doc.data()!);
        }
      } catch (_) {}
    }

    try {
      return _localOrders.firstWhere((o) => o.id == orderId || o.orderNumber == orderId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Order> createOrder(Order order) async {
    _localOrders.insert(0, order);
    await _storage.saveOrdersRaw(_localOrders.map((o) => o.toJson()).toList());

    final db = _firestore;
    if (db != null) {
      try {
        await db.collection('orders').doc(order.id).set(order.toJson()).timeout(const Duration(seconds: 4));
      } catch (_) {
        // Order is safely cached locally; will sync upon network connection
      }
    }

    return order;
  }
}
