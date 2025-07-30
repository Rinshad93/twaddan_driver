import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_model.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/auth/auth_state.dart';
import '../../presentation/bloc/order/order_bloc.dart';
import '../../presentation/bloc/order/order_state.dart';
import '../../presentation/bloc/location/location_bloc.dart';
import '../../presentation/bloc/location/location_state.dart';
import 'bloc_extensions.dart';

class GlobalBlocListener extends StatelessWidget {
  final Widget child;

  const GlobalBlocListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Auth BLoC Listener
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              context.showErrorSnackBar(state.message);
            } else if (state is AuthStatusUpdated) {
              final status = state.driver.isOnline ? 'online' : 'offline';
              context.showSuccessSnackBar('You are now $status');
            }
          },
        ),

        // Order BLoC Listener
        BlocListener<OrderBloc, OrderState>(
          listener: (context, state) {
            if (state is OrderError) {
              context.showErrorSnackBar(state.message);
            } else if (state is OrderAccepted) {

            } else if (state is OrderStatusUpdated) {
              final statusMessage = _getStatusUpdateMessage(state.order.status);
              context.showSuccessSnackBar(statusMessage);
            }
          },
        ),

        // Location BLoC Listener
        BlocListener<LocationBloc, LocationState>(
          listener: (context, state) {
            if (state is LocationError) {
              context.showErrorSnackBar(state.message);
            } else if (state is LocationPermissionDenied) {
              context.showErrorSnackBar('Location permission is required for delivery tracking');
            } else if (state is LocationServiceDisabled) {
              context.showErrorSnackBar('Please enable location services');
            }
          },
        ),
      ],
      child: child,
    );
  }

  String _getStatusUpdateMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return 'Order accepted';
      case OrderStatus.pickedUp:
        return 'Order picked up successfully';
      case OrderStatus.inTransit:
        return 'On the way to customer';
      case OrderStatus.delivered:
        return 'Order delivered successfully! 🎉';
      case OrderStatus.cancelled:
        return 'Order cancelled';
      default:
        return 'Order status updated';
    }
  }
}