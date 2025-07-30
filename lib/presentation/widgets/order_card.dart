import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/order_model.dart';
import 'status_chip.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final bool isAccepting;
  final bool isDeclining;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.isAccepting = false,
    this.isDeclining = false,
    required this.onAccept,
    required this.onDecline,
    required this.onTap,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isDisposed = false;

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
    _isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isAccepting && !widget.isDeclining && !_isDisposed) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isDisposed) {
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    if (!_isDisposed) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = widget.isAccepting || widget.isDeclining;

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
                color: isLoading
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.1),
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
                onTap: isLoading ? null : widget.onTap,
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isLoading ? 0.7 : 1.0,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spaceM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderHeader(),
                        const SizedBox(height: AppDimensions.spaceM),
                        _buildOrderDetails(),
                        const SizedBox(height: AppDimensions.spaceM),
                        _buildLocationInfo(),
                        const SizedBox(height: AppDimensions.spaceM),
                        _buildActionButtons(),
                      ],
                    ),
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
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: const Icon(
            Icons.restaurant,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.order.restaurantName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
              '${widget.order.estimatedTotalMinutes} min',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: AppDimensions.spaceS),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (widget.order.specialInstructions != null &&
              widget.order.specialInstructions!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spaceS),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Expanded(
                  child: Text(
                    widget.order.specialInstructions!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildLocationItem(
            icon: Icons.restaurant,
            label: 'Pickup',
            address: widget.order.restaurantAddress,
            distance: '${widget.order.distanceToRestaurant.toStringAsFixed(1)} km',
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: const Icon(
            Icons.arrow_forward,
            color: AppColors.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: _buildLocationItem(
            icon: Icons.home,
            label: 'Delivery',
            address: widget.order.customerAddress,
            distance: '${widget.order.distanceToCustomer.toStringAsFixed(1)} km',
          ),
        ),
      ],
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required String label,
    required String address,
    required String distance,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceS),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: AppDimensions.spaceXS),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                distance,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            address,
            style: AppTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool isLoading = widget.isAccepting || widget.isDeclining;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : widget.onDecline,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: widget.isDeclining
                    ? AppColors.error.withOpacity(0.5)
                    : AppColors.error,
              ),
            ),
            child: widget.isDeclining
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.close,
                  color: isLoading ? AppColors.textHint : AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: AppDimensions.spaceXS),
                Text(
                  'Decline',
                  style: TextStyle(
                    color: isLoading ? AppColors.textHint : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isLoading ? null : widget.onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isAccepting
                  ? AppColors.primary.withOpacity(0.7)
                  : AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
            child: widget.isAccepting
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
                  Icons.check_circle,
                  color: isLoading ? Colors.white54 : Colors.white,
                  size: 18,
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Text(
                  AppStrings.accept,
                  style: TextStyle(
                    color: isLoading ? Colors.white54 : Colors.white,
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
}



