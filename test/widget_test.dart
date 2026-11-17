import 'package:clean_arch_session/core/di/dependency_injection.dart';
import 'package:clean_arch_session/core/routes/routes.dart';
import 'package:clean_arch_session/feature/auth/presentation/ui/login_screen.dart';
import 'package:clean_arch_session/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(setupGetIt);

  testWidgets('starts on a single login screen', (tester) async {
    await tester.pumpWidget(const MyApp(initialRoute: Routes.login));

    expect(find.byType(LoginScreen, skipOffstage: false), findsOneWidget);
  });
}
