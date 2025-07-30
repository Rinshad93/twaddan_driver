import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_model.dart';
import '../mock/mock_driver_data.dart';
import '../repositories/auth_repository.dart';

class MockAuthService implements AuthRepository {
  static const String _driverKey = 'current_driver';
  static const String _isLoggedInKey = 'is_logged_in';

  @override
  Future<Driver> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Check mock credentials
    if (email == MockDriverData.mockEmail && password == MockDriverData.mockPassword) {
      final driver = MockDriverData.currentDriver;
      await saveDriver(driver);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);

      return driver;
    } else {
      throw Exception('Invalid email or password');
    }
  }

  @override
  Future<Driver> loginWithPhone(String phone, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Check mock credentials
    if (phone == MockDriverData.mockPhone && password == MockDriverData.mockPassword) {
      final driver = MockDriverData.currentDriver;
      await saveDriver(driver);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);

      return driver;
    } else {
      throw Exception('Invalid phone or password');
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_driverKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  @override
  Future<Driver?> getCurrentDriver() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverData = prefs.getString(_driverKey);

      if (driverData != null) {
        // In a real app, you would parse JSON here
        // For mock, return the mock driver
        return MockDriverData.currentDriver;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> saveDriver(Driver driver) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // In a real app, you would save JSON string
      // For mock, just save a flag
      await prefs.setString(_driverKey, driver.id);
    } catch (e) {
      throw Exception('Failed to save driver data');
    }
  }

  @override
  Future<Driver> updateDriverStatus(bool isOnline) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final currentDriver = MockDriverData.currentDriver;
    final updatedDriver = currentDriver.copyWith(isOnline: isOnline);

    await saveDriver(updatedDriver);
    return updatedDriver;
  }

  @override
  Future<Driver> updateDriver(Driver driver) async {
    await Future.delayed(const Duration(milliseconds: 600));

    await saveDriver(driver);
    return driver;
  }
}