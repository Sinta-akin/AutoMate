import 'package:automate/features/vehicle_rental/models/vehicle_listing.dart';

/// Frontend-only service layer for Vehicle Rental listings.
///
/// This class acts as a "bridge" between the UI screens and the backend.
/// Right now it uses an in-memory list (mock data) so the app works
/// without a real backend. When the Node.js API is ready, only this
/// file needs to change — the screens stay the same.
///
/// Teacher concept: Separation of Concerns — UI does not talk to data
/// directly; it goes through a service.
class VehicleService {
  // ── Singleton pattern ──────────────────────────────────────────────
  // Only ONE instance of VehicleService exists in the whole app.
  // This keeps the mock data consistent across all screens.
  static final VehicleService _instance = VehicleService._internal();
  factory VehicleService() => _instance;
  VehicleService._internal();

  // ── Mock in-memory database ────────────────────────────────────────
  // A simple list that acts like our "database" while the backend is
  // not connected.  Listings are stored here during the app session.
  final List<VehicleListing> _listings = [
    VehicleListing(
      id: 'mock-001',
      title: 'Toyota Corolla 2020',
      pricePerDay: 2500,
      seats: 5,
      description: 'A reliable sedan in excellent condition. Perfect for city drives and long trips.',
      pickupLocation: 'Kathmandu, Thamel',
      imagePaths: [],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    VehicleListing(
      id: 'mock-002',
      title: 'Honda CR-V 2022',
      pricePerDay: 4000,
      seats: 7,
      description: 'Spacious SUV with great fuel efficiency. Ideal for family trips.',
      pickupLocation: 'Lalitpur, Pulchowk',
      imagePaths: [],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // ── CRUD Operations ────────────────────────────────────────────────

  /// Returns all listings owned by the current user (simulated).
  /// In a real app this would call: GET /api/listings/my-listings
  List<VehicleListing> getMyListings() {
    // Return a copy of the list so outside code cannot mutate it directly.
    return List.unmodifiable(_listings);
  }

  /// Creates a new listing and adds it to the in-memory list.
  /// In a real app this would call: POST /api/listings
  Future<VehicleListing> createListing({
    required String title,
    required double pricePerDay,
    required int seats,
    required String description,
    required String pickupLocation,
    required List<String> imagePaths,
  }) async {
    // Simulate a small network delay so the loading indicator is visible.
    await Future.delayed(const Duration(milliseconds: 800));

    final newListing = VehicleListing(
      // Simple unique ID: timestamp-based, good enough for mock.
      id: 'listing-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      pricePerDay: pricePerDay,
      seats: seats,
      description: description,
      pickupLocation: pickupLocation,
      imagePaths: imagePaths,
    );

    _listings.insert(0, newListing); // newest first
    return newListing;
  }

  /// Updates an existing listing.
  /// In a real app this would call: PUT /api/listings/:id
  Future<VehicleListing> updateListing({
    required String id,
    required String title,
    required double pricePerDay,
    required int seats,
    required String description,
    required String pickupLocation,
    required List<String> imagePaths,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final index = _listings.indexWhere((l) => l.id == id);
    if (index == -1) throw Exception('Listing not found');

    final updated = _listings[index].copyWith(
      title: title,
      pricePerDay: pricePerDay,
      seats: seats,
      description: description,
      pickupLocation: pickupLocation,
      imagePaths: imagePaths,
    );
    _listings[index] = updated;
    return updated;
  }

  /// Deletes a listing by its ID.
  /// In a real app this would call: DELETE /api/listings/:id
  Future<void> deleteListing(String id) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _listings.removeWhere((l) => l.id == id);
  }
}
