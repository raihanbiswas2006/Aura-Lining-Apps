import '../../../domain/entities/address.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/entities/order.dart';
import 'mock_products.dart';

final List<Order> mockInitialOrders = [
  Order(
    id: 'ord-89241',
    orderNumber: 'AL-89241',
    userId: 'user-001',
    items: [
      CartItem(
        id: 'item-001',
        product: mockProducts[0], // Nordic Lounge Chair (৳34,900)
        selectedVariant: mockProducts[0].variants[0],
        quantity: 1,
      ),
      CartItem(
        id: 'item-002',
        product: mockProducts[3], // Sabi Stoneware Pedestal Vase (৳6,800)
        selectedVariant: mockProducts[3].variants[0],
        quantity: 1,
      ),
    ],
    shippingAddress: const Address(
      id: 'addr-001',
      fullName: 'Raihan Biswas',
      addressLine1: 'House 42, Road 11, Block D',
      addressLine2: 'Apt 4B, Banani',
      city: 'Dhaka',
      division: 'Dhaka',
      district: 'Dhaka',
      thana: 'Banani',
      postalCode: '1213',
      country: 'Bangladesh',
      phone: '+8801712345678',
      isDefault: true,
    ),
    shippingMethod: 'Complimentary Express Delivery',
    subtotal: 41700.0,
    discountAmount: 4170.0, // AURA10 applied
    shippingCost: 0.0, // Free delivery > ৳5,000
    taxAmount: 0.0,
    totalAmount: 37530.0,
    paymentStatus: 'paid',
    fulfillmentStatus: 'processing',
    createdAt: DateTime(2026, 9, 26, 14, 30),
    timeline: [
      OrderTimelineEvent(
        statusTitle: 'Order Placed',
        description: 'Your order was placed successfully and is being verified.',
        timestamp: DateTime(2026, 9, 26, 14, 30),
        isCompleted: true,
      ),
      OrderTimelineEvent(
        statusTitle: 'Payment Verified',
        description: 'Payment verified via bKash Merchant Gateway (TrxID: BK92841029).',
        timestamp: DateTime(2026, 9, 26, 14, 32),
        isCompleted: true,
      ),
      OrderTimelineEvent(
        statusTitle: 'Fulfillment & Craft Inspection',
        description: 'Pieces are being prepared and inspected at the Dhaka atelier.',
        timestamp: DateTime(2026, 9, 27, 09, 15),
        isCompleted: true,
      ),
      OrderTimelineEvent(
        statusTitle: 'Handed to Courier',
        description: 'Dispatched via Steadfast Courier (Consignment ID: SF-9824102).',
        timestamp: DateTime(2026, 9, 28, 10, 00),
        isCompleted: false,
      ),
      OrderTimelineEvent(
        statusTitle: 'Delivered',
        description: 'Safe arrival at your doorstep in Banani, Dhaka.',
        timestamp: DateTime(2026, 9, 30, 16, 00),
        isCompleted: false,
      ),
    ],
  ),
  Order(
    id: 'ord-81204',
    orderNumber: 'AL-81204',
    userId: 'user-001',
    items: [
      CartItem(
        id: 'item-003',
        product: mockProducts[1], // Akari Sculptural Floor Lamp (৳18,500)
        selectedVariant: mockProducts[1].variants[0],
        quantity: 1,
      ),
    ],
    shippingAddress: const Address(
      id: 'addr-001',
      fullName: 'Raihan Biswas',
      addressLine1: 'House 42, Road 11, Block D',
      addressLine2: 'Apt 4B, Banani',
      city: 'Dhaka',
      division: 'Dhaka',
      district: 'Dhaka',
      thana: 'Banani',
      postalCode: '1213',
      country: 'Bangladesh',
      phone: '+8801712345678',
      isDefault: true,
    ),
    shippingMethod: 'Inside Dhaka Standard Delivery',
    subtotal: 18500.0,
    discountAmount: 1000.0, // MINIMALIST applied
    shippingCost: 0.0,
    taxAmount: 0.0,
    totalAmount: 17500.0,
    paymentStatus: 'paid',
    fulfillmentStatus: 'delivered',
    createdAt: DateTime(2026, 9, 10, 11, 20),
    timeline: [
      OrderTimelineEvent(
        statusTitle: 'Order Placed',
        description: 'Order placed via Aura Living Mobile.',
        timestamp: DateTime(2026, 9, 10, 11, 20),
        isCompleted: true,
      ),
      OrderTimelineEvent(
        statusTitle: 'Payment Verified',
        description: 'Payment authorized via Nagad.',
        timestamp: DateTime(2026, 9, 10, 11, 21),
        isCompleted: true,
      ),
      OrderTimelineEvent(
        statusTitle: 'Handed to Courier',
        description: 'Handed over to Pathao Courier (Tracking: PTH-771924).',
        timestamp: DateTime(2026, 9, 11, 14, 00),
        isCompleted: true,
      ),
      OrderTimelineEvent(
        statusTitle: 'Delivered',
        description: 'Successfully delivered to customer in Dhaka.',
        timestamp: DateTime(2026, 9, 12, 17, 45),
        isCompleted: true,
      ),
    ],
  ),
  Order(
    id: 'ord-73019',
    orderNumber: 'AL-73019',
    userId: 'user-001',
    items: [
      CartItem(
        id: 'item-004',
        product: mockProducts[6], // Brutalist Stoneware Cup Set (৳4,200)
        selectedVariant: mockProducts[6].variants[0],
        quantity: 1,
      ),
    ],
    shippingAddress: const Address(
      id: 'addr-002',
      fullName: 'Tahmid Ahmed',
      addressLine1: 'Road 7, Sector 4, Uttara',
      addressLine2: null,
      city: 'Dhaka',
      division: 'Dhaka',
      district: 'Dhaka',
      thana: 'Uttara',
      postalCode: '1230',
      country: 'Bangladesh',
      phone: '+8801812345678',
      isDefault: false,
    ),
    shippingMethod: 'Inside Dhaka Standard Delivery',
    subtotal: 4200.0,
    discountAmount: 0.0,
    shippingCost: 80.0, // Delivery fee for orders under ৳5,000
    taxAmount: 0.0,
    totalAmount: 4280.0,
    paymentStatus: 'pending',
    fulfillmentStatus: 'confirmed',
    createdAt: DateTime(2026, 9, 29, 09, 15),
    timeline: [
      OrderTimelineEvent(
        statusTitle: 'Order Placed',
        description: 'Order placed with Cash on Delivery.',
        timestamp: DateTime(2026, 9, 29, 09, 15),
        isCompleted: true,
      ),
      OrderTimelineEvent(
        statusTitle: 'Order Confirmed',
        description: 'Phone call verification completed by Aura support team.',
        timestamp: DateTime(2026, 9, 29, 10, 00),
        isCompleted: true,
      ),
      OrderTimelineEvent(
        statusTitle: 'Fulfillment & Packing',
        description: 'Ceramics are being packed with sustainable honeycomb wrap.',
        timestamp: DateTime(2026, 9, 29, 11, 30),
        isCompleted: false,
      ),
    ],
  ),
];
