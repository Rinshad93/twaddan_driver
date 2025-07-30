import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class LocationPermissionRequested extends LocationEvent {
  const LocationPermissionRequested();
}

class LocationCurrentRequested extends LocationEvent {
  const LocationCurrentRequested();
}

class LocationWatchStarted extends LocationEvent {
  const LocationWatchStarted();
}

class LocationWatchStopped extends LocationEvent {
  const LocationWatchStopped();
}

class LocationServiceChecked extends LocationEvent {
  const LocationServiceChecked();
}

class LocationDistanceRequested extends LocationEvent {
  final LatLng start;
  final LatLng end;

  const LocationDistanceRequested({
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [start, end];
}

class LocationRouteRequested extends LocationEvent {
  final LatLng start;
  final LatLng end;

  const LocationRouteRequested({
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [start, end];
}

class LocationEtaRequested extends LocationEvent {
  final LatLng start;
  final LatLng end;

  const LocationEtaRequested({
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [start, end];
}

class LocationErrorCleared extends LocationEvent {
  const LocationErrorCleared();
}