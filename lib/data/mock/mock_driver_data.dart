  import 'package:google_maps_flutter/google_maps_flutter.dart';
  import '../models/driver_model.dart';
  import '../models/earnings_model.dart';

  class MockDriverData {
    static Driver get currentDriver => Driver(
      id: 'driver_001',
      name: 'John Smith',
      email: 'john.smith@driver.com',
      phone: '+1 (555) 123-4567',
      vehicleType: 'Car',
      vehicleNumber: 'ABC-1234',
      rating: 4.8,
      isOnline: false,
      currentLocation: const LatLng(37.7749, -122.4194), // San Francisco
      profileImage: null,
      totalTrips: 245,
      totalEarnings: 2150.75,
      joinDate: DateTime(2023, 6, 15),
    );

    static List<Driver> get allDrivers => [
      currentDriver,
      Driver(
        id: 'driver_002',
        name: 'Sarah Johnson',
        email: 'sarah.j@driver.com',
        phone: '+1 (555) 234-5678',
        vehicleType: 'Motorcycle',
        vehicleNumber: 'XYZ-5678',
        rating: 4.9,
        isOnline: true,
        currentLocation: const LatLng(37.7849, -122.4094),
        totalTrips: 189,
        totalEarnings: 1875.50,
        joinDate: DateTime(2023, 8, 20),
      ),
      Driver(
        id: 'driver_003',
        name: 'Mike Chen',
        email: 'mike.chen@driver.com',
        phone: '+1 (555) 345-6789',
        vehicleType: 'Bicycle',
        vehicleNumber: 'BIC-9012',
        rating: 4.7,
        isOnline: true,
        currentLocation: const LatLng(37.7649, -122.4294),
        totalTrips: 156,
        totalEarnings: 1245.25,
        joinDate: DateTime(2023, 9, 10),
      ),
    ];
  // Enhanced earnings data for analytics
    static List<EarningsData> get weeklyEarningsData => [
      EarningsData(
        totalEarnings: 45.50,
        totalDeliveries: 4,
        averageEarning: 11.38,
        basePay: 32.00,
        tips: 11.50,
        bonuses: 2.00,
        date: DateTime.now().subtract(const Duration(days: 6)),
      ),
      EarningsData(
        totalEarnings: 67.75,
        totalDeliveries: 6,
        averageEarning: 11.29,
        basePay: 48.00,
        tips: 17.75,
        bonuses: 2.00,
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      EarningsData(
        totalEarnings: 52.25,
        totalDeliveries: 5,
        averageEarning: 10.45,
        basePay: 40.00,
        tips: 10.25,
        bonuses: 2.00,
        date: DateTime.now().subtract(const Duration(days: 4)),
      ),
      EarningsData(
        totalEarnings: 78.50,
        totalDeliveries: 7,
        averageEarning: 11.21,
        basePay: 56.00,
        tips: 20.50,
        bonuses: 2.00,
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
      EarningsData(
        totalEarnings: 92.25,
        totalDeliveries: 8,
        averageEarning: 11.53,
        basePay: 64.00,
        tips: 26.25,
        bonuses: 2.00,
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      EarningsData(
        totalEarnings: 115.75,
        totalDeliveries: 10,
        averageEarning: 11.58,
        basePay: 80.00,
        tips: 33.75,
        bonuses: 2.00,
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      EarningsData(
        totalEarnings: 24.75,
        totalDeliveries: 6,
        averageEarning: 4.13,
        basePay: 20.00,
        tips: 4.75,
        bonuses: 0.00,
        date: DateTime.now(),
      ),
    ];

    static List<GoalData> get currentGoals => [
      GoalData(
        id: 'daily_goal_1',
        title: 'Daily Earning Goal',
        targetAmount: 100.00,
        currentAmount: 24.75,
        deadline: DateTime.now().add(const Duration(hours: 8)),
        type: GoalType.daily,
        isCompleted: false,
      ),
      GoalData(
        id: 'weekly_goal_1',
        title: 'Weekly Earning Goal',
        targetAmount: 600.00,
        currentAmount: 476.75,
        deadline: DateTime.now().add(const Duration(days: 1)),
        type: GoalType.weekly,
        isCompleted: false,
      ),
      GoalData(
        id: 'monthly_goal_1',
        title: 'Monthly Target',
        targetAmount: 2500.00,
        currentAmount: 2100.00,
        deadline: DateTime.now().add(const Duration(days: 8)),
        type: GoalType.monthly,
        isCompleted: false,
      ),
      GoalData(
        id: 'completed_goal_1',
        title: '50 Deliveries Challenge',
        targetAmount: 50.00,
        currentAmount: 50.00,
        deadline: DateTime.now().subtract(const Duration(days: 2)),
        type: GoalType.custom,
        isCompleted: true,
      ),
    ];
    // Mock credentials for testing
    static const String mockEmail = 'john.smith@driver.com';
    static const String mockPassword = '123456';
    static const String mockPhone = '+1 (555) 123-4567';
  }