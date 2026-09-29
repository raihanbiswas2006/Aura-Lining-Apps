import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/customer.dart';
import '../../orders/domain/order.dart';
import '../../../core/providers/repository_providers.dart';

final customerSearchQueryProvider = StateProvider<String>((ref) => '');

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final query = ref.watch(customerSearchQueryProvider);
  return repo.getCustomers(query: query);
});

final customerDetailProvider = FutureProvider.family<Customer?, String>((ref, id) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomerById(id);
});

final customerOrdersProvider = FutureProvider.family<List<Order>, String>((ref, customerId) async {
  final orderRepo = ref.watch(orderRepositoryProvider);
  final allOrders = await orderRepo.getOrders();
  return allOrders.where((o) => o.customerId == customerId).toList();
});
