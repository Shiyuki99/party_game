import 'package:flutter/material.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/charades/play.dart';

class CharadesPlugin implements GamePlugin {
  @override
  String get id => 'charades';

  @override
  String get name => 'Charades';

  @override
  IconData get icon => Icons.theater_comedy;

  @override
  String get description => 'Act it out, guess the word';

  @override
  GameSettings get defaultSettings => GameSettings(
        roundTimeSeconds: 60,
        numberOfRounds: 10,
      );

  @override
  Widget buildSettingsScreen(
      GameSettings settings, ValueChanged<GameSettings> onChanged) {
    return const SizedBox();
  }

  @override
  Widget buildPlayScreen(GameContext context) {
    return CharadesPlayScreen(context: context);
  }
}
