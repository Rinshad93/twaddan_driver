import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/utils/service_locator.dart';
import '../../../data/repositories/location_repository.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository _locationRepository;
  StreamSubscription<LatLng>? _locationSubscription;

  LocationBloc({LocationRepository? locationRepository})
      : _locationRepository = locationRepository ?? ServiceLocator().locationRepository,
        super(const LocationInitial()) {
    on<LocationPermissionRequested>(_onLocationPermissionRequested);
    on<LocationCurrentRequested>(_onLocationCurrentRequested);
    on<LocationWatchStarted>(_onLocationWatchStarted);
    on<LocationWatchStopped>(_onLocationWatchStopped);
    on<LocationServiceChecked>(_onLocationServiceChecked);
    on<LocationDistanceRequested>(_onLocationDistanceRequested);
    on<LocationRouteRequested>(_onLocationRouteRequested);
    on<LocationEtaRequested>(_onLocationEtaRequested);
    on<LocationErrorCleared>(_onLocationErrorCleared);
  }

  Future<void> _onLocationPermissionRequested(
      LocationPermissionRequested event,
      Emitter<LocationState> emit,
      ) async {
    try {
      emit(const LocationLoading());

      final hasPermission = await _locationRepository.requestLocationPermission();

      if (hasPermission) {
        emit(const LocationPermissionGranted());
      } else {
        emit(const LocationPermissionDenied());
      }
    } catch (e) {
      emit(LocationError('Failed to request location permission: ${e.toString()}'));
    }
  }

  Future<void> _onLocationCurrentRequested(
      LocationCurrentRequested event,
      Emitter<LocationState> emit,
      ) async {
    try {
      emit(const LocationLoading());

      // Check service first
      final serviceEnabled = await _locationRepository.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const LocationServiceDisabled());
        return;
      }

      // Check permission
      final hasPermission = await _locationRepository.requestLocationPermission();
      if (!hasPermission) {
        emit(const LocationPermissionDenied());
        return;
      }

      // Get current location
      final location = await _locationRepository.getCurrentLocation();
      emit(LocationLoaded(location));
    } catch (e) {
      emit(LocationError(_getReadableLocationError(e.toString())));
    }
  }

  Future<void> _onLocationWatchStarted(
      LocationWatchStarted event,
      Emitter<LocationState> emit,
      ) async {
    try {
      // Cancel existing subscription
      await _locationSubscription?.cancel();

      // Check prerequisites
      final serviceEnabled = await _locationRepository.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const LocationServiceDisabled());
        return;
      }

      final hasPermission = await _locationRepository.requestLocationPermission();
      if (!hasPermission) {
        emit(const LocationPermissionDenied());
        return;
      }

      // Get initial location
      final initialLocation = await _locationRepository.getCurrentLocation();
      emit(LocationWatching(initialLocation));

      // Start watching
      _locationSubscription = _locationRepository
          .watchLocationUpdates()
          .listen(
            (location) {
          emit(LocationUpdated(location));
          // Immediately return to watching state
          emit(LocationWatching(location));
        },
        onError: (error) {
          emit(LocationError('Location tracking error: ${error.toString()}'));
        },
      );
    } catch (e) {
      emit(LocationError(_getReadableLocationError(e.toString())));
    }
  }

  Future<void> _onLocationWatchStopped(
      LocationWatchStopped event,
      Emitter<LocationState> emit,
      ) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    // Return to initial state
    emit(const LocationInitial());
  }

  Future<void> _onLocationServiceChecked(
      LocationServiceChecked event,
      Emitter<LocationState> emit,
      ) async {
    try {
      final serviceEnabled = await _locationRepository.isLocationServiceEnabled();

      if (serviceEnabled) {
        add(const LocationPermissionRequested());
      } else {
        emit(const LocationServiceDisabled());
      }
    } catch (e) {
      emit(LocationError('Failed to check location service: ${e.toString()}'));
    }
  }

  Future<void> _onLocationDistanceRequested(
      LocationDistanceRequested event,
      Emitter<LocationState> emit,
      ) async {
    try {
      emit(const LocationLoading());

      final distance = await _locationRepository.calculateDistance(
        event.start,
        event.end,
      );

      emit(LocationDistanceCalculated(
        distance: distance,
        start: event.start,
        end: event.end,
      ));
    } catch (e) {
      emit(LocationError('Failed to calculate distance: ${e.toString()}'));
    }
  }

  Future<void> _onLocationRouteRequested(
      LocationRouteRequested event,
      Emitter<LocationState> emit,
      ) async {
    try {
      emit(const LocationLoading());

      final route = await _locationRepository.getRoute(
        event.start,
        event.end,
      );

      emit(LocationRouteLoaded(
        route: route,
        start: event.start,
        end: event.end,
      ));
    } catch (e) {
      emit(LocationError('Failed to get route: ${e.toString()}'));
    }
  }

  Future<void> _onLocationEtaRequested(
      LocationEtaRequested event,
      Emitter<LocationState> emit,
      ) async {
    try {
      emit(const LocationLoading());

      final eta = await _locationRepository.getEstimatedTime(
        event.start,
        event.end,
      );

      emit(LocationEtaCalculated(
        eta: eta,
        start: event.start,
        end: event.end,
      ));
    } catch (e) {
      emit(LocationError('Failed to calculate ETA: ${e.toString()}'));
    }
  }

  Future<void> _onLocationErrorCleared(
      LocationErrorCleared event,
      Emitter<LocationState> emit,
      ) async {
    emit(const LocationInitial());
  }

  String _getReadableLocationError(String error) {
    if (error.contains('permission')) {
      return 'Location permission is required';
    } else if (error.contains('service') || error.contains('GPS')) {
      return 'Please enable location services';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Network error while getting location';
    } else {
      return 'Unable to get location. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}