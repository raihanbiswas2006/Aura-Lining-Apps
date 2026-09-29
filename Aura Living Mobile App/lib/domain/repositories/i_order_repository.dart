import '../entities/order.dart';

abstract class IOrderRepository {
  Future<List<Order>> getOrders({String? userId, String? fulfillmentStatus});
  Future<Order?> getOrderById(String orderId);
  Future<Order> createOrder(Order order);
}
