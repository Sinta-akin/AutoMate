import 'dart:io';
import 'package:flutter/material.dart';
import 'package:automate/core/constants/app_constants.dart';
import 'package:automate/core/theme/app_theme.dart';
import 'package:automate/core/widgets/common_widgets.dart';
import 'package:automate/features/vehicle_rental/models/vehicle_listing.dart';
import 'package:automate/features/vehicle_rental/services/vehicle_service.dart';

/// Screen showing all listings created by the current vehicle owner.
///
/// This screen is the entry point for the Vehicle Rental feature set.
/// From here the owner can:
///  - See all their listings (US-V2-01 requirement: listings appear in search)
///  - Tap "Create Listing" to add a new one (US-V2-01)
///  - Tap a listing card to edit or delete it (US-V2-03)
///
/// Teacher concepts:
/// - StatefulWidget + setState() for reactive list updates
/// - ListView.builder for rendering a dynamic list efficiently
/// - Navigator.pushNamed + await + result handling
/// - Extracting widgets into smaller private classes (clean code)
class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final _vehicleService = VehicleService();

  // The list of listings is stored here in state.
  // Every time we create/edit/delete we call _loadListings() to refresh.
  List<VehicleListing> _listings = [];

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  /// Fetches listings from the service and updates the UI.
  void _loadListings() {
    setState(() {
      _listings = List.from(_vehicleService.getMyListings());
    });
  }

  /// Navigates to CreateListingScreen and refreshes if a listing was created.
  Future<void> _goToCreate() async {
    // push returns whatever Navigator.pop(context, value) sends back
    final result = await Navigator.pushNamed(context, AppConstants.createListing);
    if (result == true) {
      _loadListings(); // refresh the list
    }
  }

  /// Navigates to EditListingScreen passing the selected listing as an argument.
  Future<void> _goToEdit(VehicleListing listing) async {
    // We use pushNamed with arguments — the router extracts it in onGenerateRoute.
    final result = await Navigator.pushNamed(
      context,
      AppConstants.editListing,
      arguments: listing,
    );
    // 'true' means updated, 'deleted' means removed
    if (result == true || result == 'deleted') {
      _loadListings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: const AppHeader(title: 'My Listings', showBack: true),
      // Floating action button — tap to create a new listing
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreate,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Listing',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _listings.isEmpty
          ? _EmptyState(onCreateTap: _goToCreate)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _listings.length,
              itemBuilder: (context, index) {
                return _ListingCard(
                  listing: _listings[index],
                  onTap: () => _goToEdit(_listings[index]),
                );
              },
            ),
    );
  }
}

// ── Private widget: Empty state ───────────────────────────────────────────
/// Shown when the owner has no listings yet.
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                color: AppTheme.textSecondary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No listings yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first vehicle listing and start earning from your car.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              text: 'Create First Listing',
              onPressed: onCreateTap,
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private widget: Listing card ──────────────────────────────────────────
/// Shows a summary card for one vehicle listing.
/// Tapping it opens the Edit screen.
class _ListingCard extends StatelessWidget {
  final VehicleListing listing;
  final VoidCallback onTap;

  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            // Cover image or placeholder
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMd),
                bottomLeft: Radius.circular(AppTheme.radiusMd),
              ),
              child: _buildCoverImage(),
            ),

            // Details section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + edit icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.edit_outlined,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Price
                    Row(
                      children: [
                        const Icon(Icons.currency_rupee,
                            size: 14, color: AppTheme.accentOrange),
                        Text(
                          '${listing.pricePerDay.toStringAsFixed(0)} / day',
                          style: const TextStyle(
                            color: AppTheme.accentOrange,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Location + seats in one row
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            listing.pickupLocation,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.event_seat_outlined,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '${listing.seats} seats',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Available / Booked chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: listing.isAvailable
                            ? AppTheme.successGreen.withValues(alpha: 0.15)
                            : AppTheme.errorRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        listing.isAvailable ? 'Available' : 'Booked',
                        style: TextStyle(
                          color: listing.isAvailable
                              ? AppTheme.successGreen
                              : AppTheme.errorRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    if (listing.imagePaths.isNotEmpty) {
      final path = listing.imagePaths.first;
      final isLocal = path.startsWith('/') || path.contains(':\\');
      final file = File(path);

      if (isLocal && file.existsSync()) {
        return Image.file(file,
            width: 110, height: 110, fit: BoxFit.cover);
      }
    }
    // Placeholder when no image is available
    return Container(
      width: 110,
      height: 110,
      color: const Color(0xFF2A2A2A),
      child: const Icon(
        Icons.directions_car,
        color: AppTheme.textSecondary,
        size: 36,
      ),
    );
  }
}
