import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/service_locator.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/models/order_model.dart';
import 'order_event.dart';
import 'order_state.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';


class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _orderRepository;
  StreamSubscription<List<Order>>? _availableOrdersSubscription;
  StreamSubscription<Order>? _orderStatusSubscription;

  // Cache to prevent unnecessary reloads
  List<Order>? _cachedAvailableOrders;
  List<Order>? _cachedActiveOrders;
  List<Order>? _cachedOrderHistory;
  Map<String, double>? _cachedTodayEarnings;
  Map<String, double>? _cachedWeeklyEarnings;
  Map<String, double>? _cachedMonthlyEarnings;

  // Track loading states to prevent duplicate requests
  bool _isLoadingAvailable = false;
  bool _isLoadingActive = false;
  bool _isLoadingHistory = false;
  bool _isLoadingEarnings = false;
  bool _isRefreshing = false;

  // Context tracking to know which screen is currently active
  OrderViewContext _currentContext = OrderViewContext.unknown;

  // Track operations in progress
  final Set<String> _ordersBeingAccepted = <String>{};
  final Set<String> _ordersBeingDeclined = <String>{};
  final Set<String> _ordersBeingUpdated = <String>{};

  OrderBloc({OrderRepository? orderRepository})
      : _orderRepository = orderRepository ?? ServiceLocator().orderRepository,
        super(const OrderInitial()) {
    on<OrderLoadAvailable>(_onOrderLoadAvailable);
    on<OrderLoadActive>(_onOrderLoadActive);
    on<OrderLoadHistory>(_onOrderLoadHistory);
    on<OrderAccept>(_onOrderAccept);
    on<OrderDecline>(_onOrderDecline);
    on<OrderUpdateStatus>(_onOrderUpdateStatus);
    on<OrderWatchAvailable>(_onOrderWatchAvailable);
    on<OrderWatchStatus>(_onOrderWatchStatus);
    on<OrderStopWatching>(_onOrderStopWatching);
    on<OrderRefresh>(_onOrderRefresh);
    on<OrderLoadEarnings>(_onOrderLoadEarnings);
    on<OrderErrorCleared>(_onOrderErrorCleared);
  }

  // Method to set current context from UI
  void setCurrentContext(OrderViewContext context) {
    _currentContext = context;
  }

  Future<void> _onOrderLoadAvailable(
      OrderLoadAvailable event,
      Emitter<OrderState> emit,
      ) async {
    _currentContext = OrderViewContext.available;

    // Prevent duplicate loading
    if (_isLoadingAvailable && !event.forceReload) return;

    // Return cached data if available and not forcing reload and not refreshing
    if (_cachedAvailableOrders != null && !event.forceReload && !_isRefreshing) {
      if (_cachedAvailableOrders!.isEmpty) {
        emit(const OrderEmpty('No orders available at the moment'));
      } else {
        emit(OrderAvailableLoaded(_cachedAvailableOrders!));
      }
      return;
    }

    try {
      _isLoadingAvailable = true;
      if (!_isRefreshing) {
        emit(const OrderLoading());
      }

      final orders = await _orderRepository.getAvailableOrders();
      _cachedAvailableOrders = orders;

      if (orders.isEmpty) {
        emit(const OrderEmpty('No orders available at the moment'));
      } else {
        emit(OrderAvailableLoaded(orders));
      }
    } catch (e) {
      emit(OrderError('Failed to load available orders: ${e.toString()}'));
    } finally {
      _isLoadingAvailable = false;
    }
  }

  Future<void> _onOrderLoadActive(
      OrderLoadActive event,
      Emitter<OrderState> emit,
      ) async {
    _currentContext = OrderViewContext.active;

    // Prevent duplicate loading
    if (_isLoadingActive && !event.forceReload) return;

    // Return cached data if available and not forcing reload and not refreshing
    if (_cachedActiveOrders != null && !event.forceReload && !_isRefreshing) {
      if (_cachedActiveOrders!.isEmpty) {
        emit(const OrderEmpty('No active orders'));
      } else {
        emit(OrderActiveLoaded(_cachedActiveOrders!));
      }
      return;
    }

    try {
      _isLoadingActive = true;
      if (!_isRefreshing) {
        emit(const OrderLoading());
      }

      final orders = await _orderRepository.getActiveOrders();
      _cachedActiveOrders = orders;

      if (orders.isEmpty) {
        emit(const OrderEmpty('No active orders'));
      } else {
        emit(OrderActiveLoaded(orders));
      }
    } catch (e) {
      emit(OrderError('Failed to load active orders: ${e.toString()}'));
    } finally {
      _isLoadingActive = false;
    }
  }

  Future<void> _onOrderLoadHistory(
      OrderLoadHistory event,
      Emitter<OrderState> emit,
      ) async {
    _currentContext = OrderViewContext.history;

    // Prevent duplicate loading
    if (_isLoadingHistory && !event.forceReload) return;

    // Return cached data if available and not forcing reload and not refreshing
    if (_cachedOrderHistory != null && !event.forceReload && !_isRefreshing) {
      if (_cachedOrderHistory!.isEmpty) {
        emit(const OrderEmpty('No order history'));
      } else {
        emit(OrderHistoryLoaded(_cachedOrderHistory!));
      }
      return;
    }

    try {
      _isLoadingHistory = true;
      if (!_isRefreshing) {
        emit(const OrderLoading());
      }

      final orders = await _orderRepository.getOrderHistory();
      _cachedOrderHistory = orders;

      if (orders.isEmpty) {
        emit(const OrderEmpty('No order history'));
      } else {
        emit(OrderHistoryLoaded(orders));
      }
    } catch (e) {
      emit(OrderError('Failed to load order history: ${e.toString()}'));
    } finally {
      _isLoadingHistory = false;
    }
  }

  Future<void> _onOrderAccept(
      OrderAccept event,
      Emitter<OrderState> emit,
      ) async {
    // Prevent duplicate accept operations
    if (_ordersBeingAccepted.contains(event.orderId)) return;

    try {
      _ordersBeingAccepted.add(event.orderId);
      emit(OrderAccepting(event.orderId));

      final acceptedOrder = await _orderRepository.acceptOrder(event.orderId);

      // Update caches atomically
      _updateCachesAfterAccept(event.orderId, acceptedOrder);

      emit(OrderAccepted(acceptedOrder));

      // Emit updated state based on current context
      await _emitUpdatedStateAfterAccept(emit);

    } catch (e) {
      emit(OrderError('Failed to accept order: ${e.toString()}'));
    } finally {
      _ordersBeingAccepted.remove(event.orderId);
    }
  }

  void _updateCachesAfterAccept(String orderId, Order acceptedOrder) {
    // Remove from available orders cache
    if (_cachedAvailableOrders != null) {
      _cachedAvailableOrders!.removeWhere((order) => order.id == orderId);
    }

    // Add to active orders cache with proper sorting
    if (_cachedActiveOrders != null) {
      _cachedActiveOrders!.add(acceptedOrder);
      _sortActiveOrders();
    } else {
      _cachedActiveOrders = [acceptedOrder];
    }
  }

  Future<void> _emitUpdatedStateAfterAccept(Emitter<OrderState> emit) async {
    // Small delay to ensure UI can process the OrderAccepted state
    await Future.delayed(const Duration(milliseconds: 100));

    if (_currentContext == OrderViewContext.available) {
      // Update available orders view
      if (_cachedAvailableOrders != null) {
        if (_cachedAvailableOrders!.isEmpty) {
          emit(const OrderEmpty('No orders available at the moment'));
        } else {
          emit(OrderAvailableLoaded(_cachedAvailableOrders!));
        }
      }
    } else if (_currentContext == OrderViewContext.active) {
      // Update active orders view
      if (_cachedActiveOrders != null) {
        if (_cachedActiveOrders!.isEmpty) {
          emit(const OrderEmpty('No active orders'));
        } else {
          emit(OrderActiveLoaded(_cachedActiveOrders!));
        }
      }
    }
  }

  Future<void> _onOrderDecline(
      OrderDecline event,
      Emitter<OrderState> emit,
      ) async {
    // Prevent duplicate decline operations
    if (_ordersBeingDeclined.contains(event.orderId)) return;

    try {
      _ordersBeingDeclined.add(event.orderId);
      emit(OrderDeclining(event.orderId));

      await _orderRepository.declineOrder(event.orderId, reason: event.reason);

      // Update cache
      if (_cachedAvailableOrders != null) {
        _cachedAvailableOrders!.removeWhere((order) => order.id == event.orderId);
      }

      emit(OrderDeclined(event.orderId, 'Order declined successfully'));

      // Update available orders view if currently viewing
      if (_currentContext == OrderViewContext.available) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_cachedAvailableOrders != null) {
          if (_cachedAvailableOrders!.isEmpty) {
            emit(const OrderEmpty('No orders available at the moment'));
          } else {
            emit(OrderAvailableLoaded(_cachedAvailableOrders!));
          }
        }
      }

    } catch (e) {
      emit(OrderError('Failed to decline order: ${e.toString()}'));
    } finally {
      _ordersBeingDeclined.remove(event.orderId);
    }
  }

  Future<void> _onOrderUpdateStatus(
      OrderUpdateStatus event,
      Emitter<OrderState> emit,
      ) async {
    // Prevent duplicate update operations
    if (_ordersBeingUpdated.contains(event.orderId)) return;

    try {
      _ordersBeingUpdated.add(event.orderId);
      emit(OrderStatusUpdating(
        orderId: event.orderId,
        status: event.status,
      ));

      final updatedOrder = await _orderRepository.updateOrderStatus(
        event.orderId,
        event.status,
      );

      // Update cache with new order status
      _updateCachesAfterStatusUpdate(event.orderId, event.status, updatedOrder);

      emit(OrderStatusUpdated(updatedOrder));

      // Update active orders view if currently viewing and order is still active
      if (_currentContext == OrderViewContext.active && event.status != OrderStatus.delivered) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_cachedActiveOrders != null) {
          if (_cachedActiveOrders!.isEmpty) {
            emit(const OrderEmpty('No active orders'));
          } else {
            emit(OrderActiveLoaded(_cachedActiveOrders!));
          }
        }
      }

    } catch (e) {
      emit(OrderError('Failed to update order status: ${e.toString()}'));
    } finally {
      _ordersBeingUpdated.remove(event.orderId);
    }
  }

  void _updateCachesAfterStatusUpdate(String orderId, OrderStatus status, Order updatedOrder) {
    if (_cachedActiveOrders != null) {
      final index = _cachedActiveOrders!.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        if (status == OrderStatus.delivered) {
          // Remove completed order from active cache
          _cachedActiveOrders!.removeAt(index);

          // Add to history cache if it exists
          if (_cachedOrderHistory != null) {
            _cachedOrderHistory!.insert(0, updatedOrder);
          }
        } else {
          // Update order status in cache and resort
          _cachedActiveOrders![index] = updatedOrder;
          _sortActiveOrders();
        }
      }
    }
  }

  void _sortActiveOrders() {
    if (_cachedActiveOrders == null) return;

    _cachedActiveOrders!.sort((a, b) {
      // First sort by status priority
      final statusPriority = {
        OrderStatus.inTransit: 0,
        OrderStatus.pickedUp: 1,
        OrderStatus.accepted: 2,
      };

      final aPriority = statusPriority[a.status] ?? 3;
      final bPriority = statusPriority[b.status] ?? 3;

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      // Then sort by creation time (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> _onOrderWatchAvailable(
      OrderWatchAvailable event,
      Emitter<OrderState> emit,
      ) async {
    try {
      await _availableOrdersSubscription?.cancel();

      _availableOrdersSubscription = _orderRepository
          .watchAvailableOrders()
          .listen((orders) {
        _cachedAvailableOrders = orders;
        if (_currentContext == OrderViewContext.available) {
          if (orders.isEmpty) {
            emit(const OrderEmpty('No orders available at the moment'));
          } else {
            emit(OrderAvailableLoaded(orders));
          }
        }
      });

      // Load initial data if not cached
      if (_cachedAvailableOrders == null) {
        add(const OrderLoadAvailable());
      }
    } catch (e) {
      emit(OrderError('Failed to watch available orders: ${e.toString()}'));
    }
  }

  Future<void> _onOrderWatchStatus(
      OrderWatchStatus event,
      Emitter<OrderState> emit,
      ) async {
    try {
      await _orderStatusSubscription?.cancel();

      _orderStatusSubscription = _orderRepository
          .watchOrderStatus(event.orderId)
          .listen((order) {
        // Update cache
        if (_cachedActiveOrders != null) {
          final index = _cachedActiveOrders!.indexWhere((o) => o.id == order.id);
          if (index != -1) {
            _cachedActiveOrders![index] = order;
            _sortActiveOrders();
          }
        }
        emit(OrderStatusUpdated(order));
      });
    } catch (e) {
      emit(OrderError('Failed to watch order status: ${e.toString()}'));
    }
  }

  Future<void> _onOrderStopWatching(
      OrderStopWatching event,
      Emitter<OrderState> emit,
      ) async {
    await _availableOrdersSubscription?.cancel();
    await _orderStatusSubscription?.cancel();
    _availableOrdersSubscription = null;
    _orderStatusSubscription = null;
  }

  Future<void> _onOrderRefresh(
      OrderRefresh event,
      Emitter<OrderState> emit,
      ) async {
    // Prevent multiple refresh operations
    if (_isRefreshing) return;

    try {
      _isRefreshing = true;

      // Store the previous state to determine what to refresh
      final previousState = state;

      // Clear relevant caches based on current context
      if (_currentContext == OrderViewContext.available) {
        _cachedAvailableOrders = null;
      } else if (_currentContext == OrderViewContext.active) {
        _cachedActiveOrders = null;
      } else if (_currentContext == OrderViewContext.history) {
        _cachedOrderHistory = null;
      } else if (_currentContext == OrderViewContext.earnings) {
        _cachedTodayEarnings = null;
        _cachedWeeklyEarnings = null;
        _cachedMonthlyEarnings = null;
      }

      // Refresh based on context
      if (_currentContext == OrderViewContext.available ||
          previousState is OrderAvailableLoaded ||
          (previousState is OrderEmpty && (previousState as OrderEmpty).message.contains('available'))) {
        await _refreshAvailableOrders(emit);
      } else if (_currentContext == OrderViewContext.active ||
          previousState is OrderActiveLoaded ||
          (previousState is OrderEmpty && (previousState as OrderEmpty).message.contains('active'))) {
        await _refreshActiveOrders(emit);
      } else if (previousState is OrderHistoryLoaded) {
        await _refreshOrderHistory(emit);
      } else if (previousState is OrderEarningsLoaded) {
        await _refreshEarnings(emit);
      } else {
        // Default case - refresh active orders
        await _refreshActiveOrders(emit);
      }
    } finally {
      _isRefreshing = false;
    }
  }

  // Helper methods for specific refreshes
  Future<void> _refreshAvailableOrders(Emitter<OrderState> emit) async {
    try {
      final orders = await _orderRepository.getAvailableOrders();
      _cachedAvailableOrders = orders;

      if (orders.isEmpty) {
        emit(const OrderEmpty('No orders available at the moment'));
      } else {
        emit(OrderAvailableLoaded(orders));
      }
    } catch (e) {
      emit(OrderError('Failed to refresh available orders: ${e.toString()}'));
    }
  }

  Future<void> _refreshActiveOrders(Emitter<OrderState> emit) async {
    try {
      final orders = await _orderRepository.getActiveOrders();
      _cachedActiveOrders = orders;

      if (orders.isEmpty) {
        emit(const OrderEmpty('No active orders'));
      } else {
        emit(OrderActiveLoaded(orders));
      }
    } catch (e) {
      emit(OrderError('Failed to refresh active orders: ${e.toString()}'));
    }
  }

  Future<void> _refreshOrderHistory(Emitter<OrderState> emit) async {
    try {
      final orders = await _orderRepository.getOrderHistory();
      _cachedOrderHistory = orders;

      if (orders.isEmpty) {
        emit(const OrderEmpty('No order history'));
      } else {
        emit(OrderHistoryLoaded(orders));
      }
    } catch (e) {
      emit(OrderError('Failed to refresh order history: ${e.toString()}'));
    }
  }

  Future<void> _refreshEarnings(Emitter<OrderState> emit) async {
    try {
      final todayEarnings = await _orderRepository.getTodayEarnings();
      final weeklyEarnings = await _orderRepository.getWeeklyEarnings();
      final monthlyEarnings = await _orderRepository.getMonthlyEarnings();

      _cachedTodayEarnings = todayEarnings ?? {'totalEarnings': 0.0, 'totalDeliveries': 0.0};
      _cachedWeeklyEarnings = weeklyEarnings ?? {'totalEarnings': 0.0, 'totalDeliveries': 0.0};
      _cachedMonthlyEarnings = monthlyEarnings ?? {'totalEarnings': 0.0, 'totalDeliveries': 0.0};

      emit(OrderEarningsLoaded(
        todayEarnings: _cachedTodayEarnings!,
        weeklyEarnings: _cachedWeeklyEarnings!,
        monthlyEarnings: _cachedMonthlyEarnings!,
      ));
    } catch (e) {
      emit(OrderError('Failed to refresh earnings: ${e.toString()}'));
    }
  }

  Future<void> _onOrderLoadEarnings(
      OrderLoadEarnings event,
      Emitter<OrderState> emit,
      ) async {
    _currentContext = OrderViewContext.earnings;

    // Prevent duplicate loading
    if (_isLoadingEarnings && !event.forceReload) return;

    // Return cached data if available and not forcing reload and not refreshing
    if (_cachedTodayEarnings != null &&
        _cachedWeeklyEarnings != null &&
        _cachedMonthlyEarnings != null &&
        !event.forceReload &&
        !_isRefreshing) {
      emit(OrderEarningsLoaded(
        todayEarnings: _cachedTodayEarnings!,
        weeklyEarnings: _cachedWeeklyEarnings!,
        monthlyEarnings: _cachedMonthlyEarnings!,
      ));
      return;
    }

    try {
      _isLoadingEarnings = true;
      if (!_isRefreshing) {
        emit(const OrderLoading());
      }

      final todayEarnings = await _orderRepository.getTodayEarnings();
      final weeklyEarnings = await _orderRepository.getWeeklyEarnings();
      final monthlyEarnings = await _orderRepository.getMonthlyEarnings();

      // Cache the results
      _cachedTodayEarnings = todayEarnings ?? {'totalEarnings': 0.0, 'totalDeliveries': 0.0};
      _cachedWeeklyEarnings = weeklyEarnings ?? {'totalEarnings': 0.0, 'totalDeliveries': 0.0};
      _cachedMonthlyEarnings = monthlyEarnings ?? {'totalEarnings': 0.0, 'totalDeliveries': 0.0};

      emit(OrderEarningsLoaded(
        todayEarnings: _cachedTodayEarnings!,
        weeklyEarnings: _cachedWeeklyEarnings!,
        monthlyEarnings: _cachedMonthlyEarnings!,
      ));
    } catch (e, stackTrace) {
      print('Error loading earnings: $e');
      print('Stack trace: $stackTrace');
      emit(OrderError('Failed to load earnings: ${e.toString()}'));
    } finally {
      _isLoadingEarnings = false;
    }
  }

  Future<void> _onOrderErrorCleared(
      OrderErrorCleared event,
      Emitter<OrderState> emit,
      ) async {
    // Return to initial state, but don't automatically reload
    emit(const OrderInitial());
  }

  // Helper methods for state detection
  bool _isCurrentlyViewingAvailable() {
    return _currentContext == OrderViewContext.available ||
        state is OrderAvailableLoaded ||
        (state is OrderEmpty && (state as OrderEmpty).message.contains('available'));
  }

  bool _isCurrentlyViewingActive() {
    return _currentContext == OrderViewContext.active ||
        state is OrderActiveLoaded ||
        (state is OrderEmpty && (state as OrderEmpty).message.contains('active'));
  }

  // Helper method to invalidate specific cache
  void invalidateCache({
    bool available = false,
    bool active = false,
    bool history = false,
    bool earnings = false,
  }) {
    if (available) _cachedAvailableOrders = null;
    if (active) _cachedActiveOrders = null;
    if (history) _cachedOrderHistory = null;
    if (earnings) {
      _cachedTodayEarnings = null;
      _cachedWeeklyEarnings = null;
      _cachedMonthlyEarnings = null;
    }
  }

  // Helper method to get cached data without triggering loads
  List<Order>? get cachedAvailableOrders => _cachedAvailableOrders;
  List<Order>? get cachedActiveOrders => _cachedActiveOrders;
  List<Order>? get cachedOrderHistory => _cachedOrderHistory;

  // Helper to check if currently refreshing
  bool get isRefreshing => _isRefreshing;

  // Current context getter
  OrderViewContext get currentContext => _currentContext;

  // Helper methods to check operation status
  bool isOrderBeingAccepted(String orderId) => _ordersBeingAccepted.contains(orderId);
  bool isOrderBeingDeclined(String orderId) => _ordersBeingDeclined.contains(orderId);
  bool isOrderBeingUpdated(String orderId) => _ordersBeingUpdated.contains(orderId);

  @override
  Future<void> close() {
    _availableOrdersSubscription?.cancel();
    _orderStatusSubscription?.cancel();
    return super.close();
  }
}

// Context enum for tracking which screen is active
enum OrderViewContext {
  unknown,
  available,
  active,
  history,
  earnings,
}


