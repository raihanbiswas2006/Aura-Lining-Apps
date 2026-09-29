import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/repositories/i_order_repository.dart';
import '../cart/cart_cubit.dart';

enum CheckoutStep { shippingAddress, shippingMethod, paymentMethod, review }

class CheckoutState {
  final CheckoutStep currentStep;
  final Address? shippingAddress;
  final String shippingMethod; // 'dhaka' | 'outside_dhaka' | 'express'
  final double shippingCost;
  final String paymentMethod; // 'cod' | 'bkash' | 'nagad' | 'rocket' | 'card'
  final Map<String, String> cardDetails;
  final String? mfsTransactionId; // bKash / Nagad / Rocket transaction reference
  final bool isPlacingOrder;
  final Order? completedOrder;
  final String? error;

  const CheckoutState({
    this.currentStep = CheckoutStep.shippingAddress,
    this.shippingAddress,
    this.shippingMethod = 'dhaka',
    this.shippingCost = 80.0,
    this.paymentMethod = 'cod',
    this.cardDetails = const {},
    this.mfsTransactionId,
    this.isPlacingOrder = false,
    this.completedOrder,
    this.error,
  });

  String get shippingMethodTitle {
    switch (shippingMethod) {
      case 'outside_dhaka':
        return 'Outside Dhaka — Nationwide Courier (Steadfast / Pathao, 2–4 business days)';
      case 'express':
        return 'Express Same-Day Dhaka Delivery (Within 12 hours)';
      case 'dhaka':
      default:
        return 'Inside Dhaka Metro Delivery (1–2 business days)';
    }
  }

  CheckoutState copyWith({
    CheckoutStep? currentStep,
    Address? shippingAddress,
    String? shippingMethod,
    double? shippingCost,
    String? paymentMethod,
    Map<String, String>? cardDetails,
    String? mfsTransactionId,
    bool? isPlacingOrder,
    Order? completedOrder,
    String? error,
    bool clearError = false,
  }) {
    return CheckoutState(
      currentStep: currentStep ?? this.currentStep,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      shippingCost: shippingCost ?? this.shippingCost,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cardDetails: cardDetails ?? this.cardDetails,
      mfsTransactionId: mfsTransactionId ?? this.mfsTransactionId,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      completedOrder: completedOrder ?? this.completedOrder,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CheckoutCubit extends Cubit<CheckoutState> {
  final IOrderRepository _orderRepository;

  CheckoutCubit(this._orderRepository) : super(const CheckoutState());

  void setInitialAddress(Address? address) {
    if (address != null && state.shippingAddress == null) {
      emit(state.copyWith(shippingAddress: address));
    }
  }

  void selectAddress(Address address) {
    // Automatically pre-select shipping tier based on division/district
    final isInsideDhaka = address.district.toLowerCase() == 'dhaka' ||
        address.city.toLowerCase() == 'dhaka' ||
        address.division.toLowerCase() == 'dhaka';
    final method = isInsideDhaka ? 'dhaka' : 'outside_dhaka';
    final cost = isInsideDhaka ? 80.0 : 150.0;

    emit(state.copyWith(
      shippingAddress: address,
      shippingMethod: method,
      shippingCost: cost,
      currentStep: CheckoutStep.shippingMethod,
      clearError: true,
    ));
  }

  void selectShippingMethod(String method, {double subtotal = 0.0}) {
    double cost = 80.0;
    if (subtotal >= 5000.0 && method != 'express') {
      cost = 0.0; // Free complimentary delivery on orders over ৳5,000
    } else if (method == 'outside_dhaka') {
      cost = subtotal >= 5000.0 ? 0.0 : 150.0;
    } else if (method == 'express') {
      cost = 250.0;
    } else {
      cost = subtotal >= 5000.0 ? 0.0 : 80.0;
    }

    emit(state.copyWith(
      shippingMethod: method,
      shippingCost: cost,
      currentStep: CheckoutStep.paymentMethod,
      clearError: true,
    ));
  }

  void selectPaymentMethod(
    String method, {
    Map<String, String>? cardDetails,
    String? mfsTransactionId,
  }) {
    emit(state.copyWith(
      paymentMethod: method,
      cardDetails: cardDetails ?? state.cardDetails,
      mfsTransactionId: mfsTransactionId ?? state.mfsTransactionId,
      currentStep: CheckoutStep.review,
      clearError: true,
    ));
  }

  void goToStep(CheckoutStep step) {
    emit(state.copyWith(currentStep: step, clearError: true));
  }

  Future<Order?> placeOrder({
    required CartState cartState,
    required String userId,
    required Future<void> Function() onOrderSuccess,
  }) async {
    if (state.shippingAddress == null) {
      emit(state.copyWith(error: 'Please select a delivery address'));
      return null;
    }

    emit(state.copyWith(isPlacingOrder: true, clearError: true));

    try {
      // Simulate network verification with realistic latency
      await Future.delayed(const Duration(milliseconds: 600));

      final randomNum = Random().nextInt(90000) + 10000;
      final orderNumber = 'AL-$randomNum';
      final now = DateTime.now();

      final isCod = state.paymentMethod == 'cod';
      final isBkash = state.paymentMethod == 'bkash';
      final isNagad = state.paymentMethod == 'nagad';
      final isRocket = state.paymentMethod == 'rocket';

      String paymentTitle;
      String paymentDetail;
      if (isCod) {
        paymentTitle = 'Cash on Delivery (Pending)';
        paymentDetail = 'Payment to be collected in cash upon doorstep delivery.';
      } else if (isBkash) {
        paymentTitle = 'bKash MFS';
        paymentDetail = 'Verified via bKash Gateway (TrxID: ${state.mfsTransactionId ?? 'BK$randomNum'}).';
      } else if (isNagad) {
        paymentTitle = 'Nagad Digital';
        paymentDetail = 'Verified via Nagad Payment (TrxID: ${state.mfsTransactionId ?? 'NG$randomNum'}).';
      } else if (isRocket) {
        paymentTitle = 'Rocket DBBL';
        paymentDetail = 'Verified via Rocket Banking (TrxID: ${state.mfsTransactionId ?? 'RK$randomNum'}).';
      } else {
        paymentTitle = 'Card Online';
        paymentDetail = 'Payment authorized via 256-bit encrypted card gateway.';
      }

      final order = Order(
        id: 'ord-$randomNum',
        orderNumber: orderNumber,
        userId: userId,
        items: cartState.items,
        shippingAddress: state.shippingAddress!,
        shippingMethod: state.shippingMethodTitle,
        subtotal: cartState.subtotal,
        discountAmount: cartState.discountAmount,
        shippingCost: state.shippingCost,
        taxAmount: 0.0,
        totalAmount: cartState.subtotal - cartState.discountAmount + state.shippingCost,
        paymentStatus: isCod ? 'pending' : 'paid',
        fulfillmentStatus: 'confirmed',
        createdAt: now,
        timeline: [
          OrderTimelineEvent(
            statusTitle: 'Order Placed',
            description: 'Your order was submitted successfully.',
            timestamp: now,
            isCompleted: true,
          ),
          OrderTimelineEvent(
            statusTitle: isCod ? 'Order Confirmed' : '$paymentTitle Verified',
            description: paymentDetail,
            timestamp: now.add(const Duration(minutes: 2)),
            isCompleted: true,
          ),
          OrderTimelineEvent(
            statusTitle: 'Fulfillment & Craft Inspection',
            description: 'Pieces are inspected and packed at the Dhaka atelier.',
            timestamp: now.add(const Duration(hours: 4)),
            isCompleted: false,
          ),
          OrderTimelineEvent(
            statusTitle: 'Handed to Courier',
            description: 'Assigned to Steadfast / Pathao courier dispatch.',
            timestamp: now.add(const Duration(days: 1)),
            isCompleted: false,
          ),
          OrderTimelineEvent(
            statusTitle: 'Delivered',
            description: 'Safe arrival at your doorstep in Bangladesh.',
            timestamp: now.add(const Duration(days: 3)),
            isCompleted: false,
          ),
        ],
      );

      final created = await _orderRepository.createOrder(order);
      await onOrderSuccess();

      emit(state.copyWith(
        isPlacingOrder: false,
        completedOrder: created,
      ));

      return created;
    } catch (e) {
      emit(state.copyWith(
        isPlacingOrder: false,
        error: 'Failed to place order: ${e.toString()}',
      ));
      return null;
    }
  }

  void resetCheckout() {
    emit(const CheckoutState());
  }
}
