import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class LocationRepository {
  Future<LatLng> getCurrentLocation();
  Stream<LatLng> watchLocationUpdates();
  Future<bool> requestLocationPermission();
  Future<bool> isLocationServiceEnabled();
  Future<double> calculateDistance(LatLng start, LatLng end);
  Future<List<LatLng>> getRoute(LatLng start, LatLng end);
  Future<int> getEstimatedTime(LatLng start, LatLng end);
}