import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/bloc_extensions.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../data/models/order_model.dart';
import '../../bloc/order/order_bloc.dart';
import '../../bloc/order/order_event.dart';
import '../../bloc/order/order_state.dart';
import '../../widgets/status_chip.dart';
import '../navigation/navigation_screen.dart';
import 'order_details_screen.dart';

class ActiveOrdersScreen extends StatefulWidget {
  const ActiveOrdersScreen({super.key});

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen>
    with AutomaticKeepAliveClientMixin {
  String? _updatingOrderId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Set context first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.orderBloc.setCurrentContext(OrderViewContext.active);
    });
    _loadActiveOrders();
  }

  @override
  void dispose() {
    // Clear context when leaving screen
    context.orderBloc.setCurrentContext(OrderViewContext.unknown);
    super.dispose();
  }

  void _loadActiveOrders() {
    context.orderBloc.add(const OrderLoadActive());
  }

  void _refreshOrders() {
    context.orderBloc.add(const OrderRefresh());
  }

  void _updateOrderStatus(String orderId, OrderStatus newStatus) {
    if (_updatingOrderId != null) return; // Prevent multiple updates

    setState(() {
      _updatingOrderId = orderId;
    });

    // Add a small delay to show loading state
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.orderBloc.add(
          OrderUpdateStatus(orderId: orderId, status: newStatus),
        );
      }
    });
  }

  void _startNavigation(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationScreen(order: order),
      ),
    );
  }

  void _viewOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Active Orders'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderStatusUpdated) {
            setState(() {
              _updatingOrderId = null;
            });

            // Show success message based on the status
            String message = 'Order status updated successfully!';
            if (state.order.status == OrderStatus.pickedUp) {
              message = 'Order picked up successfully! 📦';
            } else if (state.order.status == OrderStatus.inTransit) {
              message = 'Delivery started! 🚗';
            } else if (state.order.status == OrderStatus.delivered) {
              message = 'Order delivered successfully! 🎉';
            }

            // context.showSuccessSnackBar(message);

            // Refresh the active orders list after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.orderBloc.setCurrentContext(OrderViewContext.active);
                // Only force reload if order was delivered (moved to history)
                if (state.order.status == OrderStatus.delivered) {
                  context.orderBloc.add(const OrderLoadActive(forceReload: true));
                }
              }
            });

          } else if (state is OrderError) {
            setState(() {
              _updatingOrderId = null;
            });
            context.showErrorSnackBar('Failed to update order status. Please try again.');

          } else if (state is OrderStatusUpdating && state.orderId == _updatingOrderId) {
            // Keep loading state active
          }
        },
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
    return BlocBuilder<OrderBloc, OrderState>(
      buildWhen: (previous, current) {
        // Only rebuild when the state actually changes for active orders
        if (current is OrderActiveLoaded ||
            (current is OrderEmpty && current.message.contains('active')) ||
            (current is OrderError && previous is! OrderError) ||
            (current is OrderLoading && previous is! OrderLoading)) {
          return true;
        }

        // Don't rebuild for status updating states to prevent flicker
        if (current is OrderStatusUpdating) {
          return false;
        }

        // Rebuild when status is updated
        if (current is OrderStatusUpdated) {
          return true;
        }

        return false;
      },
      builder: (context, state) {
        if (state is OrderLoading && _updatingOrderId == null) {
          return const Center(
            child: LoadingWidget(message: 'Loading active orders...'),
          );
        } else if (state is OrderActiveLoaded) {
          return _buildActiveOrdersList(state.orders);
        } else if (state is OrderEmpty && state.message.contains('active')) {
          return _buildEmptyState(state.message);
        } else if (state is OrderError) {
          return _buildErrorState(state.message);
        } else {
          // Handle initial state or use cached data
          final bloc = context.read<OrderBloc>();
          if (bloc.cachedActiveOrders == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _loadActiveOrders();
              }
            });
            return const Center(
              child: LoadingWidget(message: 'Loading active orders...'),
            );
          } else {
            // Use cached data
            return bloc.cachedActiveOrders!.isEmpty
                ? _buildEmptyState('No active orders')
                : _buildActiveOrdersList(bloc.cachedActiveOrders!);
          }
        }
      },
    );
  }

  Widget _buildActiveOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState('No active orders');
    }

    // Sort orders by status priority and creation time
    final sortedOrders = List<Order>.from(orders)
      ..sort((a, b) {
        // First sort by status priority
        final statusPriority = {
          OrderStatus.inTransit: 0,
          OrderStatus.pickedUp: 1,
          OrderStatus.accepted: 2,
        };

        final aPriority = statusPriority[a.status] ?? 3;
        final bPriority = statusPriority[b.status] ?? 3;

        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }

        // Then sort by creation time (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });

    return Column(
      children: [
        _buildHeader(orders.length),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: AppDimensions.spaceS,
              bottom: AppDimensions.spaceXL,
            ),
            itemCount: sortedOrders.length,
            itemBuilder: (context, index) {
              final order = sortedOrders[index];
              final isUpdating = _updatingOrderId == order.id;

              return ActiveOrderCard(
                key: ValueKey(order.id), // Add key for better performance
                order: order,
                isUpdating: isUpdating,
                onStatusUpdate: isUpdating
                    ? (newStatus) {} // Disable callback during update
                    : (newStatus) => _updateOrderStatus(order.id, newStatus),
                onNavigate: isUpdating
                    ? () {} // Disable navigation during update
                    : () => _startNavigation(order),
                onViewDetails: isUpdating
                    ? () {} // Disable view details during update
                    : () => _viewOrderDetails(order),
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
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: const Icon(
              Icons.assignment,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$orderCount Active ${orderCount == 1 ? 'Order' : 'Orders'}',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  orderCount > 0
                      ? 'Complete these orders to earn more'
                      : 'No active orders at the moment',
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
                    'IN PROGRESS',
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
                color: AppColors.info.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 64,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              'No Active Orders',
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
              label: const Text('Refresh'),
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              'Go to Available Orders to accept new deliveries',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
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


class ActiveOrderCard extends StatefulWidget {
  final Order order;
  final bool isUpdating;
  final Function(OrderStatus) onStatusUpdate;
  final VoidCallback onNavigate;
  final VoidCallback onViewDetails;

  const ActiveOrderCard({
    super.key,
    required this.order,
    required this.isUpdating,
    required this.onStatusUpdate,
    required this.onNavigate,
    required this.onViewDetails,
  });

  @override
  State<ActiveOrderCard> createState() => _ActiveOrderCardState();
}

class _ActiveOrderCardState extends State<ActiveOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceM,
              vertical: AppDimensions.spaceS,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: _getStatusColor().withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textHint.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onViewDetails,
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spaceM),
                  child: Column(
                    children: [
                      _buildOrderHeader(),
                      const SizedBox(height: AppDimensions.spaceM),
                      _buildProgressIndicator(),
                      const SizedBox(height: AppDimensions.spaceM),
                      _buildOrderInfo(),
                      const SizedBox(height: AppDimensions.spaceM),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceS),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 20,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.order.restaurantName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceS),
                  StatusChip(status: widget.order.status),
                ],
              ),
              Text(
                'Order #${widget.order.id.substring(0, 8)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${widget.order.driverEarning.toStringAsFixed(2)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _getEstimatedTimeText(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final steps = [
      {'status': OrderStatus.accepted, 'label': 'Accepted', 'icon': Icons.check_circle},
      {'status': OrderStatus.pickedUp, 'label': 'Picked Up', 'icon': Icons.shopping_bag},
      {'status': OrderStatus.inTransit, 'label': 'In Transit', 'icon': Icons.local_shipping},
      {'status': OrderStatus.delivered, 'label': 'Delivered', 'icon': Icons.flag},
    ];

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final status = step['status'] as OrderStatus;
        final isActive = _getStatusIndex(widget.order.status) >= _getStatusIndex(status);
        final isCurrent = widget.order.status == status;

        return Expanded(
          child: Row(
            children: [
              // Step indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? _getStatusColor() : AppColors.textHint.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: isCurrent ? Border.all(color: _getStatusColor(), width: 2) : null,
                ),
                child: Icon(
                  step['icon'] as IconData,
                  color: isActive ? AppColors.surface : AppColors.textHint,
                  size: 16,
                ),
              ),

              // Connecting line (except for last step)
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isActive ? _getStatusColor() : AppColors.textHint.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Column(
        children: [
          // Current destination
          Row(
            children: [
              Icon(
                _getCurrentDestinationIcon(),
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spaceS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCurrentDestinationLabel(),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _getCurrentDestinationName(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getCurrentDestinationAddress(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${_getCurrentDistance().toStringAsFixed(1)} km',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spaceS),

          // Order summary
          Row(
            children: [
              Text(
                '${widget.order.items.length} items',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Total: \$${widget.order.totalAmount.toStringAsFixed(2)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onNavigate,
            icon: const Icon(Icons.navigation, size: 18),
            label: const Text('Navigate'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: ElevatedButton(
            onPressed: _canUpdateStatus() ? () => _updateStatus() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canUpdateStatus() ? _getStatusColor() : AppColors.textHint.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
            child: widget.isUpdating
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getNextStatusIcon(),
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Text(
                  _getNextStatusText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _updateStatus() {
    final nextStatus = _getNextStatus();
    if (nextStatus != null && !widget.isUpdating) {
      widget.onStatusUpdate(nextStatus);
    }
  }

  OrderStatus? _getNextStatus() {
    switch (widget.order.status) {
      case OrderStatus.accepted:
        return OrderStatus.pickedUp;
      case OrderStatus.pickedUp:
        return OrderStatus.inTransit;
      case OrderStatus.inTransit:
        return OrderStatus.delivered;
      default:
        return null;
    }
  }

  String _getNextStatusText() {
    switch (widget.order.status) {
      case OrderStatus.accepted:
        return 'Pick Up Order';
      case OrderStatus.pickedUp:
        return 'Start Delivery';
      case OrderStatus.inTransit:
        return 'Mark Delivered';
      default:
        return 'Complete';
    }
  }

  IconData _getNextStatusIcon() {
    switch (widget.order.status) {
      case OrderStatus.accepted:
        return Icons.shopping_bag;
      case OrderStatus.pickedUp:
        return Icons.local_shipping;
      case OrderStatus.inTransit:
        return Icons.flag;
      default:
        return Icons.check;
    }
  }

  bool _canUpdateStatus() {
    return _getNextStatus() != null && !widget.isUpdating;
  }

  Color _getStatusColor() {
    switch (widget.order.status) {
      case OrderStatus.accepted:
        return AppColors.warning;
      case OrderStatus.pickedUp:
        return AppColors.primary;
      case OrderStatus.inTransit:
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.order.status) {
      case OrderStatus.accepted:
        return Icons.restaurant;
      case OrderStatus.pickedUp:
        return Icons.shopping_bag;
      case OrderStatus.inTransit:
        return Icons.local_shipping;
      default:
        return Icons.info;
    }
  }

  int _getStatusIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return 0;
      case OrderStatus.pickedUp:
        return 1;
      case OrderStatus.inTransit:
        return 2;
      case OrderStatus.delivered:
        return 3;
      default:
        return -1;
    }
  }

  IconData _getCurrentDestinationIcon() {
    switch (widget.order.status) {
      case OrderStatus.accepted:
        return Icons.restaurant;
      case OrderStatus.pickedUp:
      case OrderStatus.inTransit:
        return Icons.home;
      default:
        return Icons.location_on;
    }
  }

  String _getCurrentDestinationLabel() {
    switch (widget.order.status) {
      case OrderStatus.accepted:
        return 'Pickup from';
      case OrderStatus.pickedUp:
      case OrderStatus.inTransit:
        return 'Deliver to';
      default:
        return 'Location';
    }
  }

  String _getCurrentDestinationName() {
    switch (widget.order.status) {
      case OrderStatus.accepted:
        return widget.order.restaurantName;
      case OrderStatus.pickedUp:
      case OrderStatus.inTransit:
        return widget.order.customerName;
      default:
        return 'Unknown';
    }
  }

  String _getCurrentDestinationAddress() {
    switch (widget.order.status) {
      case OrderStatus.accepted:
        return widget.order.restaurantAddress;
      case OrderStatus.pickedUp:
      case OrderStatus.inTransit:
        return widget.order.customerAddress;
      default:
        return 'Unknown address';
    }
  }

  double _getCurrentDistance() {
    switch (widget.order.status) {
      case OrderStatus.accepted:
        return widget.order.distanceToRestaurant;
      case OrderStatus.pickedUp:
      case OrderStatus.inTransit:
        return widget.order.distanceToCustomer;
      default:
        return 0.0;
    }
  }

  String _getEstimatedTimeText() {
    final now = DateTime.now();
    final estimatedTime = widget.order.status == OrderStatus.accepted
        ? widget.order.estimatedPickupTime
        : widget.order.estimatedDeliveryTime;

    final difference = estimatedTime.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m left';
    } else {
      return '${difference.inHours}h ${difference.inMinutes % 60}m left';
    }
  }
}




