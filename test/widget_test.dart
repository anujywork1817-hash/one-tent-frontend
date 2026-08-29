import 'package:flutter_test/flutter_test.dart';
import 'package:one_tent/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KumbhApp());
    expect(find.byType(KumbhApp), findsOneWidget);
  });
}