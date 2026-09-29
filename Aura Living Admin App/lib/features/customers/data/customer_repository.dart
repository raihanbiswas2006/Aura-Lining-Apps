import 'dart:async';
import '../domain/customer.dart';
import '../../orders/domain/order_components.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getCustomers({String? query});
  Future<Customer?> getCustomerById(String id);
}

class MockCustomerRepository implements CustomerRepository {
  late List<Customer> _customers;

  MockCustomerRepository() {
    _seedCustomers();
  }

  void _seedCustomers() {
    final now = DateTime.now();

    _customers = [
      Customer(
        id: 'cust-01',
        fullName: 'Raihan Biswas',
        email: 'raihanbiswas2006@gmail.com',
        phone: '+880 1712-345678',
        defaultAddress: const ShippingAddress(
          recipientName: 'Raihan Biswas',
          streetAddress: 'House 42, Road 11',
          apartment: 'Suite 4B',
          division: 'Dhaka',
          district: 'Dhaka',
          thana: 'Banani',
          city: 'Dhaka',
          state: 'Dhaka',
          postalCode: '1213',
          country: 'Bangladesh',
          phone: '+880 1712-345678',
        ),
        createdAt: now.subtract(const Duration(days: 120)),
        totalOrdersCount: 4,
        lifetimeSpend: 84500.0,
      ),
      Customer(
        id: 'cust-02',
        fullName: 'Sadia Rahman',
        email: 'sadia.rahman@example.com',
        phone: '+880 1819-987654',
        defaultAddress: const ShippingAddress(
          recipientName: 'Sadia Rahman',
          streetAddress: 'Plot 15, Sector 4',
          division: 'Dhaka',
          district: 'Dhaka',
          thana: 'Uttara',
          city: 'Dhaka',
          state: 'Dhaka',
          postalCode: '1230',
          country: 'Bangladesh',
          phone: '+880 1819-987654',
        ),
        createdAt: now.subtract(const Duration(days: 210)),
        totalOrdersCount: 6,
        lifetimeSpend: 142000.0,
      ),
      Customer(
        id: 'cust-03',
        fullName: 'Tanvir Hossain',
        email: 'tanvir.h@creative.bd',
        phone: '+880 1911-223344',
        defaultAddress: const ShippingAddress(
          recipientName: 'Tanvir Hossain',
          streetAddress: 'Holding 88, GEC Circle',
          apartment: 'Flat 5A',
          division: 'Chattogram',
          district: 'Chattogram',
          thana: 'Panchlaish',
          city: 'Chattogram',
          state: 'Chattogram',
          postalCode: '4000',
          country: 'Bangladesh',
          phone: '+880 1911-223344',
        ),
        createdAt: now.subtract(const Duration(days: 90)),
        totalOrdersCount: 2,
        lifetimeSpend: 39500.0,
      ),
      Customer(
        id: 'cust-04',
        fullName: 'Nusrat Jahan',
        email: 'nusrat.jahan@designstudio.bd',
        phone: '+880 1622-334455',
        defaultAddress: const ShippingAddress(
          recipientName: 'Nusrat Jahan',
          streetAddress: 'House 7, Road 27',
          division: 'Dhaka',
          district: 'Dhaka',
          thana: 'Dhanmondi',
          city: 'Dhaka',
          state: 'Dhaka',
          postalCode: '1209',
          country: 'Bangladesh',
          phone: '+880 1622-334455',
        ),
        createdAt: now.subtract(const Duration(days: 340)),
        totalOrdersCount: 8,
        lifetimeSpend: 248900.0,
      ),
      Customer(
        id: 'cust-05',
        fullName: 'Farhan Ahmed',
        email: 'farhan.ahmed@techhub.bd',
        phone: '+880 1533-445566',
        defaultAddress: const ShippingAddress(
          recipientName: 'Farhan Ahmed',
          streetAddress: '24 Zindabazar Main Road',
          division: 'Sylhet',
          district: 'Sylhet',
          thana: 'Sylhet Sadar',
          city: 'Sylhet',
          state: 'Sylhet',
          postalCode: '3100',
          country: 'Bangladesh',
          phone: '+880 1533-445566',
        ),
        createdAt: now.subtract(const Duration(days: 45)),
        totalOrdersCount: 1,
        lifetimeSpend: 21000.0,
      ),
    ];
  }

  @override
  Future<List<Customer>> getCustomers({String? query}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (query == null || query.trim().isEmpty) return List.unmodifiable(_customers);

    final q = query.trim().toLowerCase();
    return _customers.where((c) {
      return c.fullName.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.phone.contains(q);
    }).toList();
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
