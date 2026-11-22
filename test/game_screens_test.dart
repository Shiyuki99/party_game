import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/core/connection/pass_play_connection.dart';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/game_engine/game_registry.dart';

void main() {
  testWidgets('every game screen renders its first phase', (tester) async {
    for (final plugin in gamePlugins) {
      final players = List<Player>.generate(
        4,
        (i) => Player(id: 'p$i', name: 'Player $i'),
      );
      final context = GameContext(
        players: players,
        connection: PassPlayConnectionService(),
        content: jsonDecode(
                File('content/${plugin.id}.json').readAsStringSync())
            as Map<String, dynamic>,
        settings: plugin.defaultSettings,
        addScore: (_, _) {},
        onGameEnd: () {},
      );
      final logic = plugin.createLogic(context);
      logic.init();

      final screen = plugin.buildScreen(logic, context);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SizedBox.expand(child: screen)),
      ));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull, reason: '${plugin.name} crashed');
      expect(find.byType(screen.runtimeType), findsOneWidget,
          reason: '${plugin.name} did not render');
    }
  });
}
