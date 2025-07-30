import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationLoading extends LocationState {
  const LocationLoading();
}

class LocationPermissionGranted extends LocationState {
  const LocationPermissionGranted();
}

class LocationPermissionDenied extends LocationState {
  const LocationPermissionDenied();
}

class LocationServiceDisabled extends LocationState {
  const LocationServiceDisabled();
}

class LocationLoaded extends LocationState {
  final LatLng location;

  const LocationLoaded(this.location);

  @override
  List<Object?> get props => [location];
}

class LocationUpdated extends LocationState {
  final LatLng location;

  const LocationUpdated(this.location);

  @override
  List<Object?> get props => [location];
}

class LocationWatching extends LocationState {
  final LatLng currentLocation;

  const LocationWatching(this.currentLocation);

  @override
  List<Object?> get props => [currentLocation];
}

class LocationDistanceCalculated extends LocationState {
  final double distance;
  final LatLng start;
  final LatLng end;

  const LocationDistanceCalculated({
    required this.distance,
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [distance, start, end];
}

class LocationRouteLoaded extends LocationState {
  final List<LatLng> route;
  final LatLng start;
  final LatLng end;

  const LocationRouteLoaded({
    required this.route,
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [route, start, end];
}

class LocationEtaCalculated extends LocationState {
  final int eta; // in minutes
  final LatLng start;
  final LatLng end;

  const LocationEtaCalculated({
    required this.eta,
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [eta, start, end];
}

class LocationError extends LocationState {
  final String message;

  const LocationError(this.message);

  @override
  List<Object?> get props => [message];
}