import 'package:flutter/material.dart';
import 'package:automate_mobile/core/theme/app_theme.dart';
import 'package:automate_mobile/core/router/app_router.dart';
import 'package:automate_mobile/core/constants/app_constants.dart';

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
