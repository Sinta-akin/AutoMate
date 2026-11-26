import 'package:flutter/material.dart';
import 'package:automate/core/theme/app_theme.dart';
import 'package:automate/core/constants/app_constants.dart';
import 'package:automate/core/widgets/common_widgets.dart';

/// Development-only navigation hub for in-progress features.
///
/// Provides quick access to profile, photo upload, and document upload
/// screens without modifying existing authentication flows.
class DevMenuScreen extends StatelessWidget {
  const DevMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: const AppHeader(title: 'Dev Menu', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Text(
                  'DEVELOPMENT',
                  style: TextStyle(
                    color: AppTheme.accentOrange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Feature Screens', style: AppTheme.headline2),
              const SizedBox(height: 4),
              Text(
                'Quick access to screens under development.',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // ── Feature cards ──────────────────────────────────────
              _FeatureCard(
                icon: Icons.person_outline,
                iconColor: AppTheme.primaryBlue,
                title: 'User Profile',
                subtitle: 'Create & edit profile information',
                tag: 'US-M1-06',
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.profile),
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.camera_alt_outlined,
                iconColor: AppTheme.successGreen,
                title: 'Profile Photo',
                subtitle: 'Upload & manage profile photo',
                tag: 'US-M1-08',
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.profilePhoto),
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.description_outlined,
                iconColor: AppTheme.accentOrange,
                title: 'Driving Licence',
                subtitle: 'Upload driving licence / document',
                tag: 'US-M1-12',
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.documentUpload),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
