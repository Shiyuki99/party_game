import 'package:flutter_test/flutter_test.dart';

import 'package:party_game/main.dart';

void main() {
  testWidgets('App loads party type screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PartyGameApp());

    expect(find.text('Party Game'), findsOneWidget);
  });
}
