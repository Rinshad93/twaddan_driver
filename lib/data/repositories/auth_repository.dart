import '../models/driver_model.dart';

abstract class AuthRepository {
  Future<Driver> login(String email, String password);
  Future<Driver> loginWithPhone(String phone, String password);
  Future<void> logout();
  Future<Driver?> getCurrentDriver();
  Future<bool> isLoggedIn();
  Future<void> saveDriver(Driver driver);
  Future<Driver> updateDriverStatus(bool isOnline);
  Future<Driver> updateDriver(Driver driver);
}