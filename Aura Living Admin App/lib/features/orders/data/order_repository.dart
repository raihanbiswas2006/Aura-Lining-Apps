import 'dart:async';
import '../domain/order.dart';
import '../domain/order_status.dart';
import '../domain/order_components.dart';

abstract class OrderRepository {
  Future<List<Order>> getOrders({OrderStatus? statusFilter, String? query});
  Future<Order?> getOrderById(String id);
  Future<Order> transitionOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? trackingNumber,
    String? courierPartner,
    String? cancellationReason,
    String? note,
    required String staffIdentifier,
  });
  Stream<List<Order>> watchOrders();
}

class MockOrderRepository implements OrderRepository {
  final _ordersStream = StreamController<List<Order>>.broadcast();
  late List<Order> _orders;

  MockOrderRepository() {
    _seedOrders();
  }

  void _seedOrders() {
    final now = DateTime.now();

    _orders = [
      Order(
        id: 'AL-9842',
        customerId: 'cust-01',
        customerName: 'Raihan Biswas',
        customerEmail: 'raihanbiswas2006@gmail.com',
        customerPhone: '+880 1712-345678',
        shippingAddress: const ShippingAddress(
          recipientName: 'Raihan Biswas',
          streetAddress: 'House 42, Road 11, Block D',
          apartment: 'Apt 4B',
          city: 'Dhaka',
          state: 'Dhaka Division',
          division: 'Dhaka',
          district: 'Dhaka',
          thana: 'Banani',
          postalCode: '1213',
          country: 'Bangladesh',
          phone: '+880 1712-345678',
        ),
        items: const [
          OrderItem(
            productId: 'prod-02',
            productTitle: 'Kanso Ceramic Ribbed Vase',
            unitPrice: 6500.0,
            quantity: 2,
            imageUrl: 'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c?auto=format&fit=crop&w=300&q=80',
          ),
          OrderItem(
            productId: 'prod-06',
            productTitle: 'Cedar & Hinoki Scented Candle',
            unitPrice: 4200.0,
            quantity: 1,
            imageUrl: 'https://images.unsplash.com/photo-1603006905003-be475563bc59?auto=format&fit=crop&w=300&q=80',
          ),
        ],
        subtotal: 17200.0,
        discountAmount: 1720.0,
        couponCode: 'AURA10',
        shippingFee: 0.0, // Free delivery > ৳5,000
        estimatedTax: 0.0,
        totalAmount: 15480.0,
        status: OrderStatus.pending,
        paymentMethod: 'bKash MFS',
        paymentStatus: 'Paid',
        transactionReference: 'BK9284102941',
        customerNote: 'Please ring phone before arrival at Banani.',
        createdAt: now.subtract(const Duration(minutes: 42)),
        statusHistory: [
          StatusLog(
            status: OrderStatus.pending,
            timestamp: now.subtract(const Duration(minutes: 42)),
            staffIdentifier: 'System / Online Storefront',
            note: 'Order placed by customer via Aura Living mobile storefront.',
          ),
        ],
      ),
      Order(
        id: 'AL-9841',
        customerId: 'cust-02',
        customerName: 'Tanvir Hasan',
        customerEmail: 'tanvir.hasan@bdtech.com',
        customerPhone: '+880 1819-223344',
        shippingAddress: const ShippingAddress(
          recipientName: 'Tanvir Hasan',
          streetAddress: '14/A, Road 7',
          apartment: 'Level 3',
          city: 'Dhaka',
          state: 'Dhaka Division',
          division: 'Dhaka',
          district: 'Dhaka',
          thana: 'Dhanmondi',
          postalCode: '1205',
          country: 'Bangladesh',
          phone: '+880 1819-223344',
        ),
        items: const [
          OrderItem(
            productId: 'prod-01',
            productTitle: 'Nordic Minimalist Oak Chair',
            variantId: 'var-01-a',
            variantAttributes: 'Wood Finish: Natural White Oak',
            unitPrice: 28000.0,
            quantity: 2,
            imageUrl: 'https://images.unsplash.com/photo-1592078615290-033ee584e267?auto=format&fit=crop&w=300&q=80',
          ),
        ],
        subtotal: 56000.0,
        discountAmount: 0.0,
        shippingFee: 0.0,
        estimatedTax: 0.0,
        totalAmount: 56000.0,
        status: OrderStatus.confirmed,
        paymentMethod: 'Cash on Delivery (COD)',
        paymentStatus: 'Pending',
        transactionReference: 'COD-DHAN-9841',
        createdAt: now.subtract(const Duration(hours: 2)),
        statusHistory: [
          StatusLog(
            status: OrderStatus.pending,
            timestamp: now.subtract(const Duration(hours: 2)),
            staffIdentifier: 'System / Online Storefront',
            note: 'Order submitted with Cash on Delivery.',
          ),
          StatusLog(
            status: OrderStatus.confirmed,
            timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
            staffIdentifier: 'Raihan Biswas (Super Admin)',
            note: 'Customer phone confirmation verified. Ready for atelier packaging.',
          ),
        ],
      ),
      Order(
        id: 'AL-9839',
        customerId: 'cust-03',
        customerName: 'Nusrat Jahan',
        customerEmail: 'nusrat.j@ctgdesign.com',
        customerPhone: '+880 1911-556677',
        shippingAddress: const ShippingAddress(
          recipientName: 'Nusrat Jahan',
          streetAddress: 'GEC Circle, Nasirabad Road',
          apartment: 'Flat 6A, Shanta Villa',
          city: 'Chattogram',
          state: 'Chattogram Division',
          division: 'Chattogram',
          district: 'Chattogram',
          thana: 'Panchlaish',
          postalCode: '4000',
          country: 'Bangladesh',
          phone: '+880 1911-556677',
        ),
        items: const [
          OrderItem(
            productId: 'prod-04',
            productTitle: 'Linen Slumber Duvet Set',
            variantId: 'var-04-a',
            variantAttributes: 'Size: Queen / Oat White',
            unitPrice: 19500.0,
            quantity: 1,
            imageUrl: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=300&q=80',
          ),
        ],
        subtotal: 19500.0,
        discountAmount: 0.0,
        shippingFee: 0.0,
        estimatedTax: 0.0,
        totalAmount: 19500.0,
        status: OrderStatus.shipped,
        paymentMethod: 'Nagad Digital',
        paymentStatus: 'Paid',
        trackingNumber: 'SF-994182470BD',
        courierPartner: 'Steadfast Courier',
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        statusHistory: [
          StatusLog(
            status: OrderStatus.pending,
            timestamp: now.subtract(const Duration(days: 1, hours: 4)),
            staffIdentifier: 'System / Online Storefront',
          ),
          StatusLog(
            status: OrderStatus.confirmed,
            timestamp: now.subtract(const Duration(days: 1, hours: 2)),
            staffIdentifier: 'Raihan Biswas',
          ),
          StatusLog(
            status: OrderStatus.shipped,
            timestamp: now.subtract(const Duration(hours: 8)),
            staffIdentifier: 'Inventory Dispatch',
            note: 'Dispatched via Steadfast Courier. Consignment ID: SF-994182470BD.',
          ),
        ],
      ),
      Order(
        id: 'AL-9835',
        customerId: 'cust-04',
        customerName: 'Fahim Chowdhury',
        customerEmail: 'fahim.c@sylhethome.bd',
        customerPhone: '+880 1711-998877',
        shippingAddress: const ShippingAddress(
          recipientName: 'Fahim Chowdhury',
          streetAddress: 'Main Road, Zindabazar Point',
          city: 'Sylhet',
          state: 'Sylhet Division',
          division: 'Sylhet',
          district: 'Sylhet',
          thana: 'Kotwali',
          postalCode: '3100',
          country: 'Bangladesh',
          phone: '+880 1711-998877',
        ),
        items: const [
          OrderItem(
            productId: 'prod-07',
            productTitle: 'Solvorn Solid Teak Dining Table',
            unitPrice: 85000.0,
            quantity: 1,
            imageUrl: 'https://images.unsplash.com/photo-1615066390971-03e4e1c36ddf?auto=format&fit=crop&w=300&q=80',
          ),
        ],
        subtotal: 85000.0,
        discountAmount: 5000.0,
        couponCode: 'WELCOME5000',
        shippingFee: 0.0,
        estimatedTax: 0.0,
        totalAmount: 80000.0,
        status: OrderStatus.delivered,
        paymentMethod: 'Card Online',
        paymentStatus: 'Paid',
        trackingNumber: 'PTH-88129931BD',
        courierPartner: 'Pathao Courier',
        createdAt: now.subtract(const Duration(days: 4)),
        statusHistory: [
          StatusLog(
            status: OrderStatus.pending,
            timestamp: now.subtract(const Duration(days: 4)),
            staffIdentifier: 'System',
          ),
          StatusLog(
            status: OrderStatus.shipped,
            timestamp: now.subtract(const Duration(days: 2)),
            staffIdentifier: 'Raihan Biswas',
          ),
          StatusLog(
            status: OrderStatus.delivered,
            timestamp: now.subtract(const Duration(hours: 6)),
            staffIdentifier: 'Pathao Courier Webhook',
            note: 'Delivered and signed at doorstep.',
          ),
        ],
      ),
      Order(
        id: 'AL-9830',
        customerId: 'cust-05',
        customerName: 'Sadia Afrin',
        customerEmail: 'sadia.a@creativebd.com',
        customerPhone: '+880 1612-445566',
        shippingAddress: const ShippingAddress(
          recipientName: 'Sadia Afrin',
          streetAddress: 'Sector 4, Road 7, House 12',
          city: 'Dhaka',
          state: 'Dhaka Division',
          division: 'Dhaka',
          district: 'Dhaka',
          thana: 'Uttara',
          postalCode: '1230',
          country: 'Bangladesh',
          phone: '+880 1612-445566',
        ),
        items: const [
          OrderItem(
            productId: 'prod-05',
            productTitle: 'Muted Brass Arc Pendant Lamp',
            unitPrice: 21000.0,
            quantity: 1,
            imageUrl: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=300&q=80',
          ),
        ],
        subtotal: 21000.0,
        discountAmount: 0.0,
        shippingFee: 0.0,
        estimatedTax: 0.0,
        totalAmount: 21000.0,
        status: OrderStatus.cancelled,
        paymentMethod: 'bKash MFS',
        paymentStatus: 'Refunded',
        cancellationReason: 'Stock Discrepancy',
        createdAt: now.subtract(const Duration(days: 6)),
        statusHistory: [
          StatusLog(
            status: OrderStatus.pending,
            timestamp: now.subtract(const Duration(days: 6)),
            staffIdentifier: 'System',
          ),
          StatusLog(
            status: OrderStatus.cancelled,
            timestamp: now.subtract(const Duration(days: 5, hours: 20)),
            staffIdentifier: 'Astrid Lindgren (Super Admin)',
            note: 'Cancelled due to Stock Discrepancy. Full refund processed.',
          ),
        ],
      ),
    ];
  }

  void _notify() {
    _ordersStream.add(List.unmodifiable(_orders));
  }

  @override
  Stream<List<Order>> watchOrders() {
    return _ordersStream.stream;
  }

  @override
  Future<List<Order>> getOrders({OrderStatus? statusFilter, String? query}) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return _orders.where((o) {
      if (statusFilter != null && o.status != statusFilter) {
        return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchId = o.id.toLowerCase().contains(q);
        final matchCustomer = o.customerName.toLowerCase().contains(q) ||
            o.customerEmail.toLowerCase().contains(q);
        if (!matchId && !matchCustomer) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Order?> getOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      final cleanId = id.replaceAll('#', '');
      return _orders.firstWhere((o) => o.id == cleanId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Order> transitionOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? trackingNumber,
    String? courierPartner,
    String? cancellationReason,
    String? note,
    required String staffIdentifier,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final cleanId = orderId.replaceAll('#', '');
    final index = _orders.indexWhere((o) => o.id == cleanId);
    if (index == -1) throw Exception('Order $orderId not found');

    final currentOrder = _orders[index];

    // Enforce transition rules per PRD Section 6.5
    if (!currentOrder.status.canTransitionTo(newStatus)) {
      throw Exception(
        'Invalid status transition: Cannot move from ${currentOrder.status.label} to ${newStatus.label}.',
      );
    }

    if (newStatus == OrderStatus.shipped &&
        (trackingNumber == null || trackingNumber.trim().isEmpty)) {
      throw Exception('Tracking Reference number is mandatory when marking order as Shipped.');
    }

    if (newStatus == OrderStatus.cancelled &&
        (cancellationReason == null || cancellationReason.trim().isEmpty)) {
      throw Exception('Cancellation reason is required when cancelling an order.');
    }

    final newHistory = List<StatusLog>.from(currentOrder.statusHistory)
      ..add(
        StatusLog(
          status: newStatus,
          timestamp: DateTime.now(),
          staffIdentifier: staffIdentifier,
          note: note ?? (newStatus == OrderStatus.cancelled ? 'Reason: $cancellationReason' : null),
        ),
      );

    final updated = currentOrder.copyWith(
      status: newStatus,
      trackingNumber: trackingNumber ?? currentOrder.trackingNumber,
      courierPartner: courierPartner ?? currentOrder.courierPartner,
      cancellationReason: cancellationReason ?? currentOrder.cancellationReason,
      paymentStatus: newStatus == OrderStatus.cancelled ? 'Refunded' : currentOrder.paymentStatus,
      statusHistory: newHistory,
    );

    _orders[index] = updated;
    _notify();
    return updated;
  }
}
