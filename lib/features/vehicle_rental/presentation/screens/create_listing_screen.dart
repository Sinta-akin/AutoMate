import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:automate/core/constants/app_constants.dart';
import 'package:automate/core/theme/app_theme.dart';
import 'package:automate/core/widgets/common_widgets.dart';
import 'package:automate/features/vehicle_rental/services/vehicle_service.dart';

/// Screen for creating a new vehicle rental listing.
///
/// User Story US-V2-01: "As Rina, I want to create a rental listing for my
/// car so that I can earn from it on days I am not using it."
///
/// User Story US-V2-02 (image upload) is also handled here — the
/// multi-image picker section is part of this creation form.
///
/// Teacher concepts used:
/// - StatefulWidget + setState() for reactive UI
/// - GlobalKey(FormState) + Form + TextFormField for validation
/// - TextEditingController for reading field values
/// - dispose() to free controllers and avoid memory leaks
/// - image_picker package for selecting images from the gallery
/// - Navigator.pop() to go back after saving
class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  // ── Form key: used to trigger validation on all fields at once ──────
  final _formKey = GlobalKey<FormState>();

  // ── Controllers: each TextEditingController is linked to one field ──
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  // ── State variables ─────────────────────────────────────────────────
  // Stores the file paths of images the user has picked.
  // We use XFile (from image_picker) which gives us the path.
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  // Max images allowed per listing (Acceptance Criteria: max 6)
  static const int _maxImages = 6;

  final _vehicleService = VehicleService();
  final _imagePicker = ImagePicker();

  // ── Dispose: always clean up controllers to prevent memory leaks ────
  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ── Pick images from gallery ─────────────────────────────────────────
  /// Called when the user taps "Add Photos".
  /// image_picker lets us open the device gallery and select images.
  Future<void> _pickImages() async {
    // Check limit before opening picker
    if (_selectedImages.length >= _maxImages) {
      _showSnackBar('Maximum $_maxImages images allowed', isError: true);
      return;
    }

    // pickMultiImage opens the gallery and lets user select multiple images
    final List<XFile> picked = await _imagePicker.pickMultiImage(
      imageQuality: 80, // compress to 80% to keep file size low
    );

    if (picked.isEmpty) return; // user cancelled

    // Calculate how many more images we can still add
    final remaining = _maxImages - _selectedImages.length;
    final toAdd = picked.length > remaining ? picked.sublist(0, remaining) : picked;

    setState(() {
      _selectedImages = [..._selectedImages, ...toAdd];
    });

    if (picked.length > remaining) {
      _showSnackBar(
        'Only $remaining more image(s) added. Max $_maxImages reached.',
        isError: false,
      );
    }
  }

  /// Remove a single image from the selection.
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // ── Submit the form ───────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    // Trigger validation on every field
    if (!_formKey.currentState!.validate()) return;

    // Acceptance Criteria: Given I am not a Vehicle Owner,
    // I cannot reach the create screen. (enforced at navigation level)
    // Here we just check the form is complete.

    setState(() => _isLoading = true);

    try {
      await _vehicleService.createListing(
        title: _titleController.text.trim(),
        pricePerDay: double.parse(_priceController.text.trim()),
        seats: int.parse(_seatsController.text.trim()),
        description: _descriptionController.text.trim(),
        pickupLocation: _locationController.text.trim(),
        imagePaths: _selectedImages.map((f) => f.path).toList(),
      );

      if (!mounted) return;
      _showSnackBar('Listing created successfully!');
      // Go back to My Listings screen after successful creation
      Navigator.pop(context, true); // pass 'true' so parent can refresh
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to create listing. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: const AppHeader(title: 'Create Listing'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section: Vehicle Details ────────────────────────────
              _SectionLabel(label: 'Vehicle Details'),
              const SizedBox(height: 12),

              // Title field
              _buildFormField(
                label: 'Title',
                hint: 'e.g. Toyota Corolla 2020',
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppConstants.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price per day field
              _buildFormField(
                label: 'Price per Day (NPR)',
                hint: 'e.g. 2500',
                controller: _priceController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.currency_rupee,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppConstants.requiredField;
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Seats field
              _buildFormField(
                label: 'Number of Seats',
                hint: 'e.g. 5',
                controller: _seatsController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.event_seat,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppConstants.requiredField;
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 1 || parsed > 20) {
                    return 'Enter a valid seat count (1–20)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pickup location field
              _buildFormField(
                label: 'Pickup Location',
                hint: 'e.g. Kathmandu, Thamel',
                controller: _locationController,
                prefixIcon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppConstants.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field (multi-line)
              _buildFormField(
                label: 'Description',
                hint: 'Describe your vehicle, its condition, and any special features...',
                controller: _descriptionController,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppConstants.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // ── Section: Vehicle Photos ─────────────────────────────
              _SectionLabel(label: 'Vehicle Photos'),
              const SizedBox(height: 4),
              Text(
                'Add up to $_maxImages photos. The first image becomes the cover photo.',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              // Image grid + add button
              _ImagePickerGrid(
                selectedImages: _selectedImages,
                maxImages: _maxImages,
                onAddTap: _pickImages,
                onRemove: _removeImage,
              ),
              const SizedBox(height: 32),

              // ── Submit button ───────────────────────────────────────
              PrimaryButton(
                text: 'Create Listing',
                onPressed: _handleSubmit,
                isLoading: _isLoading,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to build a styled form field — reuses the same decoration
  /// pattern so all fields look consistent (DRY principle).
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
/// A styled section header used to visually group form fields.
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

// ── Private widget: Image picker grid ────────────────────────────────────
/// Shows selected images in a grid with a "+" add button.
/// Acceptance Criteria:
///  - User can select multiple images at once (max 6)
///  - Each image can be removed before upload
///  - First image becomes cover photo
///  - Several images are shown in a grid
class _ImagePickerGrid extends StatelessWidget {
  final List<XFile> selectedImages;
  final int maxImages;
  final VoidCallback onAddTap;
  final void Function(int index) onRemove;

  const _ImagePickerGrid({
    required this.selectedImages,
    required this.maxImages,
    required this.onAddTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Show each selected image as a thumbnail with a remove "×" button
        ...List.generate(selectedImages.length, (index) {
          return _ImageThumbnail(
            imageFile: File(selectedImages[index].path),
            isCover: index == 0,
            onRemove: () => onRemove(index),
          );
        }),

        // Show the "+" add button only if we haven't reached the limit
        if (selectedImages.length < maxImages)
          _AddImageButton(onTap: onAddTap),
      ],
    );
  }
}

/// A single image thumbnail with cover badge and remove button.
class _ImageThumbnail extends StatelessWidget {
  final File imageFile;
  final bool isCover;
  final VoidCallback onRemove;

  const _ImageThumbnail({
    required this.imageFile,
    required this.isCover,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The image itself
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Image.file(
            imageFile,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),

        // Cover photo badge (first image only)
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
              child: const Text(
                'Cover',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // Remove (×) button in the top-right corner
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

/// The "+" button to add more images.
class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: AppTheme.border,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: AppTheme.textSecondary, size: 28),
            SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
