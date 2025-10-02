import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inven_fact/screens/welcome_screen.dart';
import 'package:inven_fact/screens/barcode_scanner_screen.dart';
import 'package:mockito/mockito.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  testWidgets('Tapping scan button opens scanner even with text in field', (WidgetTester tester) async {
    // Mocking Navigator
    final mockObserver = MockNavigatorObserver();

    await tester.pumpWidget(MaterialApp(
      home: const WelcomeScreen(),
      navigatorObservers: [mockObserver],
    ));

    // Enter text into the client code field
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.pump();

    // Tap the scan button
    await tester.tap(find.widgetWithText(OutlinedButton, 'Escanear código'));
    await tester.pumpAndSettle();

    // Verify that the BarcodeScannerScreen was pushed
    expect(find.byType(BarcodeScannerScreen), findsOneWidget);
  });
}