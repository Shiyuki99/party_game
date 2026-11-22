import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:party_game/main.dart';

void main() {
  testWidgets('App loads party type screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PartyGameApp()));

    expect(find.text('Party Game'), findsWidgets);
    expect(find.text('Pass & Play'), findsOneWidget);
    expect(find.text('LAN Party'), findsOneWidget);
  });
}
