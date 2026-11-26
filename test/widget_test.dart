import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automate/main.dart';
import 'package:automate/features/dev/presentation/screens/dev_menu_screen.dart';
import 'package:automate/features/profile/presentation/screens/profile_screen.dart';
import 'package:automate/features/profile/presentation/screens/profile_photo_screen.dart';
import 'package:automate/features/profile/presentation/screens/document_upload_screen.dart';
import 'package:automate/core/theme/app_theme.dart';

void main() {
  testWidgets('AutoMate app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const AutoMateApp());
    expect(find.text('AutoMate'), findsWidgets);
  });

  testWidgets('ProfileScreen validates phone and saves valid profile (US-M1-06)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const ProfileScreen(),
      ),
    );

    // Initially shows Edit Profile button
    expect(find.text('Edit Profile'), findsOneWidget);
    await tester.ensureVisible(find.text('Edit Profile'));
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    // Now shows Save Changes and Cancel
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Enter invalid phone number
    final phoneField = find.byType(TextFormField).at(1);
    await tester.enterText(phoneField, 'abc');
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a valid phone number (e.g. +977 9812345678)'),
      findsOneWidget,
    );

    // Enter valid name and phone number
    final nameField = find.byType(TextFormField).at(0);
    await tester.enterText(nameField, 'Sita Sharma');
    await tester.enterText(phoneField, '+977 9841000000');
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Profile updated successfully!'), findsOneWidget);
    expect(find.text('Sita Sharma'), findsWidgets);
  });

  testWidgets('ProfilePhotoScreen renders upload UI and failure toggle (US-M1-08)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const ProfilePhotoScreen(),
      ),
    );

    expect(find.text('Profile Photo'), findsOneWidget);
    expect(find.text('No profile photo uploaded'), findsOneWidget);
    expect(find.text('Drag & drop or tap to select photo'), findsOneWidget);
    expect(find.text('JPG, PNG'), findsOneWidget);
    expect(find.text('Max 500 KB'), findsOneWidget);
    expect(find.text('Upload Photo'), findsOneWidget);
    expect(find.text('Simulate upload failure'), findsOneWidget);
  });

  testWidgets('DocumentUploadScreen renders upload UI and limits (US-M1-12)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const DocumentUploadScreen(),
      ),
    );

    expect(find.text('Driving Licence'), findsOneWidget);
    expect(find.text('Document Verification'), findsOneWidget);
    expect(find.text('JPG, PNG, PDF'), findsOneWidget);
    expect(find.text('Max 5 MB'), findsOneWidget);
    expect(find.text('Upload Driving Licence'), findsOneWidget);
    expect(find.text('Simulate upload failure'), findsOneWidget);
  });

  testWidgets('DevMenuScreen lists all three feature entries',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const DevMenuScreen(),
      ),
    );

    expect(find.text('User Profile'), findsOneWidget);
    expect(find.text('Profile Photo'), findsOneWidget);
    expect(find.text('Driving Licence'), findsOneWidget);
  });
}
