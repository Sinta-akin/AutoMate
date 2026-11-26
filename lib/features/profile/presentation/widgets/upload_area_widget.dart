import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:automate/core/theme/app_theme.dart';

/// Represents the lifecycle state of a frontend simulated upload.
enum UploadStatus {
  idle,
  selected,
  uploading,
  success,
  failed,
}

/// In-memory representation of a selected or dropped file.
class SelectedFileData {
  final String name;
  final String extension;
  final Uint8List bytes;
  final int originalSizeBytes;
  final bool wasCompressed;

  const SelectedFileData({
    required this.name,
    required this.extension,
    required this.bytes,
    required this.originalSizeBytes,
    this.wasCompressed = false,
  });

  int get sizeBytes => bytes.length;
}

/// Reusable drag-and-drop + tap-to-select upload area.
class UploadDropZone extends StatefulWidget {
  final String title;
  final String subtitle;
  final String acceptedFormatsLabel;
  final String maxSizeLabel;
  final IconData icon;
  final VoidCallback onTap;
  final ValueChanged<SelectedFileData>? onFileDropped;
  final bool enabled;

  const UploadDropZone({
    super.key,
    required this.title,
    required this.subtitle,
    required this.acceptedFormatsLabel,
    required this.maxSizeLabel,
    required this.icon,
    required this.onTap,
    this.onFileDropped,
    this.enabled = true,
  });

  @override
  State<UploadDropZone> createState() => _UploadDropZoneState();
}

class _UploadDropZoneState extends State<UploadDropZone> {
  bool _isDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<SelectedFileData>(
      onWillAcceptWithDetails: (details) {
        if (!widget.enabled) return false;
        setState(() => _isDraggingOver = true);
        return true;
      },
      onLeave: (_) {
        if (mounted) setState(() => _isDraggingOver = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isDraggingOver = false);
        widget.onFileDropped?.call(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: _isDraggingOver
                  ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: _isDraggingOver ? AppTheme.primaryBlue : AppTheme.border,
                width: _isDraggingOver ? 2 : 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: AppTheme.primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isDraggingOver ? 'Drop file here' : widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle,
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _InfoChip(
                      icon: Icons.insert_drive_file_outlined,
                      label: widget.acceptedFormatsLabel,
                    ),
                    _InfoChip(
                      icon: Icons.sd_storage_outlined,
                      label: 'Max ${widget.maxSizeLabel}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable upload status & progress feedback banner.
class UploadStatusBanner extends StatelessWidget {
  final UploadStatus status;
  final double progress;
  final String? errorMessage;
  final String successMessage;
  final VoidCallback? onRetry;

  const UploadStatusBanner({
    super.key,
    required this.status,
    required this.progress,
    required this.successMessage,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case UploadStatus.idle:
      case UploadStatus.selected:
        if (errorMessage != null && errorMessage!.isNotEmpty) {
          return _buildErrorBox(errorMessage!, showRetry: false);
        }
        return const SizedBox.shrink();

      case UploadStatus.uploading:
        final percent = (progress * 100).clamp(0, 100).toInt();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Uploading...',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppTheme.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
        );

      case UploadStatus.success:
        if (errorMessage != null && errorMessage!.isNotEmpty) {
          return _buildErrorBox(errorMessage!, showRetry: false);
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border:
                Border.all(color: AppTheme.successGreen.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppTheme.successGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  successMessage,
                  style: const TextStyle(
                    color: AppTheme.successGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

      case UploadStatus.failed:
        return _buildErrorBox(
          errorMessage ?? 'Simulated upload failed. Please try again.',
          showRetry: true,
        );
    }
  }

  Widget _buildErrorBox(String message, {required bool showRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.errorRed,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (showRetry && onRetry != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry Upload'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Development-only switch to test simulated upload failure & retry flow.
class DevSimulateFailureToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const DevSimulateFailureToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bug_report_outlined,
            color: AppTheme.accentOrange,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulate upload failure',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Dev-only: test error & retry flow',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.accentOrange,
          ),
        ],
      ),
    );
  }
}
