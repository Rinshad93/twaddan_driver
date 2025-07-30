import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class BackgroundService {
  static const String _portName = 'driver_background_service';
  static const String _isOnlineKey = 'driver_is_online';
  static const String _lastLocationKey = 'last_location';
  static const String _driverIdKey = 'current_driver_id';

  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  ReceivePort? _receivePort;
  bool _isInitialized = false;

  /// Initialize background service
  Future<void> initialize() async {
    if (_isInitialized) return;

    final service = FlutterBackgroundService();

    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        autoStart: false,
        onStart: _onStart,
        isForegroundMode: true,
        autoStartOnBoot: false,
        notificationChannelId: 'driver_background_service',
        initialNotificationTitle: 'Food Delivery Driver',
        initialNotificationContent: 'Driver service is running',
        foregroundServiceNotificationId: 888,
      ),
    );

    _setupPortCommunication();
    _isInitialized = true;
  }

  /// Start background service
  Future<void> startService() async {
    if (!_isInitialized) {
      await initialize();
    }

    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();

    if (!isRunning) {
      await service.startService();
    }

    // Mark driver as online
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isOnlineKey, true);

    _sendToBackground({
      'action': 'start_tracking',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Stop background service
  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stop_service'); // Remove await since invoke returns void

    // Mark driver as offline
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isOnlineKey, false);
  }

  /// Update driver status in background
  Future<void> updateDriverStatus({
    required bool isOnline,
    String? driverId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isOnlineKey, isOnline);

    if (driverId != null) {
      await prefs.setString(_driverIdKey, driverId);
    }

    _sendToBackground({
      'action': 'update_status',
      'isOnline': isOnline,
      'driverId': driverId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get current driver status
  Future<bool> isDriverOnline() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isOnlineKey) ?? false;
  }

  /// Get last known location
  Future<LatLng?> getLastKnownLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final locationData = prefs.getString(_lastLocationKey);

    if (locationData != null) {
      final parts = locationData.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }
    }

    return null;
  }

  /// Setup port communication between UI and background
  void _setupPortCommunication() {
    _receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(_receivePort!.sendPort, _portName);

    _receivePort!.listen((data) {
      if (data is Map<String, dynamic>) {
        _handleBackgroundMessage(data);
      }
    });
  }

  /// Send message to background isolate
  void _sendToBackground(Map<String, dynamic> message) {
    final service = FlutterBackgroundService();
    service.invoke('message_from_ui', message);
  }

  /// Handle messages from background isolate
  void _handleBackgroundMessage(Map<String, dynamic> message) {
    final action = message['action'] as String?;

    switch (action) {
      case 'location_update':
        _handleLocationUpdate(message);
        break;
      case 'service_status':
        _handleServiceStatus(message);
        break;
      case 'error':
        _handleBackgroundError(message);
        break;
      default:
        print('Unknown background message: $action');
    }
  }

  /// Handle location update from background
  void _handleLocationUpdate(Map<String, dynamic> message) {
    final lat = message['latitude'] as double?;
    final lng = message['longitude'] as double?;

    if (lat != null && lng != null) {
      // Save last known location
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(_lastLocationKey, '$lat,$lng');
      });

      // You can emit this to a stream if needed for real-time UI updates
      print('Background location update: $lat, $lng');
    }
  }

  /// Handle service status updates
  void _handleServiceStatus(Map<String, dynamic> message) {
    final status = message['status'] as String?;
    print('Background service status: $status');
  }

  /// Handle background errors
  void _handleBackgroundError(Map<String, dynamic> message) {
    final error = message['error'] as String?;
    print('Background service error: $error');
  }

  /// Dispose resources
  void dispose() {
    _receivePort?.close();
    IsolateNameServer.removePortNameMapping(_portName);
  }

  /// Background service entry point
  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final backgroundServiceInstance = BackgroundServiceInstance(service);
    await backgroundServiceInstance.initialize();
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    return true;
  }
}

/// Background service instance running in isolate
class BackgroundServiceInstance {
  final ServiceInstance service;
  Timer? _locationTimer;
  Timer? _heartbeatTimer;
  SendPort? _uiSendPort;

  // Configuration
  static const Duration _locationUpdateInterval = Duration(seconds: 30);
  static const Duration _heartbeatInterval = Duration(minutes: 5);
  static const Duration _notificationCheckInterval = Duration(minutes: 1);

  BackgroundServiceInstance(this.service);

  /// Initialize background service instance
  Future<void> initialize() async {
    // Setup communication with UI
    _setupUIcommunication();

    // Listen for service calls from UI
    service.on('message_from_ui').listen(_handleUIMessage);
    service.on('stop_service').listen((_) => _stopService());

    // Start background tasks
    await _startBackgroundTasks();

    print('Background service initialized');
  }

  /// Setup communication with UI isolate
  void _setupUIcommunication() {
    _uiSendPort = IsolateNameServer.lookupPortByName(BackgroundService._portName);
  }

  /// Send message to UI isolate
  void _sendToUI(Map<String, dynamic> message) {
    _uiSendPort?.send(message);
  }

  /// Handle messages from UI isolate
  void _handleUIMessage(Map<String, dynamic>? message) {
    if (message == null) return;

    final action = message['action'] as String?;

    switch (action) {
      case 'start_tracking':
        _startLocationTracking();
        break;
      case 'stop_tracking':
        _stopLocationTracking();
        break;
      case 'update_status':
        _updateDriverStatus(message);
        break;
      default:
        print('Unknown UI message: $action');
    }
  }

  /// Start background tasks
  Future<void> _startBackgroundTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final isOnline = prefs.getBool(BackgroundService._isOnlineKey) ?? false;

    if (isOnline) {
      _startLocationTracking();
    }

    _startHeartbeat();
    _startNotificationCheck();

    // Update service notification using the correct method
    _updateNotification(
      title: 'Food Delivery Driver',
      content: isOnline ? 'Online and ready for orders' : 'Offline',
    );
  }

  /// Start location tracking
  void _startLocationTracking() {
    _stopLocationTracking(); // Stop existing timer

    _locationTimer = Timer.periodic(_locationUpdateInterval, (_) async {
      await _updateLocation();
    });

    // Get initial location
    _updateLocation();

    _sendToUI({
      'action': 'service_status',
      'status': 'location_tracking_started',
    });
  }

  /// Stop location tracking
  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;

    _sendToUI({
      'action': 'service_status',
      'status': 'location_tracking_stopped',
    });
  }

  /// Update current location
  Future<void> _updateLocation() async {
    try {
      // Check permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Send location to UI
      _sendToUI({
        'action': 'location_update',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update service notification with location info
      _updateNotification(
        title: 'Food Delivery Driver - Online',
        content: 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
      );

    } catch (e) {
      _sendToUI({
        'action': 'error',
        'error': 'Location update failed: $e',
      });
    }
  }

  /// Update driver status
  void _updateDriverStatus(Map<String, dynamic> message) {
    final isOnline = message['isOnline'] as bool? ?? false;

    if (isOnline) {
      _startLocationTracking();
      _updateNotification(
        title: 'Food Delivery Driver - Online',
        content: 'Ready to receive orders',
      );
    } else {
      _stopLocationTracking();
      _updateNotification(
        title: 'Food Delivery Driver - Offline',
        content: 'Not receiving orders',
      );
    }
  }

  /// Start heartbeat to keep service alive
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _updateNotification(
        title: 'Food Delivery Driver',
        content: 'Service running - ${DateTime.now().toString().substring(11, 19)}',
      );

      _sendToUI({
        'action': 'heartbeat',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  /// Start periodic notification checks
  void _startNotificationCheck() {
    Timer.periodic(_notificationCheckInterval, (_) async {
      await _checkPendingNotifications();
    });
  }

  /// Check for pending notifications
  Future<void> _checkPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isOnline = prefs.getBool(BackgroundService._isOnlineKey) ?? false;

      if (isOnline) {
        // Check for new orders, earnings updates, etc.
        // This would typically involve API calls

        // Simulate checking for urgent notifications
        final now = DateTime.now();
        final lastCheck = prefs.getString('last_notification_check');

        if (lastCheck == null ||
            now.difference(DateTime.parse(lastCheck)).inMinutes > 5) {

          // Save last check time
          await prefs.setString('last_notification_check', now.toIso8601String());

          // Send status update
          _sendToUI({
            'action': 'notification_check',
            'timestamp': now.toIso8601String(),
          });
        }
      }
    } catch (e) {
      print('Error checking notifications: $e');
    }
  }

  /// Update foreground notification
  void _updateNotification({required String title, required String content}) {
    try {
      // For newer versions of flutter_background_service, use this approach:
      service.invoke('setNotificationInfo', {
        'title': title,
        'content': content,
      }); // Remove await since invoke returns void
    } catch (e) {
      // Fallback for older versions or if the above doesn't work
      print('Failed to update notification: $e');
    }
  }

  /// Stop the background service
  void _stopService() {
    _locationTimer?.cancel();
    _heartbeatTimer?.cancel();

    _sendToUI({
      'action': 'service_status',
      'status': 'service_stopped',
    });

    service.stopSelf();
  }
}