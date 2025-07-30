import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/order_model.dart';

class NavigationBottomSheet extends StatefulWidget {
  final Order order;
  final String currentStep;
  final String timeRemaining;
  final String distanceRemaining;
  final bool isLoading;
  final VoidCallback? onCallCustomer;
  final VoidCallback? onCallRestaurant;
  final VoidCallback? onNextStep;
  final VoidCallback? onCenterMap;
  final String? nextStepText;

  const NavigationBottomSheet({
    super.key,
    required this.order,
    required this.currentStep,
    required this.timeRemaining,
    required this.distanceRemaining,
    required this.isLoading,
    this.onCallCustomer,
    this.onCallRestaurant,
    this.onNextStep,
    this.onCenterMap,
    this.nextStepText,
  });

  @override
  State<NavigationBottomSheet> createState() => _NavigationBottomSheetState();
}

class _NavigationBottomSheetState extends State<NavigationBottomSheet>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppDimensions.spaceS),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Main content
          GestureDetector(
            onTap: _toggleExpanded,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spaceS),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceM),

                      // Order info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.currentStep,
                              style: AppTextStyles.headlineSmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _getCurrentDestinationText(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Expand indicator
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.spaceM),

                  // Time and distance row
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.access_time,
                        label: 'ETA',
                        value: widget.timeRemaining,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppDimensions.spaceM),
                      _buildInfoChip(
                        icon: Icons.straighten,
                        label: 'Distance',
                        value: widget.distanceRemaining,
                        color: AppColors.success,
                      ),
                      const Spacer(),
                      _buildInfoChip(
                        icon: Icons.local_shipping,
                        label: 'Order',
                        value: '#${widget.order.id.substring(0, 6)}',
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _animation,
                child: Container(
                  padding: const EdgeInsets.only(
                    left: AppDimensions.spaceL,
                    right: AppDimensions.spaceL,
                    bottom: AppDimensions.spaceL,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: AppDimensions.spaceS),

                      // Order details
                      _buildOrderDetails(),

                      const SizedBox(height: AppDimensions.spaceL),

                      // Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              );
            },
          ),

          // Always visible action button
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Row(
              children: [
                // Secondary actions
                if (widget.onCallRestaurant != null && widget.order.status == OrderStatus.accepted)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onCallRestaurant,
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                if (widget.onCallCustomer != null &&
                    (widget.order.status == OrderStatus.pickedUp || widget.order.status == OrderStatus.inTransit))
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onCallCustomer,
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Call '),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                if ((widget.onCallRestaurant != null && widget.order.status == OrderStatus.accepted) ||
                    (widget.onCallCustomer != null &&
                        (widget.order.status == OrderStatus.pickedUp || widget.order.status == OrderStatus.inTransit)))
                  const SizedBox(width: AppDimensions.spaceM),

                // Primary action
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: widget.isLoading ? null : widget.onNextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getStatusColor(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      ),
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      widget.nextStepText ?? 'Next Step',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Details',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),

        // Order items
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    widget.order.status == OrderStatus.accepted
                        ? Icons.restaurant
                        : Icons.home,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppDimensions.spaceS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order.status == OrderStatus.accepted
                              ? widget.order.restaurantName
                              : widget.order.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.order.status == OrderStatus.accepted
                              ? widget.order.restaurantAddress
                              : widget.order.customerAddress,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Row(
                children: [
                  Text(
                    '${widget.order.items.length} items',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${widget.order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Special instructions
        if (widget.order.specialInstructions != null &&
            widget.order.specialInstructions!.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spaceM),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Special Instructions',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        widget.order.specialInstructions!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onCenterMap,
            icon: const Icon(Icons.my_location, size: 18),
            label: const Text('Center Map'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Add navigation to external map app
              _launchExternalNavigation();
            },
            icon: const Icon(Icons.navigation, size: 18),
            label: const Text('External GPS'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _launchExternalNavigation() {
    final destination = widget.order.status == OrderStatus.accepted
        ? widget.order.restaurantLocation
        : widget.order.customerLocation;

    // This would launch external navigation app
    // Implementation depends on your requirements
    print('Launch external navigation to: ${destination.latitude}, ${destination.longitude}');
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
        return Icons.local_shipping;
      case OrderStatus.inTransit:
        return Icons.navigation;
      default:
        return Icons.info;
    }
  }

  String _getCurrentDestinationText() {
    switch (widget.order.status) {
      case OrderStatus.accepted:
        return 'Pick up from ${widget.order.restaurantName}';
      case OrderStatus.pickedUp:
      case OrderStatus.inTransit:
        return 'Deliver to ${widget.order.customerName}';
      default:
        return 'Order navigation';
    }
  }
}


