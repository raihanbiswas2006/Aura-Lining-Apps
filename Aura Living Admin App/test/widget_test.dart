import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aura_living_admin/app.dart';

void main() {
  testWidgets('Aura Living Admin App loads and displays login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AuraLivingAdminApp(),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify Aura Living Admin branding elements are present
    expect(find.text('AURA LIVING'), findsWidgets);
  });
}
