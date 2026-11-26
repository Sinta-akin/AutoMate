import 'package:flutter/material.dart';
import 'package:automate/core/theme/app_theme.dart';
import 'package:automate/core/widgets/common_widgets.dart';

/// US-M1-06 – User Profile Creation & Editing.
///
/// Displays the user's profile information with an Edit / Save flow.
/// All state is held in memory and resets on app restart.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Controllers ──────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Arjun Kumar');
  final _phoneController = TextEditingController(text: '+977 9812345678');

  // ── In-memory profile state ──────────────────────────────────────────
  bool _isEditing = false;
  bool _isSaving = false;

  /// The *displayed* values – updated only after a successful save.
  String _displayName = 'Arjun Kumar';
  String _displayPhone = '+977 9812345678';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Accepts optional +, country code, spaces/dashes, 7-15 digits total.
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(cleaned)) {
      return 'Enter a valid phone number (e.g. +977 9812345678)';
    }
    return null;
  }

  // ── Actions ──────────────────────────────────────────────────────────

  void _toggleEdit() {
    setState(() {
      _isEditing = true;
      // Seed controllers with current displayed values.
      _nameController.text = _displayName;
      _phoneController.text = _displayPhone;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      // Revert controllers.
      _nameController.text = _displayName;
      _phoneController.text = _displayPhone;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Simulate network latency.
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    setState(() {
      _displayName = _nameController.text.trim();
      _displayPhone = _phoneController.text.trim();
      _isSaving = false;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Profile updated successfully!'),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppHeader(
        title: 'My Profile',
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Avatar placeholder ───────────────────────────────
                _buildAvatar(),
                const SizedBox(height: 8),
                Text(
                  _displayName,
                  style: AppTheme.headline2,
                ),
                const SizedBox(height: 4),
                Text(
                  _displayPhone,
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // ── Profile card ─────────────────────────────────────
                _buildProfileCard(),
                const SizedBox(height: 24),

                // ── Action buttons ───────────────────────────────────
                if (_isEditing) ...[
                  PrimaryButton(
                    text: 'Save Changes',
                    onPressed: _saveProfile,
                    isLoading: _isSaving,
                    icon: Icons.save_outlined,
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    text: 'Cancel',
                    onPressed: _isSaving ? null : _cancelEdit,
                  ),
                ] else ...[
                  PrimaryButton(
                    text: 'Edit Profile',
                    onPressed: _toggleEdit,
                    icon: Icons.edit_outlined,
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Subwidgets ───────────────────────────────────────────────────────

  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryBlue, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.person, color: AppTheme.primaryBlue, size: 48),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Personal Information',
                style: AppTheme.sectionHeading,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Full name
          AppTextField(
            label: 'Full Name',
            hint: 'Enter your full name',
            controller: _nameController,
            enabled: _isEditing,
            prefixIcon: Icons.badge_outlined,
            validator: _validateName,
          ),
          const SizedBox(height: 16),

          // Phone number
          AppTextField(
            label: 'Phone Number',
            hint: '+977 9812345678',
            controller: _phoneController,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: _validatePhone,
          ),

          // ── Status indicator ───────────────────────────────────
          if (!_isEditing) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppTheme.successGreen, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Profile information saved',
                    style: TextStyle(
                      color: AppTheme.successGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
