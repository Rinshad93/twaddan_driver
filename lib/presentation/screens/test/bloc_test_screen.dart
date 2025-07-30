/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/bloc_extensions.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/order/order_bloc.dart';
import '../../bloc/order/order_event.dart';
import '../../bloc/order/order_state.dart';
import '../../bloc/location/location_bloc.dart';
import '../../bloc/location/location_event.dart';
import '../../bloc/location/location_state.dart';

class BlocTestScreen extends StatelessWidget {
  const BlocTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLoC Test Screen'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(AppDimensions.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthTestSection(),
            SizedBox(height: AppDimensions.spaceL),
            _OrderTestSection(),
            SizedBox(height: AppDimensions.spaceL),
            _LocationTestSection(),
          ],
        ),
      ),
    );
  }
}

class _AuthTestSection extends StatelessWidget {
  const _AuthTestSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authentication BLoC',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceS),
                      decoration: BoxDecoration(
                        color: _getStateColor(state).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        border: Border.all(color: _getStateColor(state)),
                      ),
                      child: Text(
                        'State: ${state.runtimeType}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _getStateColor(state),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    if (state is AuthAuthenticated) ...[
                      Text(
                        'Driver: ${state.driver.name}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      Text(
                        'Status: ${state.driver.isOnline ? "Online" : "Offline"}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                    ],
                    if (state is AuthError) ...[
                      Text(
                        'Error: ${state.message}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: state is AuthLoading ? null : () {
                              context.authBloc.add(
                                const AuthLoginRequested(
                                  email: 'john.smith@driver.com',
                                  password: '123456',
                                ),
                              );
                            },
                            child: const Text('Test Login'),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceS),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state is AuthLoading ? null : () {
                              context.authBloc.add(const AuthLogoutRequested());
                            },
                            child: const Text('Test Logout'),
                          ),
                        ),
                      ],
                    ),
                    if (state is AuthAuthenticated) ...[
                      const SizedBox(height: AppDimensions.spaceS),
                      ElevatedButton(
                        onPressed: () {
                          context.authBloc.add(
                            AuthDriverStatusToggled(!state.driver.isOnline),
                          );
                        },
                        child: Text(
                          state.driver.isOnline ? AppStrings.goOffline : AppStrings.goOnline,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStateColor(AuthState state) {
    if (state is AuthAuthenticated) return AppColors.success;
    if (state is AuthUnauthenticated) return AppColors.warning;
    if (state is AuthError) return AppColors.error;
    if (state is AuthLoading) return AppColors.info;
    return AppColors.textSecondary;
  }
}

class _OrderTestSection extends StatelessWidget {
  const _OrderTestSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order BLoC',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceS),
                      decoration: BoxDecoration(
                        color: _getOrderStateColor(state).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        border: Border.all(color: _getOrderStateColor(state)),
                      ),
                      child: Text(
                        'State: ${state.runtimeType}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _getOrderStateColor(state),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    if (state is OrderAvailableLoaded) ...[
                      Text(
                        'Available Orders: ${state.orders.length}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                    ],
                    if (state is OrderActiveLoaded) ...[
                      Text(
                        'Active Orders: ${state.orders.length}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                    ],
                    if (state is OrderError) ...[
                      Text(
                        'Error: ${state.message}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: state is OrderLoading ? null : () {
                              context.orderBloc.add(const OrderLoadAvailable());
                            },
                            child: const Text('Load Available'),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceS),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state is OrderLoading ? null : () {
                              context.orderBloc.add(const OrderLoadActive());
                            },
                            child: const Text('Load Active'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: state is OrderLoading ? null : () {
                              context.orderBloc.add(const OrderLoadEarnings());
                            },
                            child: const Text('Load Earnings'),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceS),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state is OrderLoading ? null : () {
                              context.orderBloc.add(const OrderWatchAvailable());
                            },
                            child: const Text('Watch Orders'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getOrderStateColor(OrderState state) {
    if (state is OrderAvailableLoaded || state is OrderActiveLoaded) return AppColors.success;
    if (state is OrderEmpty) return AppColors.warning;
    if (state is OrderError) return AppColors.error;
    if (state is OrderLoading) return AppColors.info;
    return AppColors.textSecondary;
  }
}

class _LocationTestSection extends StatelessWidget {
  const _LocationTestSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location BLoC',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            BlocBuilder<LocationBloc, LocationState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceS),
                      decoration: BoxDecoration(
                        color: _getLocationStateColor(state).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        border: Border.all(color: _getLocationStateColor(state)),
                      ),
                      child: Text(
                        'State: ${state.runtimeType}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _getLocationStateColor(state),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    if (state is LocationLoaded) ...[
                      Text(
                        'Location: ${state.location.latitude.toStringAsFixed(4)}, ${state.location.longitude.toStringAsFixed(4)}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                    ],
                    if (state is LocationWatching) ...[
                      Text(
                        'Location: ${state.currentLocation.latitude.toStringAsFixed(4)}, ${state.currentLocation.longitude.toStringAsFixed(4)}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                    ],
                    if (state is LocationError) ...[
                      Text(
                        'Error: ${state.message}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceS),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: state is LocationLoading ? null : () {
                              context.locationBloc.add(const LocationCurrentRequested());
                            },
                            child: const Text('Get Location'),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceS),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state is LocationLoading ? null : () {
                              if (state is LocationWatching) {
                                context.locationBloc.add(const LocationWatchStopped());
                              } else {
                                context.locationBloc.add(const LocationWatchStarted());
                              }
                            },
                            child: Text(
                              state is LocationWatching ? 'Stop Watch' : 'Start Watch',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getLocationStateColor(LocationState state) {
    if (state is LocationLoaded || state is LocationWatching) return AppColors.success;
    if (state is LocationPermissionDenied || state is LocationServiceDisabled) return AppColors.warning;
    if (state is LocationError) return AppColors.error;
    if (state is LocationLoading) return AppColors.info;
    return AppColors.textSecondary;
  }
}*/
