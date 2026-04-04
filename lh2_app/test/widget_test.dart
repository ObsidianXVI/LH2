// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lh2_app/main.dart';

void main() {
  testWidgets('LH2App builds without crashing', (WidgetTester tester) async {
    // Build our app - Firebase initialization will hang in tests
    // so we just verify the app structure builds correctly
    await tester.pumpWidget(
      const ProviderScope(
        child: LH2App(),
      ),
    );

    // Initially shows loading spinner while Firebase initializes
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // App builds successfully - Firebase requires emulator to proceed
  });
}
