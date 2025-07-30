import 'package:equatable/equatable.dart';
import '../../../data/models/order_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class OrderAvailableLoaded extends OrderState {
  final List<Order> orders;

  const OrderAvailableLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderActiveLoaded extends OrderState {
  final List<Order> orders;

  const OrderActiveLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderHistoryLoaded extends OrderState {
  final List<Order> orders;

  const OrderHistoryLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderAccepting extends OrderState {
  final String orderId;

  const OrderAccepting(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class OrderAccepted extends OrderState {
  final Order order;

  const OrderAccepted(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderDeclining extends OrderState {
  final String orderId;

  const OrderDeclining(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class OrderDeclined extends OrderState {
  final String orderId;
  final String message;

  const OrderDeclined(this.orderId, this.message);

  @override
  List<Object?> get props => [orderId, message];
}

class OrderStatusUpdating extends OrderState {
  final String orderId;
  final OrderStatus status;

  const OrderStatusUpdating({
    required this.orderId,
    required this.status,
  });

  @override
  List<Object?> get props => [orderId, status];
}

class OrderStatusUpdated extends OrderState {
  final Order order;

  const OrderStatusUpdated(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderEarningsLoaded extends OrderState {
  final Map<String, double> todayEarnings;
  final Map<String, double> weeklyEarnings;
  final Map<String, double> monthlyEarnings;

  const OrderEarningsLoaded({
    required this.todayEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
  });

  @override
  List<Object?> get props => [todayEarnings, weeklyEarnings, monthlyEarnings];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderEmpty extends OrderState {
  final String message;

  const OrderEmpty(this.message);

  @override
  List<Object?> get props => [message];
}

