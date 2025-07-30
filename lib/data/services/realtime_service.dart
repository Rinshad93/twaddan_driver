import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/order_model.dart';
import '../models/driver_model.dart';
import '../models/notification_model.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _connectionTimeoutTimer;

  // Connection configuration
  static const String _baseUrl = 'wss://api.fooddelivery.com/ws';
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _connectionTimeout = Duration(seconds: 10);

  // Connection state
  ConnectionStatus _status = ConnectionStatus.disconnected;
  int _reconnectAttempts = 0;
  String? _driverId;
  String? _authToken;

  // Stream controllers for real-time events
  final _connectionStatusController = StreamController<ConnectionStatus>.broadcast();
  final _orderUpdatesController = StreamController<Order>.broadcast();
  final _newOrdersController = StreamController<Order>.broadcast();
  final _driverUpdatesController = StreamController<Driver>.broadcast();
  final _notificationsController = StreamController<NotificationModel>.broadcast();
  final _locationUpdatesController = StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<ConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<Order> get orderUpdates => _orderUpdatesController.stream;
  Stream<Order> get newOrders => _newOrdersController.stream;
  Stream<Driver> get driverUpdates => _driverUpdatesController.stream;
  Stream<NotificationModel> get notifications => _notificationsController.stream;
  Stream<Map<String, dynamic>> get locationUpdates => _locationUpdatesController.stream;

  // Getters
  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.connected;

  /// Initialize real-time service
  Future<void> initialize({
    required String driverId,
    required String authToken,
  }) async {
    _driverId = driverId;
    _authToken = authToken;
  }

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_status == ConnectionStatus.connecting || _status == ConnectionStatus.connected) {
      return;
    }

    _updateStatus(ConnectionStatus.connecting);
    _startConnectionTimeout();

    try {
      final uri = Uri.parse('$_baseUrl?driverId=$_driverId&token=$_authToken');
      _channel = WebSocketChannel.connect(uri);

      // Listen to WebSocket stream
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // Send initial connection message
      _sendMessage({
        'type': 'connect',
        'driverId': _driverId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _updateStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
      _cancelConnectionTimeout();

      print('WebSocket connected successfully');
    } catch (e) {
      print('WebSocket connection failed: $e');
      _updateStatus(ConnectionStatus.failed);
      _scheduleReconnect();
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _cancelReconnectTimer();
    _cancelHeartbeatTimer();
    _cancelConnectionTimeout();

    if (_channel != null) {
      await _channel!.sink.close(ws_status.normalClosure);
      _channel = null;
    }

    _updateStatus(ConnectionStatus.disconnected);
  }

  /// Send driver location update
  void sendLocationUpdate({
    required double latitude,
    required double longitude,
    required double heading,
    required double speed,
  }) {
    if (!isConnected) return;

    _sendMessage({
      'type': 'location_update',
      'driverId': _driverId,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'timestamp': DateTime.now().toIso8601String(),
      },
    });
  }

  /// Send driver status update
  void sendDriverStatusUpdate({
    required bool isOnline,
    String? status,
  }) {
    if (!isConnected) return;

    _sendMessage({
      'type': 'driver_status_update',
      'driverId': _driverId,
      'isOnline': isOnline,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send order status update
  void sendOrderStatusUpdate({
    required String orderId,
    required OrderStatus status,
    Map<String, dynamic>? metadata,
  }) {
    if (!isConnected) return;

    _sendMessage({
      'type': 'order_status_update',
      'driverId': _driverId,
      'orderId': orderId,
      'status': status.value,
      'metadata': metadata ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Join order room for real-time updates
  void joinOrderRoom(String orderId) {
    if (!isConnected) return;

    _sendMessage({
      'type': 'join_room',
      'room': 'order_$orderId',
      'driverId': _driverId,
    });
  }

  /// Leave order room
  void leaveOrderRoom(String orderId) {
    if (!isConnected) return;

    _sendMessage({
      'type': 'leave_room',
      'room': 'order_$orderId',
      'driverId': _driverId,
    });
  }

  /// Subscribe to driver area for new orders
  void subscribeToArea({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    if (!isConnected) return;

    _sendMessage({
      'type': 'subscribe_area',
      'driverId': _driverId,
      'area': {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusKm,
      },
    });
  }

  /// Unsubscribe from area
  void unsubscribeFromArea() {
    if (!isConnected) return;

    _sendMessage({
      'type': 'unsubscribe_area',
      'driverId': _driverId,
    });
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final messageType = data['type'] as String?;

      switch (messageType) {
        case 'ping':
          _sendMessage({'type': 'pong'});
          break;

        case 'new_order':
          _handleNewOrder(data);
          break;

        case 'order_update':
          _handleOrderUpdate(data);
          break;

        case 'driver_update':
          _handleDriverUpdate(data);
          break;

        case 'notification':
          _handleNotification(data);
          break;

        case 'location_request':
          _handleLocationRequest(data);
          break;

        case 'connection_ack':
          print('Connection acknowledged by server');
          break;

        case 'error':
          _handleServerError(data);
          break;

        default:
          print('Unknown message type: $messageType');
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  /// Handle new order message
  void _handleNewOrder(Map<String, dynamic> data) {
    try {
      final orderData = data['order'] as Map<String, dynamic>;
      final order = Order.fromJson(orderData);
      _newOrdersController.add(order);
    } catch (e) {
      print('Error handling new order: $e');
    }
  }

  /// Handle order update message
  void _handleOrderUpdate(Map<String, dynamic> data) {
    try {
      final orderData = data['order'] as Map<String, dynamic>;
      final order = Order.fromJson(orderData);
      _orderUpdatesController.add(order);
    } catch (e) {
      print('Error handling order update: $e');
    }
  }

  /// Handle driver update message
  void _handleDriverUpdate(Map<String, dynamic> data) {
    try {
      final driverData = data['driver'] as Map<String, dynamic>;
      final driver = Driver.fromJson(driverData);
      _driverUpdatesController.add(driver);
    } catch (e) {
      print('Error handling driver update: $e');
    }
  }

  /// Handle notification message
  void _handleNotification(Map<String, dynamic> data) {
    try {
      final notificationData = data['notification'] as Map<String, dynamic>;
      final notification = NotificationModel.fromJson(notificationData);
      _notificationsController.add(notification);
    } catch (e) {
      print('Error handling notification: $e');
    }
  }

  /// Handle location request from server
  void _handleLocationRequest(Map<String, dynamic> data) {
    // Trigger location update request
    _locationUpdatesController.add({
      'type': 'location_requested',
      'requestId': data['requestId'],
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handle server error
  void _handleServerError(Map<String, dynamic> data) {
    final errorMessage = data['message'] as String? ?? 'Unknown server error';
    final errorCode = data['code'] as String? ?? 'UNKNOWN';

    print('Server error: $errorCode - $errorMessage');

    // Handle specific error codes
    switch (errorCode) {
      case 'AUTH_FAILED':
        _updateStatus(ConnectionStatus.failed);
        break;
      case 'RATE_LIMIT':
      // Implement rate limiting backoff
        break;
      default:
      // Generic error handling
        break;
    }
  }

  /// Handle WebSocket error
  void _handleError(error) {
    print('WebSocket error: $error');
    _updateStatus(ConnectionStatus.failed);
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    print('WebSocket disconnected');
    _updateStatus(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  /// Send message through WebSocket
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel?.sink != null && isConnected) {
      try {
        _channel!.sink.add(json.encode(message));
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    }
  }

  /// Update connection status
  void _updateStatus(ConnectionStatus status) {
    if (_status != status) {
      _status = status;
      _connectionStatusController.add(status);
    }
  }

  /// Schedule reconnection
  void _scheduleReconnect() {
    if (_status == ConnectionStatus.disconnected) return;

    _cancelReconnectTimer();
    _updateStatus(ConnectionStatus.reconnecting);

    final delay = Duration(
      seconds: (_reconnectDelay.inSeconds * (_reconnectAttempts + 1))
          .clamp(0, _maxReconnectDelay.inSeconds),
    );

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect();
    });

    print('Reconnecting in ${delay.inSeconds} seconds (attempt $_reconnectAttempts)');
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _cancelHeartbeatTimer();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (isConnected) {
        _sendMessage({
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Start connection timeout
  void _startConnectionTimeout() {
    _cancelConnectionTimeout();
    _connectionTimeoutTimer = Timer(_connectionTimeout, () {
      if (_status == ConnectionStatus.connecting) {
        print('Connection timeout');
        _updateStatus(ConnectionStatus.failed);
        _scheduleReconnect();
      }
    });
  }

  /// Cancel timers
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _cancelHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _cancelConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionStatusController.close();
    _orderUpdatesController.close();
    _newOrdersController.close();
    _driverUpdatesController.close();
    _notificationsController.close();
    _locationUpdatesController.close();
  }
}