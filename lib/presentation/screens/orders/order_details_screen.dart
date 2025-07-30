import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/bloc_extensions.dart';
import '../../../data/models/order_model.dart';
import '../../bloc/order/order_bloc.dart';
import '../../bloc/order/order_event.dart';
import '../../bloc/order/order_state.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/order_item_tile.dart';
import '../navigation/navigation_screen.dart';
class OrderDetailsScreen extends StatefulWidget {
  final Order order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Order _currentOrder;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _watchOrderStatus();
  }

  void _watchOrderStatus() {
    context.orderBloc.add(OrderWatchStatus(widget.order.id));
  }

  void _updateOrderStatus(OrderStatus status) {
    setState(() {
      _isUpdatingStatus = true;
    });
    context.orderBloc.add(
      OrderUpdateStatus(orderId: _currentOrder.id, status: status),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        context.showErrorSnackBar('Could not make phone call');
      }
    }
  }

  void _openMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse('https://maps.google.com/search/$encodedAddress');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        context.showErrorSnackBar('Could not open maps');
      }
    }
  }
  void _startNavigation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationScreen(order: _currentOrder),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #${_currentOrder.id.substring(0, 8)}'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderStatusUpdated && state.order.id == _currentOrder.id) {
            setState(() {
              _currentOrder = state.order;
              _isUpdatingStatus = false;
            });

          } else if (state is OrderError) {
            setState(() {
              _isUpdatingStatus = false;
            });
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildStatusHeader(),
              _buildLocationSection(),
              _buildOrderItemsSection(),
              _buildOrderSummarySection(),
              _buildContactSection(),
              _buildActionsSection(),
              const SizedBox(height: AppDimensions.spaceXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        children: [
          StatusChip(status: _currentOrder.status, isLarge: true),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            _currentOrder.restaurantName,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            'Order #${_currentOrder.id.substring(0, 8)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickStat(
                'Value',
                '\$${_currentOrder.totalAmount.toStringAsFixed(2)}',
                AppColors.primary,
              ),
              _buildQuickStat(
                'Earning',
                '\$${_currentOrder.driverEarning.toStringAsFixed(2)}',
                AppColors.success,
              ),
              _buildQuickStat(
                'Time',
                '${_currentOrder.estimatedTotalMinutes} min',
                AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Text(
              'Locations',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildLocationTile(
            icon: Icons.restaurant,
            title: AppStrings.pickupLocation,
            name: _currentOrder.restaurantName,
            address: _currentOrder.restaurantAddress,
            distance: '${_currentOrder.distanceToRestaurant.toStringAsFixed(1)} km',
            phone: _currentOrder.restaurantPhone,
            onDirections: () => _openMaps(_currentOrder.restaurantAddress),
            onCall: _currentOrder.restaurantPhone != null
                ? () => _makePhoneCall(_currentOrder.restaurantPhone!)
                : null,
          ),
          const Divider(height: 1),
          _buildLocationTile(
            icon: Icons.home,
            title: AppStrings.deliveryLocation,
            name: _currentOrder.customerName,
            address: _currentOrder.customerAddress,
            distance: '${_currentOrder.distanceToCustomer.toStringAsFixed(1)} km',
            phone: _currentOrder.customerPhone,
            onDirections: () => _openMaps(_currentOrder.customerAddress),
            onCall: () => _makePhoneCall(_currentOrder.customerPhone),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile({
    required IconData icon,
    required String title,
    required String name,
    required String address,
    required String distance,
    String? phone,
    VoidCallback? onDirections,
    VoidCallback? onCall,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceS),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  icon,
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
                      title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceS,
                  vertical: AppDimensions.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  distance,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            address,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: AppStrings.getDirections,
                  onPressed: onDirections,
                  variant: ButtonVariant.outline,
                  size: ButtonSize.small,
                  prefixIcon: const Icon(
                    Icons.directions,
                    size: 16,
                  ),
                ),
              ),
              if (onCall != null) ...[
                const SizedBox(width: AppDimensions.spaceS),
                CustomButton(
                  text: AppStrings.call,
                  onPressed: onCall,
                  variant: ButtonVariant.primary,
                  size: ButtonSize.small,
                  prefixIcon: const Icon(
                    Icons.phone,
                    color: AppColors.surface,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Row(
              children: [
                Text(
                  AppStrings.orderItems,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceS,
                    vertical: AppDimensions.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Text(
                    '${_currentOrder.items.length} items',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._currentOrder.items.map((item) => OrderItemTile(item: item)),
          if (_currentOrder.specialInstructions != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.specialInstructions,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceS),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.spaceM),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Text(
                      _currentOrder.specialInstructions!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.warning,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummarySection() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            _buildSummaryRow('Subtotal', '\$${_currentOrder.totalAmount.toStringAsFixed(2)}'),
            _buildSummaryRow('Delivery Fee', '\$${_currentOrder.deliveryFee.toStringAsFixed(2)}'),
            const Divider(),
            _buildSummaryRow(
              'Your Earning',
              '\$${_currentOrder.driverEarning.toStringAsFixed(2)}',
              isTotal: true,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (isTotal ? AppTextStyles.bodyMedium : AppTextStyles.bodyMedium).copyWith(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: color ?? AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: (isTotal ? AppTextStyles.headlineSmall : AppTextStyles.bodyMedium).copyWith(
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Call Restaurant',
                    onPressed: _currentOrder.restaurantPhone != null
                        ? () => _makePhoneCall(_currentOrder.restaurantPhone!)
                        : null,
                    variant: ButtonVariant.outline,
                    prefixIcon: const Icon(Icons.restaurant),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: CustomButton(
                    text: 'Call Customer',
                    onPressed: () => _makePhoneCall(_currentOrder.customerPhone),
                    variant: ButtonVariant.primary,
                    prefixIcon: const Icon(
                      Icons.phone,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.spaceM),
      child: Column(
        children: [
          // Navigation button for accepted orders
          if (_currentOrder.status == OrderStatus.accepted) ...[
            CustomButton(
              text: 'Start Navigation',
              onPressed: _startNavigation,
              variant: ButtonVariant.primary,
              size: ButtonSize.large,
              isExpanded: true,
              prefixIcon: const Icon(
                Icons.navigation,
                color: AppColors.surface,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            CustomButton(
              text: AppStrings.pickupOrder,
              onPressed: _isUpdatingStatus
                  ? null
                  : () => _updateOrderStatus(OrderStatus.pickedUp),
              variant: ButtonVariant.outline,
              size: ButtonSize.large,
              isExpanded: true,
              isLoading: _isUpdatingStatus,
              prefixIcon: !_isUpdatingStatus
                  ? const Icon(Icons.shopping_bag)
                  : null,
            ),
          ],

          // Navigation for picked up orders
          if (_currentOrder.status == OrderStatus.pickedUp) ...[
            CustomButton(
              text: 'Navigate to Customer',
              onPressed: _startNavigation,
              variant: ButtonVariant.primary,
              size: ButtonSize.large,
              isExpanded: true,
              prefixIcon: const Icon(
                Icons.navigation,
                color: AppColors.surface,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            CustomButton(
              text: 'Start Delivery',
              onPressed: _isUpdatingStatus
                  ? null
                  : () => _updateOrderStatus(OrderStatus.inTransit),
              variant: ButtonVariant.outline,
              size: ButtonSize.large,
              isExpanded: true,
              isLoading: _isUpdatingStatus,
              prefixIcon: !_isUpdatingStatus
                  ? const Icon(Icons.directions_car)
                  : null,
            ),
          ],

          // Navigation for in-transit orders
          if (_currentOrder.status == OrderStatus.inTransit) ...[
            CustomButton(
              text: 'Continue Navigation',
              onPressed: _startNavigation,
              variant: ButtonVariant.primary,
              size: ButtonSize.large,
              isExpanded: true,
              prefixIcon: const Icon(
                Icons.navigation,
                color: AppColors.surface,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            CustomButton(
              text: AppStrings.markDelivered,
              onPressed: _isUpdatingStatus
                  ? null
                  : () => _updateOrderStatus(OrderStatus.delivered),
              variant: ButtonVariant.outline,
              size: ButtonSize.large,
              isExpanded: true,
              isLoading: _isUpdatingStatus,
              prefixIcon: !_isUpdatingStatus
                  ? const Icon(Icons.check_circle)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}