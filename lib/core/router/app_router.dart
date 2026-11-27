import 'package:flutter/material.dart';
import 'package:automate/features/auth/presentation/screens/login_screen.dart';
import 'package:automate/features/auth/presentation/screens/register_screen.dart';
import 'package:automate/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:automate/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:automate/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:automate/features/auth/presentation/screens/welcome_back_screen.dart';
import 'package:automate/features/landing/presentation/screens/landing_screen.dart';
import 'package:automate/features/vehicle_rental/models/vehicle_listing.dart';
import 'package:automate/features/vehicle_rental/presentation/screens/owner_dashboard_screen.dart';
import 'package:automate/features/vehicle_rental/presentation/screens/my_listings_screen.dart';
import 'package:automate/features/vehicle_rental/presentation/screens/create_listing_screen.dart';
import 'package:automate/features/vehicle_rental/presentation/screens/edit_listing_screen.dart';
import 'package:automate/core/constants/app_constants.dart';

/// Application router using named routes.
/// Teacher concept: centralised routing — all navigation is defined here,
/// so adding a new screen only requires one change in one file.
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppConstants.landing:
        return MaterialPageRoute(
          builder: (_) => const LandingScreen(),
          settings: settings,
        );
      case AppConstants.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case AppConstants.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case AppConstants.emailVerification:
        return MaterialPageRoute(
          builder: (_) => const EmailVerificationScreen(),
          settings: settings,
        );
      case AppConstants.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );
      case AppConstants.roleSelection:
        return MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
          settings: settings,
        );
      case AppConstants.welcomeBack:
        return MaterialPageRoute(
          builder: (_) => const WelcomeBackScreen(),
          settings: settings,
        );

      // ── Vehicle Rental Feature Routes ──────────────────────────────
      case AppConstants.dashboard:
        return MaterialPageRoute(
          builder: (_) => const OwnerDashboardScreen(),
          settings: settings,
        );
      case AppConstants.myListings:
        return MaterialPageRoute(
          builder: (_) => const MyListingsScreen(),
          settings: settings,
        );
      case AppConstants.createListing:
        return MaterialPageRoute(
          builder: (_) => const CreateListingScreen(),
          settings: settings,
        );
      case AppConstants.editListing:
        // The VehicleListing object is passed via settings.arguments
        final listing = settings.arguments as VehicleListing;
        return MaterialPageRoute(
          builder: (_) => EditListingScreen(listing: listing),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const LandingScreen(),
          settings: settings,
        );
    }
  }
}
