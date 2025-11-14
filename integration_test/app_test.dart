import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gallery/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Navigate to image editor and take screenshot', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Tap the "Skip for now" button on the auth screen
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    // Tap the first album
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // Tap the first photo in the album
    await tester.tap(find.byType(GridTile).first);
    await tester.pumpAndSettle();

    // Tap the edit button
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    // Verify that the image editor is displayed
    expect(find.text('Edit Photo'), findsOneWidget);

    // TODO: Take a screenshot
  });
}
