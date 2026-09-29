import '../../domain/entities/order.dart';
import '../../domain/repositories/i_order_repository.dart';
import '../datasources/local_storage_service.dart';
import '../datasources/mock/mock_orders.dart';

class MockOrderRepository implements IOrderRepository {
  final LocalStorageService _storage;
  List<Order> _orders = [];

  MockOrderRepository(this._storage) {
    _loadOrders();
  }

  void _loadOrders() {
    final rawList = _storage.getOrdersRaw();
    if (rawList.isNotEmpty) {
      _orders = rawList.map((m) => Order.fromJson(m)).toList();
    } else {
      _orders = List.from(mockInitialOrders);
      _storage.saveOrdersRaw(_orders.map((o) => o.toJson()).toList());
    }
  }

  @override
  Future<List<Order>> getOrders({String? userId, String? fulfillmentStatus}) async {
    await Future.delayed(const Duration(milliseconds: 60));
    var result = List<Order>.from(_orders);
    if (userId != null && userId.isNotEmpty) {
      result = result.where((o) => o.userId == userId).toList();
    }
    if (fulfillmentStatus != null &&
        fulfillmentStatus.isNotEmpty &&
        fulfillmentStatus != 'all') {
      result = result.where((o) => o.fulfillmentStatus == fulfillmentStatus).toList();
    }
    // Sort latest first
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 30));
    try {
      return _orders.firstWhere((o) => o.id == orderId || o.orderNumber == orderId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Order> createOrder(Order order) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _orders.insert(0, order);
    await _storage.saveOrdersRaw(_orders.map((o) => o.toJson()).toList());
    return order;
  }
}
