import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomo_front/core/notification_service.dart';
import 'package:pomo_front/core/settings_service.dart';
import 'package:pomo_front/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences method channel
    SharedPreferences.setMockInitialValues({});

    final notificationService = NotificationService();
    final settingsService = SettingsService();
    await settingsService.load();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      notificationService: notificationService,
      settingsService: settingsService,
    ));

    // Verify that the app builds and renders a MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
