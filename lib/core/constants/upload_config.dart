/// Centralized upload configuration for file size limits and accepted formats.
abstract class UploadConfig {
  // MARK: - Profile Photo

  /// Maximum profile photo size in bytes (500 KB).
  static const int profilePhotoMaxBytes = 500 * 1024;

  /// Human-readable profile photo limit.
  static const String profilePhotoMaxLabel = '500 KB';

  /// Accepted profile photo extensions.
  static const List<String> profilePhotoExtensions = ['jpg', 'jpeg', 'png'];

  /// Accepted profile photo MIME types.
  static const List<String> profilePhotoMimeTypes = [
    'image/jpeg',
    'image/png',
  ];

  // MARK: - Driving Licence / Document

  /// Maximum document size in bytes (5 MB).
  static const int documentMaxBytes = 5 * 1024 * 1024;

  /// Human-readable document limit.
  static const String documentMaxLabel = '5 MB';

  /// Accepted document extensions.
  static const List<String> documentExtensions = [
    'jpg',
    'jpeg',
    'png',
    'pdf',
  ];

  /// Accepted document MIME types.
  static const List<String> documentMimeTypes = [
    'image/jpeg',
    'image/png',
    'application/pdf',
  ];

  // MARK: - Helpers

  /// Returns the file extension from a filename, lowercased.
  static String getExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Formats bytes into a human-readable string.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Checks whether a file extension is in an allowed list.
  static bool isExtensionAllowed(String filename, List<String> allowed) {
    return allowed.contains(getExtension(filename));
  }
}
