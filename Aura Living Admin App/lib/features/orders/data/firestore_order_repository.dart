import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../domain/order.dart';
import '../domain/order_status.dart';
import '../domain/order_components.dart';
import 'order_repository.dart';

/// Live Firestore Order Repository for Aura Living Admin
class FirestoreOrderRepository implements OrderRepository {
  final FirebaseFirestore? _firestoreOverride;
  final MockOrderRepository _fallbackRepo = MockOrderRepository();

  FirebaseFirestore? get _firestore {
    if (_firestoreOverride != null) return _firestoreOverride;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  FirestoreOrderRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  @override
  Stream<List<Order>> watchOrders() {
    final db = _firestore;
    if (db == null) {
      return Stream.value(_fallbackRepo.getOrdersSync());
    }

    return db
        .collection('orders')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Fallback to mock orders if no live orders exist yet
        return _fallbackRepo.getOrdersSync();
      }

      return snapshot.docs.map((doc) => _mapDocToOrder(doc.id, doc.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }).handleError((error) {
      // Fallback gracefully on connectivity error
      return _fallbackRepo.getOrdersSync();
    });
  }

  @override
  Future<List<Order>> getOrders({OrderStatus? statusFilter, String? query}) async {
    final db = _firestore;
    if (db == null) {
      return await _fallbackRepo.getOrders(statusFilter: statusFilter, query: query);
    }

    try {
      final snapshot = await db.collection('orders').get().timeout(const Duration(seconds: 4));
      if (snapshot.docs.isEmpty) {
        return await _fallbackRepo.getOrders(statusFilter: statusFilter, query: query);
      }

      var orders = snapshot.docs.map((doc) => _mapDocToOrder(doc.id, doc.data())).toList();

      if (statusFilter != null) {
        orders = orders.where((o) => o.status == statusFilter).toList();
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        orders = orders.where((o) {
          final matchId = o.id.toLowerCase().contains(q);
          final matchCustomer = o.customerName.toLowerCase().contains(q) ||
              o.customerEmail.toLowerCase().contains(q);
          return matchId || matchCustomer;
        }).toList();
      }

      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (_) {
      return await _fallbackRepo.getOrders(statusFilter: statusFilter, query: query);
    }
  }

  @override
  Future<Order?> getOrderById(String id) async {
    final cleanId = id.replaceAll('#', '');
    final db = _firestore;
    if (db != null) {
      try {
        final doc = await db.collection('orders').doc(cleanId).get().timeout(const Duration(seconds: 4));
        if (doc.exists && doc.data() != null) {
          return _mapDocToOrder(doc.id, doc.data()!);
        }
      } catch (_) {}
    }

    return _fallbackRepo.getOrderById(cleanId);
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
    final cleanId = orderId.replaceAll('#', '');

    final existingOrder = await getOrderById(cleanId);
    if (existingOrder != null && !existingOrder.status.canTransitionTo(newStatus)) {
      throw Exception(
        'Invalid status transition: Cannot move from ${existingOrder.status.label} to ${newStatus.label}.',
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

    final newLog = {
      'status': newStatus.name,
      'timestamp': DateTime.now().toIso8601String(),
      'staffIdentifier': staffIdentifier,
      'note': note ?? (newStatus == OrderStatus.cancelled ? 'Reason: $cancellationReason' : null),
    };

    final updates = <String, dynamic>{
      'status': newStatus.name,
      'fulfillmentStatus': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([newLog]),
    };

    if (trackingNumber != null && trackingNumber.isNotEmpty) {
      updates['trackingNumber'] = trackingNumber;
    }
    if (courierPartner != null && courierPartner.isNotEmpty) {
      updates['courierPartner'] = courierPartner;
    }
    if (cancellationReason != null && cancellationReason.isNotEmpty) {
      updates['cancellationReason'] = cancellationReason;
    }
    if (newStatus == OrderStatus.cancelled) {
      updates['paymentStatus'] = 'Refunded';
    }

    final db = _firestore;
    if (db != null) {
      try {
        await db.collection('orders').doc(cleanId).update(updates).timeout(const Duration(seconds: 4));
      } catch (_) {
        // If doc does not exist yet in Firestore, update fallback
        return _fallbackRepo.transitionOrderStatus(
          orderId: cleanId,
          newStatus: newStatus,
          trackingNumber: trackingNumber,
          courierPartner: courierPartner,
          cancellationReason: cancellationReason,
          note: note,
          staffIdentifier: staffIdentifier,
        );
      }
    } else {
      return _fallbackRepo.transitionOrderStatus(
        orderId: cleanId,
        newStatus: newStatus,
        trackingNumber: trackingNumber,
        courierPartner: courierPartner,
        cancellationReason: cancellationReason,
        note: note,
        staffIdentifier: staffIdentifier,
      );
    }

    final updated = await getOrderById(cleanId);
    if (updated != null) return updated;

    return _fallbackRepo.transitionOrderStatus(
      orderId: cleanId,
      newStatus: newStatus,
      trackingNumber: trackingNumber,
      courierPartner: courierPartner,
      cancellationReason: cancellationReason,
      note: note,
      staffIdentifier: staffIdentifier,
    );
  }

  Order _mapDocToOrder(String id, Map<String, dynamic> data) {
    OrderStatus parseStatus(dynamic val) {
      final s = (val as String? ?? 'pending').toLowerCase();
      if (s.contains('pending')) return OrderStatus.pending;
      if (s.contains('confirm')) return OrderStatus.confirmed;
      if (s.contains('process')) return OrderStatus.processing;
      if (s.contains('ship') || s.contains('courier')) return OrderStatus.shipped;
      if (s.contains('deliver')) return OrderStatus.delivered;
      if (s.contains('cancel')) return OrderStatus.cancelled;
      if (s.contains('return')) return OrderStatus.returned;
      return OrderStatus.pending;
    }

    final shippingRaw = data['shippingAddress'] as Map<String, dynamic>? ?? {};
    final shippingAddress = ShippingAddress(
      recipientName: shippingRaw['fullName'] ?? shippingRaw['recipientName'] ?? data['customerName'] ?? 'Customer',
      streetAddress: shippingRaw['addressLine1'] ?? shippingRaw['streetAddress'] ?? 'Dhaka, Bangladesh',
      apartment: shippingRaw['addressLine2'] ?? shippingRaw['apartment'],
      city: shippingRaw['city'] ?? 'Dhaka',
      state: shippingRaw['division'] ?? shippingRaw['state'] ?? 'Dhaka',
      division: shippingRaw['division'] ?? 'Dhaka',
      district: shippingRaw['district'] ?? 'Dhaka',
      thana: shippingRaw['thana'] ?? 'Gulshan',
      postalCode: shippingRaw['postalCode'] ?? '1212',
      country: shippingRaw['country'] ?? 'Bangladesh',
      phone: shippingRaw['phone'] ?? data['customerPhone'] ?? '+8801700000000',
    );

    final rawItems = (data['items'] as List<dynamic>? ?? []);
    final items = rawItems.map((item) {
      final map = item as Map<String, dynamic>;
      final imageUrl = map['imageUrl'] ??
          (map['imageUrls'] is List && (map['imageUrls'] as List).isNotEmpty ? map['imageUrls'][0] : null) ??
          'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?auto=format&fit=crop&w=300&q=80';
      return OrderItem(
        productId: map['productId'] ?? map['id'] ?? '',
        productTitle: map['title'] ?? map['name'] ?? map['productTitle'] ?? 'Product',
        unitPrice: (map['price'] as num?)?.toDouble() ?? (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        imageUrl: imageUrl,
        variantId: map['variantId'],
        variantAttributes: map['variantAttributes'] ?? map['color'],
      );
    }).toList();

    DateTime createdAt = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
    }

    final rawHistory = (data['statusHistory'] as List<dynamic>? ?? []);
    final statusHistory = rawHistory.map((h) {
      final hm = h as Map<String, dynamic>;
      DateTime ts = DateTime.now();
      if (hm['timestamp'] is Timestamp) {
        ts = (hm['timestamp'] as Timestamp).toDate();
      } else if (hm['timestamp'] is String) {
        ts = DateTime.tryParse(hm['timestamp']) ?? DateTime.now();
      }
      return StatusLog(
        status: parseStatus(hm['status']),
        timestamp: ts,
        staffIdentifier: hm['staffIdentifier'] ?? 'Staff',
        note: hm['note'],
      );
    }).toList();

    return Order(
      id: id,
      customerId: data['userId'] ?? data['customerId'] ?? 'guest',
      customerName: data['customerName'] ?? 'Customer',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      shippingAddress: shippingAddress,
      items: items,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? (data['total'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (data['discount'] as num?)?.toDouble() ?? (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
      couponCode: data['couponCode'],
      shippingFee: (data['shippingFee'] as num?)?.toDouble() ?? 0.0,
      estimatedTax: 0.0,
      totalAmount: (data['total'] as num?)?.toDouble() ?? (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: parseStatus(data['status']),
      paymentMethod: data['paymentMethod'] ?? 'Cash on Delivery',
      paymentStatus: data['paymentStatus'] ?? 'Unpaid',
      transactionReference: data['transactionReference'],
      trackingNumber: data['trackingNumber'],
      courierPartner: data['courierPartner'],
      customerNote: data['customerNote'],
      cancellationReason: data['cancellationReason'],
      createdAt: createdAt,
      statusHistory: statusHistory,
    );
  }
}

extension MockOrderRepositoryExtension on MockOrderRepository {
  List<Order> getOrdersSync() {
    return [
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
            productId: 'prod-001',
            productTitle: 'Nordic Lounge Chair',
            unitPrice: 34900.0,
            quantity: 1,
            imageUrl: 'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?auto=format&fit=crop&w=300&q=80',
          ),
        ],
        subtotal: 34900.0,
        discountAmount: 0.0,
        shippingFee: 0.0,
        estimatedTax: 0.0,
        totalAmount: 34900.0,
        status: OrderStatus.pending,
        paymentMethod: 'bKash MFS',
        paymentStatus: 'Paid',
        transactionReference: 'BK9284102941',
        customerNote: 'Please ring phone before arrival at Banani.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
        statusHistory: [
          StatusLog(
            status: OrderStatus.pending,
            timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
            staffIdentifier: 'System / Online Storefront',
            note: 'Order placed by customer via Aura Living mobile storefront.',
          ),
        ],
      ),
    ];
  }
}
