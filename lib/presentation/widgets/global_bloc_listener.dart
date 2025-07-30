import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twaddan_driver/data/models/order_model.dart';

import '../../../core/utils/bloc_extensions.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/realtime_service.dart';
import '../../../data/services/background_service.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/location/location_bloc.dart';
import '../bloc/location/location_state.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_event.dart';
import '../bloc/notification/notification_state.dart';
import '../bloc/order/order_bloc.dart';
import '../bloc/order/order_event.dart';
import '../bloc/order/order_state.dart';

class GlobalBlocListener extends StatefulWidget {
  final Widget child;

  const GlobalBlocListener({
    super.key,
    required this.child,
  });

  @override
  State<GlobalBlocListener> createState() => _GlobalBlocListenerState();
}

class _GlobalBlocListenerState extends State<GlobalBlocListener> {
  final NotificationService _notificationService = NotificationService();
  final RealtimeService _realtimeService = RealtimeService();
  final BackgroundService _backgroundService = BackgroundService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _realtimeService.dispose();
    _backgroundService.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize notification service
      await _notificationService.initialize();

      // Initialize background service
      await _backgroundService.initialize();

      // Initialize real-time service will be done when user logs in
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Auth state listener
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) => _handleAuthStateChange(context, state),
        ),

        // Order state listener
        BlocListener<OrderBloc, OrderState>(
          listener: (context, state) => _handleOrderStateChange(context, state),
        ),

        // Location state listener
        BlocListener<LocationBloc, LocationState>(
          listener: (context, state) => _handleLocationStateChange(context, state),
        ),

        // Notification state listener
        BlocListener<NotificationBloc, NotificationState>(
          listener: (context, state) => _handleNotificationStateChange(context, state),
        ),
      ],
      child: widget.child,
    );
  }

  /// Handle authentication state changes
  void _handleAuthStateChange(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      _onUserAuthenticated(context, state);
    } else if (state is AuthUnauthenticated) {
      _onUserLoggedOut(context);
    } else if (state is AuthStatusUpdated) {
      _onDriverStatusChanged(context, state);
    }
  }

  /// Handle user authentication
  Future<void> _onUserAuthenticated(BuildContext context, AuthAuthenticated state) async {
    final driver = state.driver;

    try {
      // Initialize real-time service with driver credentials
      await _realtimeService.initialize(
        driverId: driver.id,
        authToken: 'mock_token', // In real app, get from auth state
      );

      // Connect to real-time service
      await _realtimeService.connect();

      // Update background service with driver info
      await _backgroundService.updateDriverStatus(
        isOnline: driver.isOnline,
        driverId: driver.id,
      );

      // Subscribe to driver's area if online
      if (driver.isOnline && driver.currentLocation != null) {
        _realtimeService.subscribeToArea(
          latitude: driver.currentLocation!.latitude,
          longitude: driver.currentLocation!.longitude,
          radiusKm: 10.0, // 10km radius
        );
      }

      // Show welcome notification
      await _notificationService.showPromotionalNotification(
        title: 'Welcome back, ${driver.name}! 👋',
        message: driver.isOnline
            ? 'You\'re online and ready to receive orders'
            : 'Go online to start receiving orders',
        data: {'action': 'dashboard'},
      );

      // Listen to real-time events
      _subscribeToRealtimeEvents(context);

    } catch (e) {
      print('Error setting up user session: $e');
      context.showErrorSnackBar('Failed to connect to real-time services');
    }
  }

  /// Handle user logout
  Future<void> _onUserLoggedOut(BuildContext context) async {
    try {
      // Disconnect real-time service
      await _realtimeService.disconnect();

      // Stop background service
      await _backgroundService.stopService();

      // Cancel all notifications
      await _notificationService.cancelAllNotifications();

      context.showInfoSnackBar('You have been logged out');
    } catch (e) {
      print('Error during logout cleanup: $e');
    }
  }

  /// Handle driver status changes
  Future<void> _onDriverStatusChanged(BuildContext context, AuthStatusUpdated state) async {
    final driver = state.driver;

    try {
      // Update real-time service
      _realtimeService.sendDriverStatusUpdate(
        isOnline: driver.isOnline,
        status: driver.isOnline ? 'available' : 'offline',
      );

      // Update background service
      await _backgroundService.updateDriverStatus(
        isOnline: driver.isOnline,
        driverId: driver.id,
      );

      // Show status notification
      if (driver.isOnline) {
        // Start background service when going online
        await _backgroundService.startService();

        // Subscribe to area for new orders
        if (driver.currentLocation != null) {
          _realtimeService.subscribeToArea(
            latitude: driver.currentLocation!.latitude,
            longitude: driver.currentLocation!.longitude,
            radiusKm: 10.0,
          );
        }

        await _notificationService.showPromotionalNotification(
          title: 'You\'re now online! 🟢',
          message: 'Ready to receive new orders',
        );
      } else {
        // Stop background service when going offline
        await _backgroundService.stopService();

        // Unsubscribe from area
        _realtimeService.unsubscribeFromArea();

        await _notificationService.showPromotionalNotification(
          title: 'You\'re now offline 🔴',
          message: 'You won\'t receive new orders',
        );
      }
    } catch (e) {
      print('Error updating driver status: $e');
    }
  }

  /// Handle order state changes
  void _handleOrderStateChange(BuildContext context, OrderState state) {
    if (state is OrderAccepted) {
      _onOrderAccepted(context, state);
    } else if (state is OrderStatusUpdated) {
      _onOrderStatusUpdated(context, state);
    } else if (state is OrderError) {
      _onOrderError(context, state);
    }
  }

  /// Handle order acceptance
  Future<void> _onOrderAccepted(BuildContext context, OrderAccepted state) async {
    final order = state.order;

    try {
      // Join order room for real-time updates
      _realtimeService.joinOrderRoom(order.id);

      // Send order status update
      _realtimeService.sendOrderStatusUpdate(
        orderId: order.id,
        status: order.status,
        metadata: {
          'acceptedAt': DateTime.now().toIso8601String(),
        },
      );

      // Show notification
      await _notificationService.showOrderStatusNotification(
        orderId: order.id,
        status: order.status.displayName,
        message: 'Order from ${order.restaurantName} accepted',
      );

      context.showSuccessSnackBar('Order accepted! Navigate to restaurant to pick up.');
    } catch (e) {
      print('Error handling order acceptance: $e');
    }
  }

  /// Handle order status updates
  Future<void> _onOrderStatusUpdated(BuildContext context, OrderStatusUpdated state) async {
    final order = state.order;

    try {
      // Send real-time update
      _realtimeService.sendOrderStatusUpdate(
        orderId: order.id,
        status: order.status,
        metadata: {
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      // Show appropriate notification based on status
      String message;
      switch (order.status) {
        case OrderStatus.pickedUp:
          message = 'Order picked up from ${order.restaurantName}';
          break;
        case OrderStatus.inTransit:
          message = 'Delivering order to ${order.customerName}';
          break;
        case OrderStatus.delivered:
          message = 'Order delivered successfully! 🎉';
          // Leave order room when delivered
          _realtimeService.leaveOrderRoom(order.id);
          break;
        default:
          message = 'Order status updated to ${order.status.displayName}';
      }

      await _notificationService.showOrderStatusNotification(
        orderId: order.id,
        status: order.status.displayName,
        message: message,
      );

    } catch (e) {
      print('Error handling order status update: $e');
    }
  }

  /// Handle order errors
  void _onOrderError(BuildContext context, OrderError state) {
    context.showErrorSnackBar(state.message);
  }

  /// Handle location state changes
  void _handleLocationStateChange(BuildContext context, LocationState state) {
    if (state is LocationUpdated || state is LocationWatching) {
      _onLocationUpdated(context, state);
    } else if (state is LocationError) {
      _onLocationError(context, state);
    }
  }

  /// Handle location updates
  void _onLocationUpdated(BuildContext context, LocationState state) {
    final location = state is LocationUpdated
        ? state.location
        : (state as LocationWatching).currentLocation;

    try {
      // Send location update to real-time service
      _realtimeService.sendLocationUpdate(
        latitude: location.latitude,
        longitude: location.longitude,
        heading: 0.0, // Would get from device sensors
        speed: 0.0,   // Would get from location service
      );
    } catch (e) {
      print('Error sending location update: $e');
    }
  }

  /// Handle location errors
  void _onLocationError(BuildContext context, LocationError state) {
    if (state.message.contains('permission')) {
      context.showErrorSnackBar('Location permission required for deliveries');
    } else {
      context.showErrorSnackBar('Location error: ${state.message}');
    }
  }

  /// Handle notification state changes
  void _handleNotificationStateChange(BuildContext context, NotificationState state) {
    if (state is NotificationActionTriggered) {
      _onNotificationActionTriggered(context, state);
    }
  }

  /// Handle notification actions
  void _onNotificationActionTriggered(BuildContext context, NotificationActionTriggered state) {
    final notification = state.notification;

    switch (notification.type) {
      case NotificationType.newOrder:
      // Navigate to order details or show order acceptance dialog
        if (notification.orderId != null) {
          _showOrderAcceptanceDialog(context, notification);
        }
        break;
      case NotificationType.earnings:
      // Navigate to earnings screen
        break;
      case NotificationType.emergency:
      // Handle emergency notification
        _showEmergencyDialog(context, notification);
        break;
      default:
        break;
    }
  }

  /// Subscribe to real-time events
  void _subscribeToRealtimeEvents(BuildContext context) {
    // Listen to new orders
    _realtimeService.newOrders.listen((order) {
      _notificationService.showNewOrderNotification(
        orderId: order.id,
        restaurantName: order.restaurantName,
        deliveryFee: order.driverEarning,
        estimatedTime: order.estimatedTotalMinutes.toDouble(),
      );
    });

    // Listen to order updates
    _realtimeService.orderUpdates.listen((order) {
      context.read<OrderBloc>().add(OrderRefresh());
    });

    // Listen to driver updates
    _realtimeService.driverUpdates.listen((driver) {
      // Could update driver info in auth bloc if needed
    });

    // Listen to real-time notifications
    _realtimeService.notifications.listen((notification) {
      context.read<NotificationBloc>().add(
        NotificationReceived(notification),
      );
    });
  }

  /// Show order acceptance dialog
  void _showOrderAcceptanceDialog(BuildContext context, NotificationModel notification) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('New Order - ${notification.restaurantName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restaurant: ${notification.restaurantName}'),
            Text('Delivery Fee: \$${notification.deliveryFee?.toStringAsFixed(2)}'),
            Text('Estimated Time: ${notification.estimatedTime?.toInt()} minutes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.showInfoSnackBar('Order declined');
            },
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (notification.orderId != null) {
                context.read<OrderBloc>().add(
                  OrderAccept(notification.orderId!),
                );
              }
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  /// Show emergency dialog
  void _showEmergencyDialog(BuildContext context, NotificationModel notification) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.red),
            const SizedBox(width: 8),
            Text(notification.title),
          ],
        ),
        content: Text(notification.body),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }
}