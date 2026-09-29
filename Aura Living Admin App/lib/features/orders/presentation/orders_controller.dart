import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/order.dart';
import '../domain/order_status.dart';
import '../../../core/providers/repository_providers.dart';

class OrderFilterState {
  final OrderStatus? statusFilter;
  final String searchQuery;

  const OrderFilterState({
    this.statusFilter,
    this.searchQuery = '',
  });

  OrderFilterState copyWith({
    OrderStatus? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
  }) {
    return OrderFilterState(
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final orderFilterProvider = StateProvider<OrderFilterState>((ref) {
  return const OrderFilterState();
});

final ordersStreamProvider = StreamProvider<List<Order>>((ref) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  return orderRepo.watchOrders();
});

final filteredOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  final filter = ref.watch(orderFilterProvider);

  return ordersAsync.whenData((orders) {
    return orders.where((order) {
      if (filter.statusFilter != null && order.status != filter.statusFilter) {
        return false;
      }
      if (filter.searchQuery.trim().isNotEmpty) {
        final q = filter.searchQuery.trim().toLowerCase();
        final matchId = order.id.toLowerCase().contains(q);
        final matchCustomer = order.customerName.toLowerCase().contains(q) ||
            order.customerEmail.toLowerCase().contains(q);
        final matchCity = order.shippingAddress.city.toLowerCase().contains(q);
        if (!matchId && !matchCustomer && !matchCity) return false;
      }
      return true;
    }).toList();
  });
});

final orderDetailProvider = FutureProvider.family<Order?, String>((ref, orderId) async {
  final orderRepo = ref.watch(orderRepositoryProvider);
  return orderRepo.getOrderById(orderId);
});
