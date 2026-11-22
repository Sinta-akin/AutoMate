import 'package:flutter/material.dart';
import 'package:automate/core/theme/app_theme.dart';
import 'package:automate/core/router/app_router.dart';
import 'package:automate/core/constants/app_constants.dart';

void main() {
  runApp(const AutoMateApp());
}

class AutoMateApp extends StatelessWidget {
  const AutoMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppConstants.landing,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
