import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? specialInstructions;

  const OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.specialInstructions,
  });

  OrderItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? price,
    String? specialInstructions,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'specialInstructions': specialInstructions,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
      specialInstructions: json['specialInstructions'],
    );
  }

  @override
  List<Object?> get props => [id, name, quantity, price, specialInstructions];
}