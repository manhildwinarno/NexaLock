import 'package:flutter_test/flutter_test.dart';
import 'package:nexalock/main.dart';

void main() {
  testWidgets('App initialization setup error screen renders', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MyApp(
        isFirebaseInitialized: false,
        initError: 'Simulated init error',
      ),
    );

    // Verify that the Firebase Not Configured screen is rendered.
    expect(find.text('Firebase Not Configured'), findsOneWidget);
    expect(find.text('Simulated init error'), findsOneWidget);
  });
}
