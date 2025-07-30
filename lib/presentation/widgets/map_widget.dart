import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/order_model.dart';

class MapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final Order? order;
  final List<LatLng>? route;
  final bool showUserLocation;
  final bool showRoute;
  final Function(GoogleMapController)? onMapCreated;
  final Function(LatLng)? onLocationChanged;
  final double? zoom;

  const MapWidget({
    super.key,
    this.initialLocation,
    this.order,
    this.route,
    this.showUserLocation = true,
    this.showRoute = false,
    this.onMapCreated,
    this.onLocationChanged,
    this.zoom = 14.0,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _restaurantIcon;
  BitmapDescriptor? _customerIcon;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation ?? const LatLng(37.7749, -122.4194);
    _loadCustomMarkers();
    _setupMarkers();
    _setupRoute();
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update current location if changed
    if (widget.initialLocation != oldWidget.initialLocation && widget.initialLocation != null) {
      _currentLocation = widget.initialLocation;
      _setupMarkers();
    }

    // Update markers if order changed
    if (widget.order != oldWidget.order) {
      _setupMarkers();
      if (widget.order != null) {
        _fitMarkersInView();
      }
    }

    // Update route if changed
    if (widget.route != oldWidget.route) {
      _setupRoute();
    }
  }

  Future<void> _loadCustomMarkers() async {
    try {
      // Create custom markers with different colors
      _driverIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/driver_marker.png', // You can add custom icons
      ).catchError((_) => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));

      _restaurantIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/restaurant_marker.png',
      ).catchError((_) => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange));

      _customerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/customer_marker.png',
      ).catchError((_) => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));

    } catch (e) {
      // Fallback to default markers
      _driverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _restaurantIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      _customerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }

  void _setupMarkers() {
    _markers.clear();

    // Add current location marker (driver)
    if (widget.showUserLocation && _currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Driver Position',
          ),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    // Add order-related markers
    if (widget.order != null) {
      final order = widget.order!;

      // Restaurant marker
      _markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: order.restaurantLocation,
          icon: _restaurantIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: order.restaurantName,
            snippet: 'Pickup Location\n${order.restaurantAddress}',
          ),
          onTap: () => _showLocationDetails('restaurant', order.restaurantName, order.restaurantAddress),
        ),
      );

      // Customer marker
      _markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: order.customerLocation,
          icon: _customerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: order.customerName,
            snippet: 'Delivery Location\n${order.customerAddress}',
          ),
          onTap: () => _showLocationDetails('customer', order.customerName, order.customerAddress),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _setupRoute() {
    _polylines.clear();

    if (widget.showRoute && widget.route != null && widget.route!.isNotEmpty) {
      // Main route polyline
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('main_route'),
          points: widget.route!,
          color: AppColors.primary,
          width: 5,
          patterns: [], // Solid line for main route
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );

      // Optional: Add a shadow/outline for better visibility
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_shadow'),
          points: widget.route!,
          color: AppColors.primary.withOpacity(0.3),
          width: 8,
          patterns: [],
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );

      // If we have current location and route, show progress
      if (_currentLocation != null && widget.route!.isNotEmpty) {
        _addRouteProgress();
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _addRouteProgress() {
    if (widget.route == null || widget.route!.isEmpty || _currentLocation == null) return;

    // Find the closest point on route to current location
    int closestIndex = _findClosestPointOnRoute(_currentLocation!, widget.route!);

    if (closestIndex > 0) {
      // Create a completed portion of the route
      List<LatLng> completedRoute = widget.route!.take(closestIndex + 1).toList();

      _polylines.add(
        Polyline(
          polylineId: const PolylineId('completed_route'),
          points: completedRoute,
          color: AppColors.success,
          width: 5,
          patterns: [],
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }
  }

  int _findClosestPointOnRoute(LatLng currentLocation, List<LatLng> route) {
    if (route.isEmpty) return 0;

    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < route.length; i++) {
      double distance = _calculateDistance(currentLocation, route[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Simple distance calculation (for more accuracy, use Haversine formula)
    double latDiff = point1.latitude - point2.latitude;
    double lngDiff = point1.longitude - point2.longitude;
    return (latDiff * latDiff) + (lngDiff * lngDiff);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    widget.onMapCreated?.call(controller);

    // Set map style for better appearance
    _setMapStyle();

    // Fit markers if we have them
    if (_markers.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _fitMarkersInView();
      });
    }
  }

  void _setMapStyle() async {
    const String mapStyle = '''
    [
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "transit",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "road",
        "elementType": "labels.icon",
        "stylers": [{"visibility": "off"}]
      }
    ]
    ''';

    try {
      await _mapController?.setMapStyle(mapStyle);
    } catch (e) {
      print('Error setting map style: $e');
    }
  }

  void _showLocationDetails(String type, String name, String address) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusL)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  type == 'restaurant' ? Icons.restaurant : Icons.home,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceS),
            Text(
              address,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Add navigation functionality
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Add call functionality
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void updateCurrentLocation(LatLng newLocation) {
    setState(() {
      _currentLocation = newLocation;
    });
    _setupMarkers();
    _setupRoute(); // Refresh route to show progress
    widget.onLocationChanged?.call(newLocation);
  }

  void animateToLocation(LatLng location, {double zoom = 16.0}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: zoom),
      ),
    );
  }

  void _fitMarkersInView() {
    if (_markers.isEmpty) return;

    try {
      final bounds = _calculateBounds(_markers.map((m) => m.position).toList());
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    } catch (e) {
      print('Error fitting markers: $e');
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    if (positions.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(37.7749, -122.4194),
        northeast: const LatLng(37.7749, -122.4194),
      );
    }

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final position in positions) {
      minLat = minLat < position.latitude ? minLat : position.latitude;
      maxLat = maxLat > position.latitude ? maxLat : position.latitude;
      minLng = minLng < position.longitude ? minLng : position.longitude;
      maxLng = maxLng > position.longitude ? maxLng : position.longitude;
    }

    // Add some padding
    const double padding = 0.001;

    return LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _currentLocation!,
        zoom: widget.zoom!,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: false, // We handle this with custom marker
      myLocationButtonEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      trafficEnabled: false,
      buildingsEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
      onCameraMove: (CameraPosition position) {
        // Handle camera movement if needed
      },
    );
  }
}

