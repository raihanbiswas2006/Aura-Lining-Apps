import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aura_living/app/app.dart';
import 'package:aura_living/core/di/injection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    if (!getIt.isRegistered<SharedPreferences>()) {
      await configureDependencies();
    }
  });

  testWidgets('Aura Living app loads and renders brand splash', (WidgetTester tester) async {
    await tester.pumpWidget(const AuraLivingApp());
    expect(find.text('AURA LIVING'), findsWidgets);

    // Settle splash initialization timers
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
  });
}
