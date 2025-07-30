import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/bloc_extensions.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../data/models/order_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/order/order_bloc.dart';
import '../../bloc/order/order_event.dart';
import '../../bloc/order/order_state.dart';
import '../../widgets/order_card.dart';
import 'order_details_screen.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen>
    with AutomaticKeepAliveClientMixin {
  String? _acceptingOrderId;
  String? _decliningOrderId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Set context first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.orderBloc.setCurrentContext(OrderViewContext.available);
    });
    _loadOrdersIfOnline();
  }

  @override
  void dispose() {
    // Clear context when leaving screen
    context.orderBloc.setCurrentContext(OrderViewContext.unknown);
    super.dispose();
  }

  void _loadOrdersIfOnline() {
    final authBloc = context.read<AuthBloc>();
    if (authBloc.isDriverOnline) {
      _loadOrders();
      _startWatchingOrders();
    }
  }

  void _loadOrders() {
    context.orderBloc.add(const OrderLoadAvailable());
  }

  void _startWatchingOrders() {
    context.orderBloc.add(const OrderWatchAvailable());
  }

  void _refreshOrders() {
    final authBloc = context.read<AuthBloc>();
    if (authBloc.isDriverOnline) {
      context.orderBloc.add(const OrderRefresh());
    } else {
      context.showInfoSnackBar('Please go online to view available orders');
    }
  }

  void _acceptOrder(String orderId) {
    final authBloc = context.read<AuthBloc>();
    if (!authBloc.isDriverOnline) {
      context.showErrorSnackBar('You must be online to accept orders');
      return;
    }

    if (_acceptingOrderId != null || _decliningOrderId != null) return;

    setState(() {
      _acceptingOrderId = orderId;
    });
    context.orderBloc.add(OrderAccept(orderId));
  }

  void _declineOrder(String orderId) {
    final authBloc = context.read<AuthBloc>();
    if (!authBloc.isDriverOnline) {
      context.showErrorSnackBar('You must be online to interact with orders');
      return;
    }

    if (_acceptingOrderId != null || _decliningOrderId != null) return;

    _showDeclineDialog(orderId);
  }

  void _showDeclineDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        String? selectedReason;
        final reasons = [
          'Too far from my location',
          'Restaurant wait time too long',
          'Order value too low',
          'Unsafe delivery area',
          'Already have enough orders',
          'Technical issue',
          'Other',
        ];

        return StatefulBuilder(
          builder: (context, setState) {
            return WillPopScope(
              onWillPop: () async => _decliningOrderId == null,
              child: AlertDialog(
                title: Text(
                  'Decline Order',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please select a reason for declining this order:',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    ...reasons.map((reason) => RadioListTile<String>(
                      title: Text(
                        reason,
                        style: AppTextStyles.bodySmall,
                      ),
                      value: reason,
                      groupValue: selectedReason,
                      onChanged: _decliningOrderId == null ? (value) {
                        setState(() {
                          selectedReason = value;
                        });
                      } : null,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    )),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: _decliningOrderId == null
                        ? () => Navigator.of(dialogContext).pop()
                        : null,
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: _decliningOrderId == null
                            ? AppColors.textSecondary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: (selectedReason != null && _decliningOrderId == null)
                        ? () {
                      Navigator.of(dialogContext).pop();
                      _performDecline(orderId, selectedReason!);
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    child: _decliningOrderId == orderId
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      'Decline',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _performDecline(String orderId, String reason) {
    setState(() {
      _decliningOrderId = orderId;
    });
    context.orderBloc.add(OrderDecline(orderId, reason: reason));
  }

  void _viewOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(order: order),
      ),
    );
  }

  void _goOnline() {
    final authBloc = context.read<AuthBloc>();
    authBloc.add(const AuthDriverStatusToggled(true));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.availableOrders),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final isOnline = authState is AuthAuthenticated ? authState.driver.isOnline : false;
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: isOnline ? _refreshOrders : null,
                color: isOnline ? null : AppColors.textHint,
              );
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<OrderBloc, OrderState>(
            listener: (context, state) {
              if (state is OrderAccepted) {
                setState(() {
                  _acceptingOrderId = null;
                });
                context.showSuccessSnackBar('Order accepted successfully');

                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    context.orderBloc.setCurrentContext(OrderViewContext.available);
                  }
                });

              } else if (state is OrderDeclined) {
                setState(() {
                  _decliningOrderId = null;
                });
                context.showInfoSnackBar('Order declined');

              } else if (state is OrderError) {
                setState(() {
                  _acceptingOrderId = null;
                  _decliningOrderId = null;
                });
                context.showErrorSnackBar(state.message);
              }
            },
          ),
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                // When driver goes online, load orders
                if (state.driver.isOnline) {
                  _loadOrdersIfOnline();
                }
              }
            },
          ),
        ],
        child: RefreshIndicator(
          onRefresh: () async {
            _refreshOrders();
            await Future.delayed(const Duration(seconds: 1));
          },
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          final driver = authState.driver;

          // If driver is offline, show offline state
          if (!driver.isOnline) {
            return _buildOfflineState();
          }

          // If driver is online, show orders
          return BlocBuilder<OrderBloc, OrderState>(
            buildWhen: (previous, current) {
              if (current is OrderLoading ||
                  current is OrderAvailableLoaded ||
                  current is OrderEmpty ||
                  current is OrderError) {
                return true;
              }

              if (current is OrderAccepting || current is OrderDeclining) {
                return false;
              }

              if (current is OrderAccepted || current is OrderDeclined) {
                return true;
              }

              return false;
            },
            builder: (context, orderState) {
              if (orderState is OrderLoading && _acceptingOrderId == null && _decliningOrderId == null) {
                return const Center(
                  child: LoadingWidget(message: 'Loading available orders...'),
                );
              } else if (orderState is OrderAvailableLoaded) {
                return _buildOrdersList(orderState.orders);
              } else if (orderState is OrderEmpty) {
                return _buildEmptyState(orderState.message);
              } else if (orderState is OrderError) {
                return _buildErrorState(orderState.message);
              } else {
                final bloc = context.read<OrderBloc>();
                if (bloc.cachedAvailableOrders == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _loadOrders();
                    }
                  });
                  return const Center(
                    child: LoadingWidget(message: 'Loading available orders...'),
                  );
                } else {
                  return bloc.cachedAvailableOrders!.isEmpty
                      ? _buildEmptyState('No orders available at the moment')
                      : _buildOrdersList(bloc.cachedAvailableOrders!);
                }
              }
            },
          );
        }

        // If not authenticated, show loading
        return const Center(
          child: LoadingWidget(message: 'Loading...'),
        );
      },
    );
  }

  Widget _buildOfflineState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceXL),
              decoration: BoxDecoration(
                color: AppColors.textHint.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off,
                size: 64,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              'You are Offline',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'You need to be online to view and accept delivery orders. Go online to start receiving orders.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isUpdating = state is AuthStatusUpdating;
                return ElevatedButton.icon(
                  onPressed: isUpdating ? null : _goOnline,
                  icon: isUpdating
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.wifi),
                  label: Text(isUpdating ? 'Going Online...' : 'Go Online'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceXL,
                      vertical: AppDimensions.spaceM,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState('No orders available at the moment');
    }

    return Column(
      children: [
        _buildHeader(orders.length),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: AppDimensions.spaceS,
              bottom: AppDimensions.spaceXL,
            ),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final isAccepting = _acceptingOrderId == order.id;
              final isDeclining = _decliningOrderId == order.id;
              final isLoading = isAccepting || isDeclining;

              return OrderCard(
                key: ValueKey(order.id),
                order: order,
                isAccepting: isAccepting,
                isDeclining: isDeclining,
                onAccept: isLoading ? () {} : () => _acceptOrder(order.id),
                onDecline: isLoading ? () {} : () => _declineOrder(order.id),
                onTap: isLoading ? () {} : () => _viewOrderDetails(order),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(int orderCount) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceS),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$orderCount Orders Available',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  orderCount > 0
                      ? 'Tap to view details, swipe to refresh'
                      : 'Pull down to refresh and check for new orders',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (orderCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceS,
                vertical: AppDimensions.spaceXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceXS),
                  Text(
                    'LIVE',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceXL),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              'No Orders Available',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            TextButton.icon(
              onPressed: _refreshOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Check for New Orders'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceXL),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              'Something went wrong',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            ElevatedButton.icon(
              onPressed: _refreshOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

