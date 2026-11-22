import 'package:flutter_test/flutter_test.dart';

import 'package:agriculture/main.dart';

void main() {
  testWidgets('Agriculture app login smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PagriApp());

    // Verify that login screen is shown with PAGRI title.
    expect(find.text('PAGRI'), findsOneWidget);
  });
}
