import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/bloc_extensions.dart';
import '../../../data/models/order_model.dart';
import '../../bloc/location/location_bloc.dart';
import '../../bloc/location/location_event.dart';
import '../../bloc/location/location_state.dart';
import '../../bloc/order/order_bloc.dart';
import '../../bloc/order/order_event.dart';
import '../../bloc/order/order_state.dart';
import '../../widgets/map_widget.dart';
import '../../widgets/navigation_bottom_sheet.dart';

class NavigationScreen extends StatefulWidget {
  final Order order;

  const NavigationScreen({
    super.key,
    required this.order,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  late Order _currentOrder;
  GoogleMapController? _mapController;
  StreamSubscription<LatLng>? _locationSubscription;
  LatLng? _currentLocation;
  List<LatLng> _route = [];
  bool _isUpdatingStatus = false;
  bool _isLoadingRoute = false;
  String _timeRemaining = '-- min';
  String _distanceRemaining = '-- km';
  Timer? _routeUpdateTimer;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _initializeNavigation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _routeUpdateTimer?.cancel();
    super.dispose();
  }

  void _initializeNavigation() {
    // Start location tracking
    context.locationBloc.add(const LocationWatchStarted());

    // Watch for order status updates
    context.orderBloc.add(OrderWatchStatus(_currentOrder.id));

    // Start periodic route updates
    _startRouteUpdateTimer();
  }

  void _startRouteUpdateTimer() {
    _routeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentLocation != null) {
        _getRoute();
      }
    });
  }

  void _getRoute() {
    final destination = _getCurrentDestination();
    if (destination != null && _currentLocation != null) {
      setState(() {
        _isLoadingRoute = true;
      });

      // Get route
      context.locationBloc.add(
        LocationRouteRequested(start: _currentLocation!, end: destination),
      );

      // Get ETA
      context.locationBloc.add(
        LocationEtaRequested(start: _currentLocation!, end: destination),
      );

      // Get distance
      context.locationBloc.add(
        LocationDistanceRequested(start: _currentLocation!, end: destination),
      );
    }
  }

  LatLng? _getCurrentDestination() {
    switch (_currentOrder.status) {
      case OrderStatus.accepted:
        return _currentOrder.restaurantLocation;
      case OrderStatus.pickedUp:
      case OrderStatus.inTransit:
        return _currentOrder.customerLocation;
      default:
        return null;
    }
  }

  String _getCurrentStepText() {
    switch (_currentOrder.status) {
      case OrderStatus.accepted:
        return 'Navigate to Restaurant';
      case OrderStatus.pickedUp:
        return 'Navigate to Customer';
      case OrderStatus.inTransit:
        return 'Delivering Order';
      default:
        return 'Navigation';
    }
  }

  String _getCurrentInstructions() {
    switch (_currentOrder.status) {
      case OrderStatus.accepted:
        return 'Head to ${_currentOrder.restaurantName} to pick up the order';
      case OrderStatus.pickedUp:
        return 'Deliver order to ${_currentOrder.customerName}';
      case OrderStatus.inTransit:
        return 'You\'re on your way to deliver the order';
      default:
        return 'Follow the route on the map';
    }
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

  void _centerMapOnCurrentLocation() {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation!, zoom: 16.0),
        ),
      );
    }
  }

  void _centerMapOnRoute() {
    if (_route.isNotEmpty && _mapController != null) {
      // Calculate bounds for the entire route
      double minLat = _route.first.latitude;
      double maxLat = _route.first.latitude;
      double minLng = _route.first.longitude;
      double maxLng = _route.first.longitude;

      for (final point in _route) {
        minLat = minLat < point.latitude ? minLat : point.latitude;
        maxLat = maxLat > point.latitude ? maxLat : point.latitude;
        minLng = minLng < point.longitude ? minLng : point.longitude;
        maxLng = maxLng > point.longitude ? maxLng : point.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat - 0.001, minLng - 0.001),
        northeast: LatLng(maxLat + 0.001, maxLng + 0.001),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  OrderStatus _getNextStatus() {
    switch (_currentOrder.status) {
      case OrderStatus.accepted:
        return OrderStatus.pickedUp;
      case OrderStatus.pickedUp:
        return OrderStatus.inTransit;
      case OrderStatus.inTransit:
        return OrderStatus.delivered;
      default:
        return _currentOrder.status;
    }
  }

  String _getNextStatusText() {
    switch (_currentOrder.status) {
      case OrderStatus.accepted:
        return 'Mark as Picked Up';
      case OrderStatus.pickedUp:
        return 'Start Delivery';
      case OrderStatus.inTransit:
        return 'Mark as Delivered';
      default:
        return 'Update Status';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #${_currentOrder.id.substring(0, 8)}'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (_isLoadingRoute)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: _centerMapOnRoute,
            tooltip: 'Show full route',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerMapOnCurrentLocation,
            tooltip: 'Center on location',
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<LocationBloc, LocationState>(
            listener: (context, state) {
              if (state is LocationWatching || state is LocationUpdated) {
                final location = state is LocationWatching
                    ? state.currentLocation
                    : (state as LocationUpdated).location;

                setState(() {
                  _currentLocation = location;
                });

                // Update route when location changes significantly
                if (_route.isEmpty) {
                  _getRoute();
                }
              } else if (state is LocationRouteLoaded) {
                setState(() {
                  _route = state.route;
                  _isLoadingRoute = false;
                });

                // Show success message for route loading
                if (mounted) {
                  context.showSuccessSnackBar('Route updated');
                }
              } else if (state is LocationEtaCalculated) {
                setState(() {
                  _timeRemaining = '${state.eta} min';
                });
              } else if (state is LocationDistanceCalculated) {
                setState(() {
                  _distanceRemaining = '${state.distance.toStringAsFixed(1)} km';
                });
              } else if (state is LocationError) {
                setState(() {
                  _isLoadingRoute = false;
                });
                context.showErrorSnackBar('Failed to load route: ${state.message}');
              }
            },
          ),
          BlocListener<OrderBloc, OrderState>(
            listener: (context, state) {
              if (state is OrderStatusUpdated && state.order.id == _currentOrder.id) {
                setState(() {
                  _currentOrder = state.order;
                  _isUpdatingStatus = false;
                });

                if (state.order.status == OrderStatus.delivered) {
                  // Order completed, return to previous screen
                  Navigator.pop(context);

                } else {

                  // Get new route for next destination
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _getRoute();
                  });
                }
              } else if (state is OrderError) {
                setState(() {
                  _isUpdatingStatus = false;
                });
                context.showErrorSnackBar(state.message);
              }
            },
          ),
        ],
        child: Stack(
          children: [
            // Map
            MapWidget(
              initialLocation: _currentLocation,
              order: _currentOrder,
              route: _route,
              showUserLocation: true,
              showRoute: _route.isNotEmpty,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),

            // Route instructions card
            if (_route.isNotEmpty)
              Positioned(
                top: AppDimensions.spaceM,
                left: AppDimensions.spaceM,
                right: AppDimensions.spaceM,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceM),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textHint.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                            ),
                            child: const Icon(
                              Icons.navigation,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceS),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getCurrentStepText(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _getCurrentInstructions(),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spaceS,
                              vertical: AppDimensions.spaceXS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _timeRemaining,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceS),
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
                                const Icon(
                                  Icons.straighten,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _distanceRemaining,
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Navigation bottom sheet
            Align(
              alignment: Alignment.bottomCenter,
              child: NavigationBottomSheet(
                order: _currentOrder,
                currentStep: _getCurrentStepText(),
                timeRemaining: _timeRemaining,
                distanceRemaining: _distanceRemaining,
                isLoading: _isUpdatingStatus,
                onCallCustomer: () => _makePhoneCall(_currentOrder.customerPhone),
                onCallRestaurant: _currentOrder.restaurantPhone != null
                    ? () => _makePhoneCall(_currentOrder.restaurantPhone!)
                    : null,
                onNextStep: () => _updateOrderStatus(_getNextStatus()),
                onCenterMap: _centerMapOnCurrentLocation,
                nextStepText: _getNextStatusText(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

