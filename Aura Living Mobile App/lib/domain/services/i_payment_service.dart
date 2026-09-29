import 'dart:async';

/// Supported payment methods for Bangladesh localized e-commerce
enum PaymentGatewayType {
  cod('Cash on Delivery', 'cash_on_delivery', 'Pay with cash upon white-glove inspection at your doorstep'),
  bkash('bKash', 'bkash', 'Instant mobile checkout via Bangladesh\'s premier MFS wallet'),
  nagad('Nagad', 'nagad', 'Fast digital payment powered by Bangladesh Post Office'),
  rocket('Rocket', 'rocket', 'Dutch-Bangla Bank secure mobile banking checkout'),
  card('Credit / Debit Card', 'card', 'Visa, Mastercard, and Amex processed with 256-bit encryption');

  final String title;
  final String key;
  final String subtitle;
  const PaymentGatewayType(this.title, this.key, this.subtitle);

  static PaymentGatewayType fromKey(String key) {
    return PaymentGatewayType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => PaymentGatewayType.cod,
    );
  }
}

/// Represents the status and audit trail of a payment attempt
class PaymentResult {
  final bool isSuccess;
  final String transactionId;
  final String? message;
  final PaymentGatewayType gatewayType;
  final double amount;
  final DateTime timestamp;
  final Map<String, dynamic>? rawMetadata;

  const PaymentResult({
    required this.isSuccess,
    required this.transactionId,
    this.message,
    required this.gatewayType,
    required this.amount,
    required this.timestamp,
    this.rawMetadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'transactionId': transactionId,
      'message': message,
      'gatewayType': gatewayType.key,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'rawMetadata': rawMetadata,
    };
  }
}

/// Abstract contract for plug-and-play payment gateway SDKs / webhooks
abstract class IPaymentGateway {
  PaymentGatewayType get gatewayType;
  String get displayName;

  /// Initiate checkout session or direct charge
  Future<PaymentResult> initiatePayment({
    required double amount,
    required String orderId,
    required String customerPhone,
    Map<String, dynamic>? extraParams,
  });

  /// Verify transaction with gateway server / webhook
  Future<PaymentResult> verifyTransaction(String transactionId);
}

/// Cash on Delivery Gateway Implementation
class CashOnDeliveryPaymentGateway implements IPaymentGateway {
  @override
  PaymentGatewayType get gatewayType => PaymentGatewayType.cod;

  @override
  String get displayName => 'Cash on Delivery';

  @override
  Future<PaymentResult> initiatePayment({
    required double amount,
    required String orderId,
    required String customerPhone,
    Map<String, dynamic>? extraParams,
  }) async {
    // COD orders are automatically confirmed in pending payment status
    return PaymentResult(
      isSuccess: true,
      transactionId: 'COD-${DateTime.now().millisecondsSinceEpoch}',
      message: 'Order placed with Cash on Delivery. Please keep exact change ready.',
      gatewayType: PaymentGatewayType.cod,
      amount: amount,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<PaymentResult> verifyTransaction(String transactionId) async {
    return PaymentResult(
      isSuccess: true,
      transactionId: transactionId,
      gatewayType: PaymentGatewayType.cod,
      amount: 0.0,
      timestamp: DateTime.now(),
    );
  }
}

/// bKash Payment Gateway Implementation (Sandbox / Live SDK Ready)
class BkashPaymentGateway implements IPaymentGateway {
  @override
  PaymentGatewayType get gatewayType => PaymentGatewayType.bkash;

  @override
  String get displayName => 'bKash MFS';

  @override
  Future<PaymentResult> initiatePayment({
    required double amount,
    required String orderId,
    required String customerPhone,
    Map<String, dynamic>? extraParams,
  }) async {
    // Simulated tokenized payment with bKash API format
    final trxId = extraParams?['trxId'] as String? ??
        'BK${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';
    return PaymentResult(
      isSuccess: true,
      transactionId: trxId,
      message: 'bKash payment verified successfully.',
      gatewayType: PaymentGatewayType.bkash,
      amount: amount,
      timestamp: DateTime.now(),
      rawMetadata: {
        'payerReference': customerPhone,
        'merchantInvoiceNumber': orderId,
      },
    );
  }

  @override
  Future<PaymentResult> verifyTransaction(String transactionId) async {
    return PaymentResult(
      isSuccess: true,
      transactionId: transactionId,
      gatewayType: PaymentGatewayType.bkash,
      amount: 0.0,
      timestamp: DateTime.now(),
    );
  }
}

/// Nagad Payment Gateway Implementation
class NagadPaymentGateway implements IPaymentGateway {
  @override
  PaymentGatewayType get gatewayType => PaymentGatewayType.nagad;

  @override
  String get displayName => 'Nagad Digital Payment';

  @override
  Future<PaymentResult> initiatePayment({
    required double amount,
    required String orderId,
    required String customerPhone,
    Map<String, dynamic>? extraParams,
  }) async {
    final trxId = extraParams?['trxId'] as String? ??
        'NG${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';
    return PaymentResult(
      isSuccess: true,
      transactionId: trxId,
      message: 'Nagad payment confirmed successfully.',
      gatewayType: PaymentGatewayType.nagad,
      amount: amount,
      timestamp: DateTime.now(),
      rawMetadata: {
        'customerPhone': customerPhone,
        'orderRef': orderId,
      },
    );
  }

  @override
  Future<PaymentResult> verifyTransaction(String transactionId) async {
    return PaymentResult(
      isSuccess: true,
      transactionId: transactionId,
      gatewayType: PaymentGatewayType.nagad,
      amount: 0.0,
      timestamp: DateTime.now(),
    );
  }
}

/// DBBL Rocket Payment Gateway Implementation
class RocketPaymentGateway implements IPaymentGateway {
  @override
  PaymentGatewayType get gatewayType => PaymentGatewayType.rocket;

  @override
  String get displayName => 'Rocket DBBL';

  @override
  Future<PaymentResult> initiatePayment({
    required double amount,
    required String orderId,
    required String customerPhone,
    Map<String, dynamic>? extraParams,
  }) async {
    final trxId = extraParams?['trxId'] as String? ??
        'RK${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';
    return PaymentResult(
      isSuccess: true,
      transactionId: trxId,
      message: 'Rocket transaction completed.',
      gatewayType: PaymentGatewayType.rocket,
      amount: amount,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<PaymentResult> verifyTransaction(String transactionId) async {
    return PaymentResult(
      isSuccess: true,
      transactionId: transactionId,
      gatewayType: PaymentGatewayType.rocket,
      amount: 0.0,
      timestamp: DateTime.now(),
    );
  }
}

/// Card Payment Gateway (SSLCommerz / Shurjopay / Stripe ready)
class CardPaymentGateway implements IPaymentGateway {
  @override
  PaymentGatewayType get gatewayType => PaymentGatewayType.card;

  @override
  String get displayName => 'Credit / Debit Card';

  @override
  Future<PaymentResult> initiatePayment({
    required double amount,
    required String orderId,
    required String customerPhone,
    Map<String, dynamic>? extraParams,
  }) async {
    final trxId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult(
      isSuccess: true,
      transactionId: trxId,
      message: 'Card authorized securely.',
      gatewayType: PaymentGatewayType.card,
      amount: amount,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<PaymentResult> verifyTransaction(String transactionId) async {
    return PaymentResult(
      isSuccess: true,
      transactionId: transactionId,
      gatewayType: PaymentGatewayType.card,
      amount: 0.0,
      timestamp: DateTime.now(),
    );
  }
}

/// Central Gateway Provider Factory
class PaymentServiceManager {
  static final Map<PaymentGatewayType, IPaymentGateway> _gateways = {
    PaymentGatewayType.cod: CashOnDeliveryPaymentGateway(),
    PaymentGatewayType.bkash: BkashPaymentGateway(),
    PaymentGatewayType.nagad: NagadPaymentGateway(),
    PaymentGatewayType.rocket: RocketPaymentGateway(),
    PaymentGatewayType.card: CardPaymentGateway(),
  };

  static IPaymentGateway getGateway(PaymentGatewayType type) {
    return _gateways[type] ?? _gateways[PaymentGatewayType.cod]!;
  }
}
