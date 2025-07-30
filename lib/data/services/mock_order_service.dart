import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';


import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../mock/mock_order_data.dart';
import '../repositories/order_repository.dart';
class MockOrderService implements OrderRepository {
  // Stream controllers for real-time updates
  final _availableOrdersController = StreamController<List<Order>>.broadcast();
  final _orderStatusController = StreamController<Order>.broadcast();

  // In-memory storage for current state
  List<Order> _availableOrders = [];
  List<Order> _activeOrders = [];
  final List<Order> _completedOrders = MockOrderData.completedOrders;

  // Track operations in progress to prevent race conditions
  final Set<String> _ordersBeingProcessed = <String>{};

  MockOrderService() {
    _initializeOrders();
    _startOrderSimulation();
  }

  void _initializeOrders() {
    _availableOrders = List.from(MockOrderData.availableOrders);
    _activeOrders = List.from(MockOrderData.activeOrders);
  }

  void _startOrderSimulation() {
    // Simulate new orders appearing every 2-4 minutes
    Timer.periodic(const Duration(minutes: 3), (timer) {
      _addRandomOrder();
    });

    // Simulate order status updates every 30 seconds for active orders
    Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateActiveOrderStatuses();
    });
  }

  void _addRandomOrder() {
    if (_availableOrders.length < 5) {
      final newOrder = _generateRandomOrder();
      _availableOrders.add(newOrder);
      _notifyAvailableOrdersUpdate();
    }
  }

  Order _generateRandomOrder() {
    final random = Random();
    final restaurants = [
      'McDonald\'s', 'Burger King', 'KFC', 'Pizza Hut', 'Subway',
      'Taco Bell', 'Domino\'s', 'Starbucks', 'Chipotle', 'Wendy\'s'
    ];
    final customerNames = [
      'John Doe', 'Jane Smith', 'Mike Johnson', 'Sarah Wilson',
      'David Brown', 'Lisa Davis', 'Tom Anderson', 'Amy Taylor'
    ];

    final restaurantName = restaurants[random.nextInt(restaurants.length)];
    final customerName = customerNames[random.nextInt(customerNames.length)];

    return Order(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      restaurantName: restaurantName,
      restaurantAddress: '${100 + random.nextInt(900)} Random St, San Francisco, CA',
      restaurantLocation: LatLng(
        37.7749 + (random.nextDouble() - 0.5) * 0.1,
        -122.4194 + (random.nextDouble() - 0.5) * 0.1,
      ),
      customerName: customerName,
      customerAddress: '${100 + random.nextInt(900)} Customer Ave, San Francisco, CA',
      customerPhone: '+1 (555) ${100 + random.nextInt(900)}-${1000 + random.nextInt(9000)}',
      customerLocation: LatLng(
        37.7749 + (random.nextDouble() - 0.5) * 0.1,
        -122.4194 + (random.nextDouble() - 0.5) * 0.1,
      ),
      items: _generateRandomItems(),
      totalAmount: 15.0 + random.nextDouble() * 25.0,
      deliveryFee: 3.99 + random.nextDouble() * 3.0,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      estimatedPickupTime: DateTime.now().add(Duration(minutes: 5 + random.nextInt(15))),
      estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 20 + random.nextInt(20))),
      restaurantPhone: '+1 (555) ${100 + random.nextInt(900)}-${1000 + random.nextInt(9000)}',
      distanceToRestaurant: 0.5 + random.nextDouble() * 2.0,
      distanceToCustomer: 1.0 + random.nextDouble() * 3.0,
    );
  }

  List<OrderItem> _generateRandomItems() {
    final random = Random();
    final items = <OrderItem>[];
    final itemCount = 1 + random.nextInt(3);

    final possibleItems = [
      ('Burger', 8.99), ('Pizza', 12.99), ('Sandwich', 6.99),
      ('Fries', 3.99), ('Drink', 2.99), ('Salad', 7.99),
      ('Chicken', 9.99), ('Pasta', 11.99), ('Soup', 4.99),
    ];

    for (int i = 0; i < itemCount; i++) {
      final item = possibleItems[random.nextInt(possibleItems.length)];
      items.add(OrderItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}_$i',
        name: item.$1,
        quantity: 1 + random.nextInt(2),
        price: item.$2,
      ));
    }

    return items;
  }

  void _updateActiveOrderStatuses() {
    for (int i = 0; i < _activeOrders.length; i++) {
      final order = _activeOrders[i];

      // Skip if order is being processed
      if (_ordersBeingProcessed.contains(order.id)) continue;

      final timeSinceCreated = DateTime.now().difference(order.createdAt).inMinutes;

      OrderStatus newStatus = order.status;

      // Simulate realistic status progression
      if (order.status == OrderStatus.accepted && timeSinceCreated > 10) {
        newStatus = OrderStatus.pickedUp;
      } else if (order.status == OrderStatus.pickedUp && timeSinceCreated > 15) {
        newStatus = OrderStatus.inTransit;
      } else if (order.status == OrderStatus.inTransit && timeSinceCreated > 25) {
        newStatus = OrderStatus.delivered;
      }

      if (newStatus != order.status) {
        final updatedOrder = order.copyWith(status: newStatus);
        _activeOrders[i] = updatedOrder;
        _orderStatusController.add(updatedOrder);

        // Move completed orders to history
        if (newStatus == OrderStatus.delivered) {
          _activeOrders.removeAt(i);
          _completedOrders.insert(0, updatedOrder);
          i--; // Adjust index after removal
        }
      }
    }
  }

  void _notifyAvailableOrdersUpdate() {
    _availableOrdersController.add(List.from(_availableOrders));
  }

  @override
  Future<List<Order>> getAvailableOrders() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_availableOrders);
  }

  @override
  Future<List<Order>> getActiveOrders() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_activeOrders);
  }

  @override
  Future<List<Order>> getOrderHistory() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_completedOrders);
  }

  @override
  Future<Order> acceptOrder(String orderId) async {
    // Prevent concurrent operations on the same order
    if (_ordersBeingProcessed.contains(orderId)) {
      throw Exception('Order is already being processed');
    }

    _ordersBeingProcessed.add(orderId);

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final orderIndex = _availableOrders.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) {
        throw Exception('Order not found or already accepted by another driver');
      }

      final order = _availableOrders[orderIndex];
      final acceptedOrder = order.copyWith(status: OrderStatus.accepted);

      // Atomic update: Remove from available and add to active
      _availableOrders.removeAt(orderIndex);
      _activeOrders.add(acceptedOrder);

      // Notify streams
      _notifyAvailableOrdersUpdate();
      _orderStatusController.add(acceptedOrder);

      return acceptedOrder;
    } finally {
      _ordersBeingProcessed.remove(orderId);
    }
  }

  @override
  Future<void> declineOrder(String orderId, {String? reason}) async {
    // Prevent concurrent operations on the same order
    if (_ordersBeingProcessed.contains(orderId)) {
      throw Exception('Order is already being processed');
    }

    _ordersBeingProcessed.add(orderId);

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final orderIndex = _availableOrders.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) {
        throw Exception('Order not found or already processed');
      }

      final order = _availableOrders[orderIndex];

      // Remove from available orders
      _availableOrders.removeAt(orderIndex);

      // Log the decline reason for analytics
      print('Order ${order.id} declined by driver. Reason: ${reason ?? 'No reason provided'}');

      // Notify available orders stream
      _notifyAvailableOrdersUpdate();
    } finally {
      _ordersBeingProcessed.remove(orderId);
    }
  }

  @override
  Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    // Prevent concurrent operations on the same order
    if (_ordersBeingProcessed.contains(orderId)) {
      throw Exception('Order status is already being updated');
    }

    _ordersBeingProcessed.add(orderId);

    try {
      await Future.delayed(const Duration(milliseconds: 400));

      final orderIndex = _activeOrders.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) {
        throw Exception('Active order not found');
      }

      final order = _activeOrders[orderIndex];
      final updatedOrder = order.copyWith(status: status);

      _activeOrders[orderIndex] = updatedOrder;
      _orderStatusController.add(updatedOrder);

      // Move to completed if delivered
      if (status == OrderStatus.delivered) {
        _activeOrders.removeAt(orderIndex);
        _completedOrders.insert(0, updatedOrder);
      }

      return updatedOrder;
    } finally {
      _ordersBeingProcessed.remove(orderId);
    }
  }

  @override
  Future<Order> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Search in all order lists
    final allOrders = [
      ..._availableOrders,
      ..._activeOrders,
      ..._completedOrders,
    ];

    final order = allOrders.firstWhere(
          (order) => order.id == orderId,
      orElse: () => throw Exception('Order not found'),
    );

    return order;
  }

  @override
  Stream<List<Order>> watchAvailableOrders() {
    // Emit current state immediately, then listen for updates
    Future.delayed(Duration.zero, () {
      _notifyAvailableOrdersUpdate();
    });

    return _availableOrdersController.stream;
  }

  @override
  Stream<Order> watchOrderStatus(String orderId) {
    return _orderStatusController.stream
        .where((order) => order.id == orderId);
  }

  @override
  Future<Map<String, double>> getTodayEarnings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockOrderData.todayEarnings;
  }

  @override
  Future<Map<String, double>> getWeeklyEarnings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockOrderData.weeklyEarnings;
  }

  @override
  Future<Map<String, double>> getMonthlyEarnings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockOrderData.monthlyEarnings;
  }

  // Utility method to check if an order is being processed
  bool isOrderBeingProcessed(String orderId) {
    return _ordersBeingProcessed.contains(orderId);
  }

  // Method to get current state without async delay (for debugging)
  List<Order> getCurrentAvailableOrders() => List.from(_availableOrders);
  List<Order> getCurrentActiveOrders() => List.from(_activeOrders);
  List<Order> getCurrentCompletedOrders() => List.from(_completedOrders);

  void dispose() {
    _availableOrdersController.close();
    _orderStatusController.close();
  }
}

