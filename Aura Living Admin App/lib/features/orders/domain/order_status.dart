/// Order Status Workflow localized for Bangladesh e-commerce & courier delivery
enum OrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  processing('Processing'),
  shipped('Handed to Courier'),
  delivered('Delivered'),
  cancelled('Cancelled'),
  returned('Returned');

  final String label;
  const OrderStatus(this.label);

  /// Valid forward progression:
  /// [Pending] -> [Confirmed] -> [Processing] -> [Handed to Courier] -> [Delivered]
  OrderStatus? get nextLogicalStatus {
    switch (this) {
      case OrderStatus.pending:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.processing;
      case OrderStatus.processing:
        return OrderStatus.shipped;
      case OrderStatus.shipped:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
      case OrderStatus.returned:
        return null;
    }
  }

  /// Permitted manual transitions
  List<OrderStatus> get permittedTransitions {
    switch (this) {
      case OrderStatus.pending:
        return [OrderStatus.confirmed, OrderStatus.processing, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return [OrderStatus.processing, OrderStatus.shipped, OrderStatus.cancelled];
      case OrderStatus.processing:
        return [OrderStatus.shipped, OrderStatus.cancelled];
      case OrderStatus.shipped:
        return [OrderStatus.delivered, OrderStatus.returned, OrderStatus.cancelled];
      case OrderStatus.delivered:
        return [OrderStatus.returned];
      case OrderStatus.cancelled:
      case OrderStatus.returned:
        return [];
    }
  }

  List<OrderStatus> get allowedNextStatuses => permittedTransitions;

  bool canTransitionTo(OrderStatus target) {
    return permittedTransitions.contains(target);
  }
}

/// Popular Bangladesh Courier Delivery Partners
class BangladeshCourierPartners {
  BangladeshCourierPartners._();

  static const String steadfast = 'Steadfast Courier';
  static const String pathao = 'Pathao Courier';
  static const String redx = 'RedX Delivery';
  static const String paperfly = 'Paperfly';
  static const String eCourier = 'eCourier';
  static const String inHouse = 'Aura In-House Fleet (Dhaka Metro)';

  static const List<String> all = [
    steadfast,
    pathao,
    redx,
    paperfly,
    eCourier,
    inHouse,
  ];
}
