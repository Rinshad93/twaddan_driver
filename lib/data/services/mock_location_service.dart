import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../repositories/location_repository.dart';

class MockLocationService implements LocationRepository {
  // San Francisco as default location
  static const LatLng _defaultLocation = LatLng(37.7749, -122.4194);
  LatLng _currentLocation = _defaultLocation;

  final _locationController = StreamController<LatLng>.broadcast();
  final Random _random = Random();

  MockLocationService() {
    _startLocationSimulation();
  }

  void _startLocationSimulation() {
    // Simulate location updates every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _simulateLocationMovement();
    });
  }

  void _simulateLocationMovement() {
    // Small random movement to simulate real GPS with some drift
    final newLat = _currentLocation.latitude + (_random.nextDouble() - 0.5) * 0.0001;
    final newLng = _currentLocation.longitude + (_random.nextDouble() - 0.5) * 0.0001;

    _currentLocation = LatLng(newLat, newLng);
    _locationController.add(_currentLocation);
  }

  @override
  Future<LatLng> getCurrentLocation() async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate permission check
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    return _currentLocation;
  }

  @override
  Stream<LatLng> watchLocationUpdates() {
    return _locationController.stream;
  }

  @override
  Future<bool> requestLocationPermission() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate permission request
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      // Mock always grants permission for demo
      return true;
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      // Mock always returns true for demo
      return true;
    }
  }

  @override
  Future<double> calculateDistance(LatLng start, LatLng end) async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final distanceInMeters = Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );

      // Convert meters to kilometers
      return distanceInMeters / 1000;
    } catch (e) {
      // Fallback calculation using Haversine formula
      return _haversineDistance(start, end);
    }
  }

  double _haversineDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(end.latitude - start.latitude);
    final double dLng = _degreesToRadians(end.longitude - start.longitude);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  @override
  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // Generate a more realistic route using street-like patterns
    return _generateRealisticRoute(start, end);
  }

  List<LatLng> _generateRealisticRoute(LatLng start, LatLng end) {
    final route = <LatLng>[];

    // Add starting point
    route.add(start);

    // Generate intermediate waypoints that follow a more realistic path
    final waypoints = _generateStreetLikeWaypoints(start, end);

    // Create smooth route segments between waypoints
    for (int i = 0; i < waypoints.length - 1; i++) {
      final segmentStart = waypoints[i];
      final segmentEnd = waypoints[i + 1];

      // Generate points for this segment with some randomness for realism
      final segmentPoints = _generateSegmentPoints(segmentStart, segmentEnd);
      route.addAll(segmentPoints);
    }

    // Ensure we end exactly at the destination
    if (route.last != end) {
      route.add(end);
    }

    return route;
  }

  List<LatLng> _generateStreetLikeWaypoints(LatLng start, LatLng end) {
    final waypoints = <LatLng>[start];

    final latDiff = end.latitude - start.latitude;
    final lngDiff = end.longitude - start.longitude;

    // Create waypoints that simulate turning at intersections
    // This creates a more street-like navigation pattern

    // First segment - move primarily in one direction
    if (latDiff.abs() > lngDiff.abs()) {
      // Move more north/south first
      waypoints.add(LatLng(
        start.latitude + latDiff * 0.6,
        start.longitude + lngDiff * 0.2,
      ));

      // Then adjust east/west
      waypoints.add(LatLng(
        start.latitude + latDiff * 0.8,
        start.longitude + lngDiff * 0.7,
      ));
    } else {
      // Move more east/west first
      waypoints.add(LatLng(
        start.latitude + latDiff * 0.2,
        start.longitude + lngDiff * 0.6,
      ));

      // Then adjust north/south
      waypoints.add(LatLng(
        start.latitude + latDiff * 0.7,
        start.longitude + lngDiff * 0.8,
      ));
    }

    // Add some intermediate points for longer routes
    final distance = _haversineDistance(start, end);
    if (distance > 2.0) { // For routes longer than 2km
      waypoints.insert(1, LatLng(
        start.latitude + latDiff * 0.3,
        start.longitude + lngDiff * 0.1,
      ));

      waypoints.insert(-1, LatLng(
        start.latitude + latDiff * 0.9,
        start.longitude + lngDiff * 0.9,
      ));
    }

    waypoints.add(end);
    return waypoints;
  }

  List<LatLng> _generateSegmentPoints(LatLng start, LatLng end) {
    final points = <LatLng>[];
    const int segmentSteps = 8; // Points per segment

    for (int i = 1; i <= segmentSteps; i++) {
      final progress = i / segmentSteps;

      // Add some curvature to make the route look more natural
      final curve = sin(progress * pi) * 0.0001; // Small curve factor

      final lat = start.latitude +
          (end.latitude - start.latitude) * progress +
          curve * (_random.nextDouble() - 0.5);

      final lng = start.longitude +
          (end.longitude - start.longitude) * progress +
          curve * (_random.nextDouble() - 0.5);

      points.add(LatLng(lat, lng));
    }

    return points;
  }

  @override
  Future<int> getEstimatedTime(LatLng start, LatLng end) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final distance = await calculateDistance(start, end);

    // More realistic time calculation based on distance and traffic patterns
    double averageSpeed;

    if (distance < 1.0) {
      // Short distance - city streets with traffic lights
      averageSpeed = 15; // km/h
    } else if (distance < 5.0) {
      // Medium distance - mix of city and arterial roads
      averageSpeed = 25; // km/h
    } else {
      // Long distance - highways possible
      averageSpeed = 35; // km/h
    }

    // Add some randomness for traffic conditions
    final trafficFactor = 0.8 + (_random.nextDouble() * 0.4); // 0.8 to 1.2
    averageSpeed *= trafficFactor;

    final timeInHours = distance / averageSpeed;
    final timeInMinutes = (timeInHours * 60).round();

    // Add minimum time and buffer
    return (timeInMinutes + 3).clamp(5, 120); // Min 5 minutes, max 2 hours
  }

  // Method to simulate movement along a route (useful for testing)
  void simulateMovementAlongRoute(List<LatLng> route) {
    if (route.isEmpty) return;

    int currentIndex = 0;
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (currentIndex >= route.length) {
        timer.cancel();
        return;
      }

      _currentLocation = route[currentIndex];
      _locationController.add(_currentLocation);
      currentIndex++;
    });
  }

  // Method to jump to a specific location (useful for testing)
  void jumpToLocation(LatLng location) {
    _currentLocation = location;
    _locationController.add(_currentLocation);
  }

  void dispose() {
    _locationController.close();
  }
}



