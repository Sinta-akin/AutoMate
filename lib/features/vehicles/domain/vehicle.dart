import 'package:flutter/widgets.dart';

/// A vehicle category shown on the category selection screen.
class VehicleCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const VehicleCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

/// A vehicle listed for rent.
class Vehicle {
  final String id;
  final String title;
  final String model;
  final String categoryId;
  final String categoryName;
  final int seats;
  final int dailyPrice;
  final List<String> images; // asset paths or http(s) URLs
  final String description;
  final String pickupLocation;
  final String ownerName;

  /// Days (time stripped) on which the vehicle is already booked.
  final Set<DateTime> unavailableDates;

  const Vehicle({
    required this.id,
    required this.title,
    required this.model,
    required this.categoryId,
    required this.categoryName,
    required this.seats,
    required this.dailyPrice,
    required this.images,
    required this.description,
    required this.pickupLocation,
    required this.ownerName,
    this.unavailableDates = const {},
  });
}