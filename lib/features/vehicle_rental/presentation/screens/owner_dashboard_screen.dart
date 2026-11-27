import 'package:flutter/material.dart';
import 'package:automate/core/constants/app_constants.dart';
import 'package:automate/core/theme/app_theme.dart';
import 'package:automate/features/vehicle_rental/presentation/screens/my_listings_screen.dart';

/// Owner Dashboard — the home screen for vehicle owners after login.
///
/// This screen uses a BottomNavigationBar + PageView to switch between
/// different sections — the same pattern taught in AI39A's DashboardScreen.
///
/// Teacher concept (from AI39A):
///   - BottomNavigationBar with selectedIndex to track active tab
///   - PageController.jumpToPage() to sync PageView with the navbar
///   - setState() to update the UI when the tab changes
///   - PageView with NeverScrollableScrollPhysics (user cannot swipe — only
///     the navbar controls navigation, preventing accidental swipes)
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  // Tracks which tab is active — same pattern as AI39A DashboardScreen
  int _selectedIndex = 0;

  // PageController lets us programmatically switch pages
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Called when a bottom nav item is tapped.
  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
      // jumpToPage instantly switches the page (no animation needed here)
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      // ── Bottom Navigation Bar ──────────────────────────────────────
      // Same pattern as AI39A: BottomNavigationBar with icons + labels
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: 'My Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      // ── PageView body ──────────────────────────────────────────────
      // NeverScrollableScrollPhysics: users can't swipe, only tap nav
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: const [
          _HomeTab(),
          MyListingsScreen(), // Feature screens live in the nav tabs
          _EarningsTab(),
          _ProfileTab(),
        ],
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────
/// Quick-access home with a shortcut to create a listing.
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good day, Rina 👋',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Vehicle Owner',
                      style: TextStyle(
                        color: AppTheme.accentOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Stats row
            Row(
              children: [
                _StatCard(
                  icon: Icons.directions_car,
                  label: 'Listings',
                  value: '2',
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.calendar_today,
                  label: 'Bookings',
                  value: '0',
                  color: AppTheme.accentOrange,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.currency_rupee,
                  label: 'Earned',
                  value: '0',
                  color: AppTheme.successGreen,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            _QuickActionCard(
              icon: Icons.add_circle_outline,
              title: 'Create a New Listing',
              subtitle: 'List your vehicle and start earning',
              onTap: () => Navigator.pushNamed(context, AppConstants.createListing),
            ),
            const SizedBox(height: 10),
            _QuickActionCard(
              icon: Icons.list_alt_outlined,
              title: 'Manage My Listings',
              subtitle: 'Edit, delete or view your listings',
              onTap: () => Navigator.pushNamed(context, AppConstants.myListings),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card widget ──────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
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

// ── Quick action card ─────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Placeholder Earnings Tab ──────────────────────────────────────────────
class _EarningsTab extends StatelessWidget {
  const _EarningsTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, color: AppTheme.textSecondary, size: 60),
            SizedBox(height: 16),
            Text(
              'Earnings',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Placeholder Profile Tab ───────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryBlue,
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rina',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vehicle Owner',
              style: TextStyle(
                color: AppTheme.accentOrange,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppConstants.landing,
                  (route) => false,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
