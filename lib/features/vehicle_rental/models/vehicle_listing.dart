/// Model class representing a vehicle rental listing.
/// This is a simple data class (like a blueprint) that holds
/// all the information about one vehicle listing.
class VehicleListing {
  final String id;
  final String title;
  final double pricePerDay;
  final int seats;
  final String description;
  final String pickupLocation;
  // We store image paths as strings (file paths or URLs).
  // For now these are local file paths selected by image_picker.
  final List<String> imagePaths;
  final bool isAvailable;
  final DateTime createdAt;

  VehicleListing({
    required this.id,
    required this.title,
    required this.pricePerDay,
    required this.seats,
    required this.description,
    required this.pickupLocation,
    required this.imagePaths,
    this.isAvailable = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a copy of this listing with updated fields.
  /// This is a common Dart pattern — instead of mutating the object,
  /// we create a new one with the changed values.
  VehicleListing copyWith({
    String? id,
    String? title,
    double? pricePerDay,
    int? seats,
    String? description,
    String? pickupLocation,
    List<String>? imagePaths,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return VehicleListing(
      id: id ?? this.id,
      title: title ?? this.title,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      seats: seats ?? this.seats,
      description: description ?? this.description,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      imagePaths: imagePaths ?? this.imagePaths,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
