import 'package:equatable/equatable.dart';
import 'product_model.dart';

class OrderItemModel extends Equatable {
  final int id;
  final int orderId;
  final int productId;
  final String productName;
  final String price;
  final int quantity;
  final String subtotal;
  final String taxAmount;
  final String discountAmount;
  final String total;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProductModel product;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      price: json['price'],
      quantity: json['quantity'],
      subtotal: json['subtotal'],
      taxAmount: json['tax_amount'],
      discountAmount: json['discount_amount'],
      total: json['total'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      product: ProductModel.fromJson(json['product']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total': total,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'product': product.toJson(),
    };
  }

  // Helper getters
  String? get specialInstructions {
    // This is a placeholder - you may want to add this field to the model
    return null;
  }
  
  String get formattedPrice {
    try {
      final priceValue = double.parse(price);
      return '\$${priceValue.toStringAsFixed(2)}';
    } catch (e) {
      return price;
    }
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        productId,
        productName,
        price,
        quantity,
        subtotal,
        taxAmount,
        discountAmount,
        total,
        createdAt,
        updatedAt,
        product,
      ];
}