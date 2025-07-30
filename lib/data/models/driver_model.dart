import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Driver extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;
  final double rating;
  final bool isOnline;
  final LatLng? currentLocation;
  final String? profileImage;
  final int totalTrips;
  final double totalEarnings;
  final DateTime joinDate;

  const Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.rating,
    required this.isOnline,
    this.currentLocation,
    this.profileImage,
    required this.totalTrips,
    required this.totalEarnings,
    required this.joinDate,
  });

  Driver copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? vehicleType,
    String? vehicleNumber,
    double? rating,
    bool? isOnline,
    LatLng? currentLocation,
    String? profileImage,
    int? totalTrips,
    double? totalEarnings,
    DateTime? joinDate,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      rating: rating ?? this.rating,
      isOnline: isOnline ?? this.isOnline,
      currentLocation: currentLocation ?? this.currentLocation,
      profileImage: profileImage ?? this.profileImage,
      totalTrips: totalTrips ?? this.totalTrips,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      joinDate: joinDate ?? this.joinDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'rating': rating,
      'isOnline': isOnline,
      'currentLocation': currentLocation != null
          ? {
        'latitude': currentLocation!.latitude,
        'longitude': currentLocation!.longitude,
      }
          : null,
      'profileImage': profileImage,
      'totalTrips': totalTrips,
      'totalEarnings': totalEarnings,
      'joinDate': joinDate.toIso8601String(),
    };
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      isOnline: json['isOnline'] ?? false,
      currentLocation: json['currentLocation'] != null
          ? LatLng(
        json['currentLocation']['latitude'].toDouble(),
        json['currentLocation']['longitude'].toDouble(),
      )
          : null,
      profileImage: json['profileImage'],
      totalTrips: json['totalTrips'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      joinDate: DateTime.parse(
        json['joinDate'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    vehicleType,
    vehicleNumber,
    rating,
    isOnline,
    currentLocation,
    profileImage,
    totalTrips,
    totalEarnings,
    joinDate,
  ];
}