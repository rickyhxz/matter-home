import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matter_home/main.dart';

void main() {
  testWidgets('Home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MatterHomeApp()));
    await tester.pumpAndSettle();
    expect(find.text('My Home'), findsOneWidget);
  });
}
