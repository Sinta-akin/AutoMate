import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:automate/core/constants/app_constants.dart';
import 'package:automate/core/theme/app_theme.dart';
import 'package:automate/core/widgets/common_widgets.dart';
import 'package:automate/features/vehicle_rental/models/vehicle_listing.dart';
import 'package:automate/features/vehicle_rental/services/vehicle_service.dart';

/// Screen for editing or deleting an existing vehicle rental listing.
///
/// User Story US-V2-03: "As Rina, I want to edit or delete my listing so
/// that renters see correct prices and only vehicles I still offer."
///
/// Acceptance Criteria:
/// 1. Given an edit, then it shows on the details page at once.
/// 2. Given tap delete, then a confirmation is asked first.
/// 3. Given a listing with an Approved future booking, then delete is blocked
///    and a message explains why. (simulated here via isAvailable flag)
/// 4. Given a deleted listing, it disappears from search.
///
/// Teacher concepts:
/// - Reusing the same form pattern from CreateListingScreen (DRY)
/// - Passing data to a screen via constructor arguments
/// - showDialog for confirmation dialogs (AlertDialog)
/// - Navigator.pop with result to tell the caller something changed
class EditListingScreen extends StatefulWidget {
  /// The listing to edit is passed in from the previous screen.
  final VehicleListing listing;

  const EditListingScreen({super.key, required this.listing});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _seatsController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  // Track images: existing ones (paths from the listing) + newly picked
  late List<String> _existingImagePaths;
  List<XFile> _newImages = [];
  bool _isLoading = false;
  bool _isDeleting = false;

  static const int _maxImages = 6;

  final _vehicleService = VehicleService();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Pre-fill form fields with current listing values — good UX
    _titleController = TextEditingController(text: widget.listing.title);
    _priceController = TextEditingController(
        text: widget.listing.pricePerDay.toStringAsFixed(0));
    _seatsController =
        TextEditingController(text: widget.listing.seats.toString());
    _descriptionController =
        TextEditingController(text: widget.listing.description);
    _locationController =
        TextEditingController(text: widget.listing.pickupLocation);
    _existingImagePaths = List.from(widget.listing.imagePaths);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  int get _totalImages => _existingImagePaths.length + _newImages.length;

  Future<void> _pickMoreImages() async {
    if (_totalImages >= _maxImages) {
      _showSnackBar('Maximum $_maxImages images allowed', isError: true);
      return;
    }

    final List<XFile> picked = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;

    final remaining = _maxImages - _totalImages;
    final toAdd = picked.length > remaining ? picked.sublist(0, remaining) : picked;

    setState(() {
      _newImages = [..._newImages, ...toAdd];
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImagePaths.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  // ── Handle Save ───────────────────────────────────────────────────────
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Combine existing + new image paths
      final allImagePaths = [
        ..._existingImagePaths,
        ..._newImages.map((f) => f.path),
      ];

      await _vehicleService.updateListing(
        id: widget.listing.id,
        title: _titleController.text.trim(),
        pricePerDay: double.parse(_priceController.text.trim()),
        seats: int.parse(_seatsController.text.trim()),
        description: _descriptionController.text.trim(),
        pickupLocation: _locationController.text.trim(),
        imagePaths: allImagePaths,
      );

      if (!mounted) return;
      _showSnackBar('Listing updated successfully!');
      // Pass 'true' so MyListingsScreen knows to refresh
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to update listing.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Handle Delete ─────────────────────────────────────────────────────
  /// Shows a confirmation dialog before deleting.
  /// Acceptance Criteria: "Given tap delete, then a confirmation is asked first."
  Future<void> _handleDelete() async {
    // Acceptance Criteria: blocked if listing has an active booking (simulated)
    // In this demo we simulate it by checking a "has future booking" flag.
    // We'll check if listing is marked as unavailable (meaning it's booked).
    if (!widget.listing.isAvailable) {
      _showSnackBar(
        'Cannot delete: this listing has an approved future booking.',
        isError: true,
      );
      return;
    }

    // Show confirmation dialog — teacher concept: AlertDialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        title: const Text(
          'Delete Listing?',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this listing? This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          // Delete button — red to signal danger
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return; // User pressed Cancel

    setState(() => _isDeleting = true);

    try {
      await _vehicleService.deleteListing(widget.listing.id);
      if (!mounted) return;
      _showSnackBar('Listing deleted.');
      // Pass 'deleted' string so MyListingsScreen knows what happened
      Navigator.pop(context, 'deleted');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to delete listing.', isError: true);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Listing',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        // Delete button in app bar top-right
        actions: [
          _isDeleting
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.errorRed,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                  tooltip: 'Delete listing',
                  onPressed: _handleDelete,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section: Vehicle Details ────────────────────────────
              const _SectionLabel(label: 'Vehicle Details'),
              const SizedBox(height: 12),

              _buildFormField(
                label: 'Title',
                hint: 'e.g. Toyota Corolla 2020',
                controller: _titleController,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? AppConstants.requiredField : null,
              ),
              const SizedBox(height: 16),

              _buildFormField(
                label: 'Price per Day (NPR)',
                hint: 'e.g. 2500',
                controller: _priceController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.currency_rupee,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppConstants.requiredField;
                  final p = double.tryParse(v.trim());
                  if (p == null || p <= 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildFormField(
                label: 'Number of Seats',
                hint: 'e.g. 5',
                controller: _seatsController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.event_seat,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return AppConstants.requiredField;
                  final p = int.tryParse(v.trim());
                  if (p == null || p < 1) return 'Enter a valid seat count';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildFormField(
                label: 'Pickup Location',
                hint: 'e.g. Kathmandu, Thamel',
                controller: _locationController,
                prefixIcon: Icons.location_on,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? AppConstants.requiredField : null,
              ),
              const SizedBox(height: 16),

              _buildFormField(
                label: 'Description',
                hint: 'Describe your vehicle...',
                controller: _descriptionController,
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? AppConstants.requiredField : null,
              ),
              const SizedBox(height: 28),

              // ── Section: Vehicle Photos ─────────────────────────────
              const _SectionLabel(label: 'Vehicle Photos'),
              const SizedBox(height: 4),
              Text(
                'First image is the cover. Max $_maxImages photos total.',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),

              // Combined image grid: existing + new + add button
              _buildImageGrid(),
              const SizedBox(height: 32),

              // ── Save button ─────────────────────────────────────────
              PrimaryButton(
                text: 'Save Changes',
                onPressed: _handleSave,
                isLoading: _isLoading,
                icon: Icons.save_outlined,
              ),
              const SizedBox(height: 16),

              // ── Secondary delete button ─────────────────────────────
              SecondaryButton(
                text: 'Delete Listing',
                onPressed: _isDeleting ? null : _handleDelete,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Existing images (file path strings from the listing)
        ...List.generate(_existingImagePaths.length, (index) {
          final path = _existingImagePaths[index];
          final isCover = index == 0 && _existingImagePaths.isNotEmpty;
          return _ExistingImageThumbnail(
            imagePath: path,
            isCover: isCover,
            onRemove: () => _removeExistingImage(index),
          );
        }),

        // Newly picked images (XFile)
        ...List.generate(_newImages.length, (index) {
          final globalIndex = _existingImagePaths.length + index;
          final isCover = globalIndex == 0;
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: Image.file(
                  File(_newImages[index].path),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              if (isCover)
                _coverBadge(),
              _removeBadge(() => _removeNewImage(index)),
            ],
          );
        }),

        // Add more button
        if (_totalImages < _maxImages)
          GestureDetector(
            onTap: _pickMoreImages,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: AppTheme.textSecondary, size: 28),
                  SizedBox(height: 4),
                  Text('Add Photo',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _coverBadge() => Positioned(
        bottom: 4,
        left: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('Cover',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ),
      );

  Widget _removeBadge(VoidCallback onRemove) => Positioned(
        top: 4,
        right: 4,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ),
      );

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            filled: true,
            fillColor: AppTheme.surface,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: const Color(0xFF64748B), size: 20)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppTheme.errorRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: AppTheme.errorRed, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ── Private widget: Section label ─────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

// ── Private widget: Existing image thumbnail ───────────────────────────────
/// Shows an already-saved image. If the path is a URL we'd use
/// Image.network(); if it's a local path we use Image.file().
/// For now all are local paths from the mock, so we show a placeholder icon.
class _ExistingImageThumbnail extends StatelessWidget {
  final String imagePath;
  final bool isCover;
  final VoidCallback onRemove;

  const _ExistingImageThumbnail({
    required this.imagePath,
    required this.isCover,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Check if it looks like a local file path
    final isLocalFile = imagePath.startsWith('/') || imagePath.contains(':\\');
    final file = File(imagePath);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: isLocalFile && file.existsSync()
              ? Image.file(file, width: 100, height: 100, fit: BoxFit.cover)
              : Container(
                  width: 100,
                  height: 100,
                  color: AppTheme.surface,
                  child: const Icon(Icons.directions_car,
                      color: AppTheme.textSecondary, size: 36),
                ),
        ),
        if (isCover)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Cover',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
