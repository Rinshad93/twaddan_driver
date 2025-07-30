import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/services/mock_auth_service.dart';
import '../../data/services/mock_order_service.dart';
import '../../data/services/mock_location_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Repositories
  late final AuthRepository _authRepository;
  late final OrderRepository _orderRepository;
  late final LocationRepository _locationRepository;

  bool _initialized = false;

  void initialize() {
    if (_initialized) return;

    _authRepository = MockAuthService();
    _orderRepository = MockOrderService();
    _locationRepository = MockLocationService();

    _initialized = true;
  }

  // Getters
  AuthRepository get authRepository {
    if (!_initialized) {
      throw Exception('ServiceLocator not initialized. Call initialize() first.');
    }
    return _authRepository;
  }

  OrderRepository get orderRepository {
    if (!_initialized) {
      throw Exception('ServiceLocator not initialized. Call initialize() first.');
    }
    return _orderRepository;
  }

  LocationRepository get locationRepository {
    if (!_initialized) {
      throw Exception('ServiceLocator not initialized. Call initialize() first.');
    }
    return _locationRepository;
  }

  void dispose() {
    if (_orderRepository is MockOrderService) {
      (_orderRepository as MockOrderService).dispose();
    }
    if (_locationRepository is MockLocationService) {
      (_locationRepository as MockLocationService).dispose();
    }
    _initialized = false;
  }
}