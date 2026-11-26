import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:automate/core/constants/upload_config.dart';
import 'package:automate/core/theme/app_theme.dart';
import 'package:automate/core/widgets/common_widgets.dart';
import 'package:automate/features/profile/presentation/widgets/upload_area_widget.dart';

/// US-M1-12 – Driving Licence / Document Upload.
///
/// Allows selecting or dropping JPG, PNG, or PDF files up to
/// [UploadConfig.documentMaxBytes] (5 MB), displays file metadata,
/// simulates upload progress, and provides view, replace, remove, and retry.
class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  UploadStatus _status = UploadStatus.idle;
  double _uploadProgress = 0.0;
  Timer? _uploadTimer;

  SelectedFileData? _selectedDocument;
  String? _errorMessage;
  bool _simulateFailure = false;

  @override
  void dispose() {
    _uploadTimer?.cancel();
    super.dispose();
  }

  // ── File Selection & Validation ───────────────────────────────────────

  Future<void> _pickDocument() async {
    if (_status == UploadStatus.uploading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: UploadConfig.documentExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _errorMessage = 'Unable to read the selected file.';
        });
        return;
      }

      _validateAndSelectDocument(name: file.name, bytes: bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to open file picker. Please try again.';
      });
    }
  }

  void _validateAndSelectDocument({
    required String name,
    required dynamic bytes,
  }) {
    final ext = UploadConfig.getExtension(name);
    if (!UploadConfig.isExtensionAllowed(
      name,
      UploadConfig.documentExtensions,
    )) {
      setState(() {
        _errorMessage =
            'Unsupported format (${ext.isEmpty ? 'unknown' : ext.toUpperCase()}). Accepted formats: JPG, PNG, PDF.';
        if (_selectedDocument == null) _status = UploadStatus.idle;
      });
      return;
    }

    final fileSize = bytes.length as int;
    if (fileSize > UploadConfig.documentMaxBytes) {
      setState(() {
        _errorMessage =
            'File size (${UploadConfig.formatBytes(fileSize)}) exceeds the ${UploadConfig.documentMaxLabel} maximum limit.';
        if (_selectedDocument == null) _status = UploadStatus.idle;
      });
      return;
    }

    setState(() {
      _selectedDocument = SelectedFileData(
        name: name,
        extension: ext,
        bytes: bytes,
        originalSizeBytes: fileSize,
      );
      _status = UploadStatus.selected;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });
  }

  // ── Upload Simulation & Actions ───────────────────────────────────────

  void _startSimulatedUpload() {
    if (_selectedDocument == null) return;
    _uploadTimer?.cancel();

    setState(() {
      _status = UploadStatus.uploading;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    const totalTicks = 22;
    int currentTick = 0;

    _uploadTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentTick++;
      final nextProgress = currentTick / totalTicks;

      if (_simulateFailure && currentTick >= 13) {
        timer.cancel();
        setState(() {
          _status = UploadStatus.failed;
          _errorMessage =
              'Simulated upload failed. Please check and retry.';
        });
        return;
      }

      if (currentTick >= totalTicks) {
        timer.cancel();
        setState(() {
          _uploadProgress = 1.0;
          _status = UploadStatus.success;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Driving licence uploaded successfully!'),
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

  void _removeDocument() {
    _uploadTimer?.cancel();
    setState(() {
      _selectedDocument = null;
      _status = UploadStatus.idle;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });
  }

  void _viewDocument() {
    final doc = _selectedDocument;
    if (doc == null) return;

    final isPdf = doc.extension == 'pdf';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        doc.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isPdf)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBackground,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf,
                          color: AppTheme.accentOrange,
                          size: 56,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          doc.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'PDF Document • ${UploadConfig.formatBytes(doc.sizeBytes)}',
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: Image.memory(doc.bytes, fit: BoxFit.contain),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final doc = _selectedDocument;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: const AppHeader(title: 'Driving Licence', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Document Verification', style: AppTheme.headline2),
              const SizedBox(height: 6),
              Text(
                'Upload a clear photo or PDF scan of your valid driving licence.',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // ── Drag-and-drop / File Picker Area ─────────────────────
              UploadDropZone(
                title: 'Drag & drop or tap to upload licence',
                subtitle: 'Select a document from your device',
                acceptedFormatsLabel: 'JPG, PNG, PDF',
                maxSizeLabel: UploadConfig.documentMaxLabel,
                icon: Icons.badge_outlined,
                onTap: _pickDocument,
                onFileDropped: (dropped) => _validateAndSelectDocument(
                  name: dropped.name,
                  bytes: dropped.bytes,
                ),
                enabled: _status != UploadStatus.uploading,
              ),
              const SizedBox(height: 20),

              // ── Selected Document Details Card ───────────────────────
              if (doc != null) ...[
                _buildSelectedDocumentCard(doc),
                const SizedBox(height: 16),
              ],

              // ── Status / Progress / Error / Retry Banner ─────────────
              UploadStatusBanner(
                status: _status,
                progress: _uploadProgress,
                errorMessage: _errorMessage,
                successMessage: 'Driving licence uploaded successfully!',
                onRetry: _startSimulatedUpload,
              ),
              if (_status != UploadStatus.idle || _errorMessage != null)
                const SizedBox(height: 16),

              // ── Primary CTA ──────────────────────────────────────────
              if (doc == null) ...[
                PrimaryButton(
                  text: 'Upload Driving Licence',
                  onPressed: _pickDocument,
                  icon: Icons.upload_file_outlined,
                ),
              ] else if (_status != UploadStatus.success) ...[
                PrimaryButton(
                  text: _status == UploadStatus.uploading
                      ? 'Uploading...'
                      : 'Upload Driving Licence',
                  onPressed: _status == UploadStatus.uploading
                      ? null
                      : _startSimulatedUpload,
                  isLoading: _status == UploadStatus.uploading,
                  icon: Icons.cloud_upload_outlined,
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  text: 'Replace Document',
                  onPressed:
                      _status == UploadStatus.uploading ? null : _pickDocument,
                ),
              ] else ...[
                PrimaryButton(
                  text: 'Replace Document',
                  onPressed: _pickDocument,
                  icon: Icons.swap_horiz,
                ),
              ],

              if (doc != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _status == UploadStatus.uploading
                        ? null
                        : _removeDocument,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text(
                      'Remove Document',
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
              ],

              const SizedBox(height: 20),

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

  Widget _buildSelectedDocumentCard(SelectedFileData doc) {
    final isPdf = doc.extension == 'pdf';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: _status == UploadStatus.success
              ? AppTheme.successGreen.withValues(alpha: 0.6)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isPdf ? AppTheme.accentOrange : AppTheme.primaryBlue)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                  color: isPdf ? AppTheme.accentOrange : AppTheme.primaryBlue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Format: ${doc.extension.toUpperCase()} • Size: ${UploadConfig.formatBytes(doc.sizeBytes)}',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'View Document',
                onPressed: _viewDocument,
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          if (_status == UploadStatus.success) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: AppTheme.successGreen,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Saved in current session',
                    style: TextStyle(
                      color: AppTheme.successGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
