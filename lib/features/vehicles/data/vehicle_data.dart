import 'package:flutter/material.dart';
import 'package:automate/core/constants/app_constants.dart';
import 'package:automate/features/vehicles/domain/vehicle.dart';

/// Hard-coded sample data. Replace with Firestore reads once the database
/// is ready (keep the same model classes).
abstract class VehicleData {
  static final List<VehicleCategory> categories = [
    VehicleCategory(
      id: 'hatchback',
      name: 'Hatchback',
      description: 'Compact and easy to park',
      icon: Icons.directions_car_filled,
    ),
    VehicleCategory(
      id: 'sedan',
      name: 'Sedan',
      description: 'Comfortable for city and highway',
      icon: Icons.directions_car,
    ),
    VehicleCategory(
      id: 'suv',
      name: 'SUV',
      description: 'Space and power for any road',
      icon: Icons.airport_shuttle,
    ),
    VehicleCategory(
      id: 'van',
      name: 'Van',
      description: 'Great for groups and cargo',
      icon: Icons.directions_bus,
    ),
    VehicleCategory(
      id: 'pickup',
      name: 'Pickup',
      description: 'Heavy loads and rough terrain',
      icon: Icons.local_shipping,
    ),
    VehicleCategory(
      id: 'bike',
      name: 'Bike',
      description: 'Fast and fuel efficient',
      icon: Icons.two_wheeler,
    ),
    VehicleCategory(
      id: 'scooter',
      name: 'Scooter',
      description: 'Easy city riding',
      icon: Icons.electric_scooter,
    ),
    VehicleCategory(
      id: 'luxury',
      name: 'Luxury',
      description: 'Premium rides for special days',
      icon: Icons.workspace_premium,
    ),
  ];

  /// Options for the questionnaire's "vehicle type" chips.
  static const List<String> vehicleTypes = [
    'Car',
    'SUV',
    'Van',
    'Bike',
    'Scooter',
    'Pickup',
  ];

  /// Options for the questionnaire's "primary use" chips.
  static const List<String> primaryUses = [
    'Daily commute',
    'Family trip',
    'Adventure',
    'Business',
    'Cargo / moving',
    'Special occasion',
  ];

  static DateTime _day(int offsetFromToday) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + offsetFromToday);
  }

  static Set<DateTime> _range(int from, int to) =>
      {for (var i = from; i <= to; i++) _day(i)};

  static final List<Vehicle> vehicles = [
    Vehicle(
      id: 'v1',
      title: 'Toyota Fortuner',
      model: '2022 Fortuner 4x4',
      categoryId: 'suv',
      categoryName: 'SUV',
      seats: 7,
      dailyPrice: 9500,
      images: const [
        AppConstants.landingHeroImage,
        AppConstants.serviceHeroImage,
        AppConstants.logo,
      ],
      description:
      'A spacious and powerful 7-seater SUV, perfect for family trips and '
          'mountain roads. Well maintained, regularly serviced and fully '
          'insured. Fuel is not included.',
      pickupLocation: 'Lazimpat, Kathmandu',
      ownerName: 'Rudra Sharma',
      unavailableDates: {..._range(3, 5), ..._range(12, 14)},
    ),
    Vehicle(
      id: 'v2',
      title: 'Suzuki Swift',
      model: '2021 Swift VXi',
      categoryId: 'hatchback',
      categoryName: 'Hatchback',
      seats: 5,
      dailyPrice: 3800,
      images: const [
        AppConstants.serviceHeroImage,
        AppConstants.landingHeroImage,
      ],
      description:
      'Fuel-efficient and easy to drive in the city. Ideal for daily '
          'commutes and short getaways.',
      pickupLocation: 'Jawalakhel, Lalitpur',
      ownerName: 'Anita Gurung',
      unavailableDates: {..._range(1, 2), _day(9)},
    ),
  ];

  static Vehicle? byId(String id) {
    for (final v in vehicles) {
      if (v.id == id) return v;
    }
    return null;
  }
}