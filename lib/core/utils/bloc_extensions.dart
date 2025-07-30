import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/auth/auth_state.dart';
import '../../presentation/bloc/location/location_state.dart';
import '../../presentation/bloc/order/order_bloc.dart';
import '../../presentation/bloc/location/location_bloc.dart';
import '../../presentation/bloc/order/order_state.dart';

extension BlocContext on BuildContext {
  // Easy access to BLoCs
  AuthBloc get authBloc => read<AuthBloc>();
  OrderBloc get orderBloc => read<OrderBloc>();
  LocationBloc get locationBloc => read<LocationBloc>();

  // Easy access to BLoC states
  AuthState get authState => watch<AuthBloc>().state;
  OrderState get orderState => watch<OrderBloc>().state;
  LocationState get locationState => watch<LocationBloc>().state;
}

extension SnackBarHelper on BuildContext {
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void showInfoSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}