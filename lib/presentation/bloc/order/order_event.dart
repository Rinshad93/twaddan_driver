import 'package:equatable/equatable.dart';
import '../../../data/models/order_model.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class OrderLoadAvailable extends OrderEvent {
  final bool forceReload;

  const OrderLoadAvailable({this.forceReload = false});

  @override
  List<Object?> get props => [forceReload];
}

class OrderLoadActive extends OrderEvent {
  final bool forceReload;

  const OrderLoadActive({this.forceReload = false});

  @override
  List<Object?> get props => [forceReload];
}

class OrderLoadHistory extends OrderEvent {
  final bool forceReload;

  const OrderLoadHistory({this.forceReload = false});

  @override
  List<Object?> get props => [forceReload];
}

class OrderAccept extends OrderEvent {
  final String orderId;

  const OrderAccept(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class OrderDecline extends OrderEvent {
  final String orderId;
  final String? reason;

  const OrderDecline(this.orderId, {this.reason});

  @override
  List<Object?> get props => [orderId, reason];
}

class OrderUpdateStatus extends OrderEvent {
  final String orderId;
  final OrderStatus status;

  const OrderUpdateStatus({
    required this.orderId,
    required this.status,
  });

  @override
  List<Object?> get props => [orderId, status];
}

class OrderWatchAvailable extends OrderEvent {
  const OrderWatchAvailable();
}

class OrderWatchStatus extends OrderEvent {
  final String orderId;

  const OrderWatchStatus(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class OrderStopWatching extends OrderEvent {
  const OrderStopWatching();
}

class OrderRefresh extends OrderEvent {
  const OrderRefresh();
}

class OrderLoadEarnings extends OrderEvent {
  final bool forceReload;

  const OrderLoadEarnings({this.forceReload = false});

  @override
  List<Object?> get props => [forceReload];
}

class OrderErrorCleared extends OrderEvent {
  const OrderErrorCleared();
}



