import '../models/order_model.dart';

abstract class OrderRepository {
  Future<List<Order>> getAvailableOrders();
  Future<List<Order>> getActiveOrders();
  Future<List<Order>> getOrderHistory();
  Future<Order> acceptOrder(String orderId);
  Future<void> declineOrder(String orderId, {String? reason});
  Future<Order> updateOrderStatus(String orderId, OrderStatus status);
  Future<Order> getOrderById(String orderId);
  Stream<List<Order>> watchAvailableOrders();
  Stream<Order> watchOrderStatus(String orderId);
  Future<Map<String, double>> getTodayEarnings();
  Future<Map<String, double>> getWeeklyEarnings();
  Future<Map<String, double>> getMonthlyEarnings();
}