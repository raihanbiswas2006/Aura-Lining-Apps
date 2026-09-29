import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final ProductVariant selectedVariant;
  final int quantity;

  const CartItem({
    required this.id,
    required this.product,
    required this.selectedVariant,
    required this.quantity,
  });

  double get unitPrice => selectedVariant.price;
  double get totalPrice => unitPrice * quantity;
  double get subtotal => totalPrice;

  CartItem copyWith({
    String? id,
    Product? product,
    ProductVariant? selectedVariant,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'selectedVariant': selectedVariant.toJson(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      selectedVariant: ProductVariant.fromJson(
          json['selectedVariant'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
