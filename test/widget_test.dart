import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amphibians_data_collection/main.dart';
import 'package:amphibians_data_collection/views/login_view.dart';
import 'package:amphibians_data_collection/controllers/auth_controller.dart';

class FakeAuthController extends AuthController {
  FakeAuthController() : super(null);
}

void main() {
  testWidgets('App smoke test - displays LoginView', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authControllerProvider.overrideWith((ref) => FakeAuthController()),
        ],
        child: const MyApp(),
      ),
    );

    // Wait for the asynchronous streams to emit their initial states
    await tester.pumpAndSettle();

    // Verify that LoginView is displayed since the user is not authenticated.
    expect(find.byType(LoginView), findsOneWidget);
  });
}
