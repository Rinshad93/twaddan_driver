import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'order_item_model.dart';

enum OrderStatus {
  pending,
  accepted,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pickup Ready';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.inTransit:
        return 'in_transit';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}

class Order extends Equatable {
  final String id;
  final String restaurantName;
  final String restaurantAddress;
  final LatLng restaurantLocation;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final LatLng customerLocation;
  final List<OrderItem> items;
  final double totalAmount;
  final double deliveryFee;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime estimatedPickupTime;
  final DateTime estimatedDeliveryTime;
  final String? specialInstructions;
  final String? restaurantPhone;
  final double distanceToRestaurant;
  final double distanceToCustomer;

  const Order({
    required this.id,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantLocation,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
    required this.customerLocation,
    required this.items,
    required this.totalAmount,
    required this.deliveryFee,
    required this.status,
    required this.createdAt,
    required this.estimatedPickupTime,
    required this.estimatedDeliveryTime,
    this.specialInstructions,
    this.restaurantPhone,
    required this.distanceToRestaurant,
    required this.distanceToCustomer,
  });

  Order copyWith({
    String? id,
    String? restaurantName,
    String? restaurantAddress,
    LatLng? restaurantLocation,
    String? customerName,
    String? customerAddress,
    String? customerPhone,
    LatLng? customerLocation,
    List<OrderItem>? items,
    double? totalAmount,
    double? deliveryFee,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? estimatedPickupTime,
    DateTime? estimatedDeliveryTime,
    String? specialInstructions,
    String? restaurantPhone,
    double? distanceToRestaurant,
    double? distanceToCustomer,
  }) {
    return Order(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      customerLocation: customerLocation ?? this.customerLocation,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      estimatedPickupTime: estimatedPickupTime ?? this.estimatedPickupTime,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      restaurantPhone: restaurantPhone ?? this.restaurantPhone,
      distanceToRestaurant: distanceToRestaurant ?? this.distanceToRestaurant,
      distanceToCustomer: distanceToCustomer ?? this.distanceToCustomer,
    );
  }

  double get driverEarning => deliveryFee * 0.8; // 80% of delivery fee

  double get totalDistance => distanceToRestaurant + distanceToCustomer;

  int get estimatedTotalMinutes {
    final pickupMinutes = (distanceToRestaurant * 2).round(); // 2 min per km
    final deliveryMinutes = (distanceToCustomer * 2).round();
    return pickupMinutes + deliveryMinutes + 5; // +5 min for pickup
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantName': restaurantName,
      'restaurantAddress': restaurantAddress,
      'restaurantLocation': {
        'latitude': restaurantLocation.latitude,
        'longitude': restaurantLocation.longitude,
      },
      'customerName': customerName,
      'customerAddress': customerAddress,
      'customerPhone': customerPhone,
      'customerLocation': {
        'latitude': customerLocation.latitude,
        'longitude': customerLocation.longitude,
      },
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'deliveryFee': deliveryFee,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'estimatedPickupTime': estimatedPickupTime.toIso8601String(),
      'estimatedDeliveryTime': estimatedDeliveryTime.toIso8601String(),
      'specialInstructions': specialInstructions,
      'restaurantPhone': restaurantPhone,
      'distanceToRestaurant': distanceToRestaurant,
      'distanceToCustomer': distanceToCustomer,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    OrderStatus status = OrderStatus.pending;
    try {
      status = OrderStatus.values.firstWhere(
            (e) => e.value == json['status'],
        orElse: () => OrderStatus.pending,
      );
    } catch (e) {
      status = OrderStatus.pending;
    }

    return Order(
      id: json['id'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      restaurantAddress: json['restaurantAddress'] ?? '',
      restaurantLocation: LatLng(
        json['restaurantLocation']['latitude'].toDouble(),
        json['restaurantLocation']['longitude'].toDouble(),
      ),
      customerName: json['customerName'] ?? '',
      customerAddress: json['customerAddress'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      customerLocation: LatLng(
        json['customerLocation']['latitude'].toDouble(),
        json['customerLocation']['longitude'].toDouble(),
      ),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
      status: status,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      estimatedPickupTime: DateTime.parse(
        json['estimatedPickupTime'] ?? DateTime.now().toIso8601String(),
      ),
      estimatedDeliveryTime: DateTime.parse(
        json['estimatedDeliveryTime'] ?? DateTime.now().toIso8601String(),
      ),
      specialInstructions: json['specialInstructions'],
      restaurantPhone: json['restaurantPhone'],
      distanceToRestaurant: (json['distanceToRestaurant'] ?? 0.0).toDouble(),
      distanceToCustomer: (json['distanceToCustomer'] ?? 0.0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    restaurantName,
    restaurantAddress,
    restaurantLocation,
    customerName,
    customerAddress,
    customerPhone,
    customerLocation,
    items,
    totalAmount,
    deliveryFee,
    status,
    createdAt,
    estimatedPickupTime,
    estimatedDeliveryTime,
    specialInstructions,
    restaurantPhone,
    distanceToRestaurant,
    distanceToCustomer,
  ];
}