import 'dart:async';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:automate/core/constants/upload_config.dart';
import 'package:automate/core/theme/app_theme.dart';
import 'package:automate/core/widgets/common_widgets.dart';
import 'package:automate/features/profile/presentation/widgets/upload_area_widget.dart';

/// US-M1-08 – Profile Photo Upload.
///
/// Supports gallery, camera (where supported), device file picker, and
/// drag-and-drop. Enforces JPG/PNG only and compresses images locally
/// to fit within [UploadConfig.profilePhotoMaxBytes] (500 KB).
class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({super.key});

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  UploadStatus _status = UploadStatus.idle;
  double _uploadProgress = 0.0;
  Timer? _uploadTimer;

  SelectedFileData? _selectedPhoto;
  SelectedFileData? _uploadedPhoto;
  String? _errorMessage;
  bool _isCompressing = false;
  bool _simulateFailure = false;

  bool get _supportsCamera {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void dispose() {
    _uploadTimer?.cancel();
    super.dispose();
  }

  // ── Selection & Validation ────────────────────────────────────────────

  void _showSourcePicker() {
    if (_status == UploadStatus.uploading || _isCompressing) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Profile Photo', style: AppTheme.sectionHeading),
                const SizedBox(height: 4),
                Text(
                  'Accepted: JPG, PNG • Max ${UploadConfig.profilePhotoMaxLabel}',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (_supportsCamera) ...[
                  _PickerOptionTile(
                    icon: Icons.camera_alt_outlined,
                    title: 'Take a Photo',
                    subtitle: 'Use your device camera',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _pickFromImagePicker(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                _PickerOptionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from Gallery',
                  subtitle: 'Select an existing image',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickFromImagePicker(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                _PickerOptionTile(
                  icon: Icons.folder_open_outlined,
                  title: 'Browse Device Files',
                  subtitle: 'Pick a JPG or PNG file',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickFromDeviceFiles();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFromImagePicker(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      await _processSelectedImage(name: picked.name, bytes: bytes);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Unable to access ${source == ImageSource.camera ? 'camera' : 'gallery'} on this device.';
      });
    }
  }

  Future<void> _pickFromDeviceFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: UploadConfig.profilePhotoExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _errorMessage = 'Could not read the selected file bytes.';
        });
        return;
      }

      await _processSelectedImage(name: file.name, bytes: bytes);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to open file picker. Please try again.';
      });
    }
  }

  Future<void> _handleDroppedFile(SelectedFileData dropped) async {
    await _processSelectedImage(name: dropped.name, bytes: dropped.bytes);
  }

  /// Validates extension and compresses image locally if > 500 KB.
  Future<void> _processSelectedImage({
    required String name,
    required Uint8List bytes,
  }) async {
    final ext = UploadConfig.getExtension(name);
    if (!UploadConfig.isExtensionAllowed(
      name,
      UploadConfig.profilePhotoExtensions,
    )) {
      setState(() {
        _errorMessage =
            'Unsupported file type (${ext.isEmpty ? 'unknown' : ext.toUpperCase()}). Please select a JPG or PNG image.';
        if (_selectedPhoto == null) _status = UploadStatus.idle;
      });
      return;
    }

    setState(() {
      _isCompressing = true;
      _errorMessage = null;
    });

    final originalSize = bytes.length;
    Uint8List processedBytes = bytes;
    bool wasCompressed = false;

    if (originalSize > UploadConfig.profilePhotoMaxBytes) {
      final compressed = await _compressImageToLimit(
        bytes,
        UploadConfig.profilePhotoMaxBytes,
      );
      if (!mounted) return;

      if (compressed == null ||
          compressed.length > UploadConfig.profilePhotoMaxBytes) {
        setState(() {
          _isCompressing = false;
          _errorMessage =
              'Image (${UploadConfig.formatBytes(originalSize)}) could not be compressed below ${UploadConfig.profilePhotoMaxLabel}. Please choose a smaller image.';
        });
        return;
      }
      processedBytes = compressed;
      wasCompressed = true;
    }

    if (!mounted) return;
    setState(() {
      _isCompressing = false;
      _selectedPhoto = SelectedFileData(
        name: name,
        extension: ext,
        bytes: processedBytes,
        originalSizeBytes: originalSize,
        wasCompressed: wasCompressed,
      );
      _status = UploadStatus.selected;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });
  }

  /// Iteratively downscales an image using `dart:ui` until its encoded bytes
  /// fit below [maxBytes], returning `null` if compression fails.
  Future<Uint8List?> _compressImageToLimit(
    Uint8List sourceBytes,
    int maxBytes,
  ) async {
    try {
      final probeCodec = await ui.instantiateImageCodec(sourceBytes);
      final probeFrame = await probeCodec.getNextFrame();
      int targetWidth = probeFrame.image.width;
      probeFrame.image.dispose();
      probeCodec.dispose();

      // Step down dimensions until encoded size is <= maxBytes.
      for (int attempt = 0; attempt < 6; attempt++) {
        targetWidth = (targetWidth * 0.7).round().clamp(160, 1600);
        final codec = await ui.instantiateImageCodec(
          sourceBytes,
          targetWidth: targetWidth,
        );
        final frame = await codec.getNextFrame();
        final byteData = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        frame.image.dispose();
        codec.dispose();

        if (byteData == null) return null;
        final candidate = byteData.buffer.asUint8List();
        if (candidate.length <= maxBytes) {
          return candidate;
        }
        if (targetWidth <= 160) break;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Upload Simulation & Actions ───────────────────────────────────────

  void _startSimulatedUpload() {
    if (_selectedPhoto == null) return;
    _uploadTimer?.cancel();

    setState(() {
      _status = UploadStatus.uploading;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    const totalTicks = 20;
    int currentTick = 0;

    _uploadTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentTick++;
      final nextProgress = currentTick / totalTicks;

      if (_simulateFailure && currentTick >= 12) {
        timer.cancel();
        setState(() {
          _status = UploadStatus.failed;
          _errorMessage =
              'Simulated upload failed due to a temporary connection issue.';
        });
        return;
      }

      if (currentTick >= totalTicks) {
        timer.cancel();
        setState(() {
          _uploadProgress = 1.0;
          _status = UploadStatus.success;
          _uploadedPhoto = _selectedPhoto;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Profile photo uploaded successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        setState(() => _uploadProgress = nextProgress);
      }
    });
  }

  void _removePhoto() {
    _uploadTimer?.cancel();
    setState(() {
      _selectedPhoto = null;
      _uploadedPhoto = null;
      _status = UploadStatus.idle;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final activePhoto = _selectedPhoto ?? _uploadedPhoto;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: const AppHeader(title: 'Profile Photo', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Current / Preview Avatar ─────────────────────────────
              _buildAvatarPreview(activePhoto),
              const SizedBox(height: 12),
              Text(
                activePhoto != null
                    ? activePhoto.name
                    : 'No profile photo uploaded',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (activePhoto != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${activePhoto.extension.toUpperCase()} • ${UploadConfig.formatBytes(activePhoto.sizeBytes)}'
                  '${activePhoto.wasCompressed ? ' (compressed from ${UploadConfig.formatBytes(activePhoto.originalSizeBytes)})' : ''}',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),

              // ── Compression loading indicator ────────────────────────
              if (_isCompressing) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Compressing image to fit 500 KB...',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Drag-and-drop / Tap Area ─────────────────────────────
              UploadDropZone(
                title: 'Drag & drop or tap to select photo',
                subtitle: 'Choose from gallery, camera, or device files',
                acceptedFormatsLabel: 'JPG, PNG',
                maxSizeLabel: UploadConfig.profilePhotoMaxLabel,
                icon: Icons.add_a_photo_outlined,
                onTap: _showSourcePicker,
                onFileDropped: _handleDroppedFile,
                enabled:
                    _status != UploadStatus.uploading && !_isCompressing,
              ),
              const SizedBox(height: 16),

              // ── Status / Progress / Error / Retry Banner ─────────────
              UploadStatusBanner(
                status: _status,
                progress: _uploadProgress,
                errorMessage: _errorMessage,
                successMessage: 'Profile photo uploaded successfully!',
                onRetry: _startSimulatedUpload,
              ),
              if (_status != UploadStatus.idle || _errorMessage != null)
                const SizedBox(height: 16),

              // ── Primary Action Buttons ───────────────────────────────
              if (_selectedPhoto != null &&
                  _status != UploadStatus.success) ...[
                PrimaryButton(
                  text: _status == UploadStatus.uploading
                      ? 'Uploading...'
                      : 'Upload Photo',
                  onPressed: _status == UploadStatus.uploading
                      ? null
                      : _startSimulatedUpload,
                  isLoading: _status == UploadStatus.uploading,
                  icon: Icons.cloud_upload_outlined,
                ),
                const SizedBox(height: 12),
              ] else ...[
                PrimaryButton(
                  text: activePhoto == null ? 'Upload Photo' : 'Replace Photo',
                  onPressed: _showSourcePicker,
                  icon: Icons.photo_camera_outlined,
                ),
                const SizedBox(height: 12),
              ],

              if (activePhoto != null) ...[
                if (_selectedPhoto != null && _status != UploadStatus.success)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SecondaryButton(
                      text: 'Replace Photo',
                      onPressed: _status == UploadStatus.uploading
                          ? null
                          : _showSourcePicker,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _status == UploadStatus.uploading
                        ? null
                        : _removePhoto,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text(
                      'Remove Photo',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: BorderSide(
                        color: AppTheme.errorRed.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Dev-only Failure Simulation Toggle ───────────────────
              DevSimulateFailureToggle(
                value: _simulateFailure,
                onChanged: (val) => setState(() => _simulateFailure = val),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPreview(SelectedFileData? photo) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: _status == UploadStatus.success
                  ? AppTheme.successGreen
                  : AppTheme.primaryBlue,
              width: 3,
            ),
          ),
          child: ClipOval(
            child: photo != null
                ? Image.memory(
                    photo.bytes,
                    fit: BoxFit.cover,
                    width: 132,
                    height: 132,
                  )
                : const Center(
                    child: Icon(
                      Icons.person,
                      color: AppTheme.textSecondary,
                      size: 64,
                    ),
                  ),
          ),
        ),
        if (_status == UploadStatus.success)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppTheme.successGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 18),
          ),
      ],
    );
  }
}

class _PickerOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      tileColor: AppTheme.scaffoldBackground,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(icon, color: AppTheme.primaryBlue, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle, style: AppTheme.bodyMedium),
      trailing:
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
    );
  }
}
