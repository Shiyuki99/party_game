import 'package:flutter/material.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/imposter/play.dart';

class ImposterPlugin implements GamePlugin {
  @override
  String get id => 'imposter';

  @override
  String get name => 'Imposter';

  @override
  IconData get icon => Icons.visibility_off;

  @override
  String get description => 'Find the imposter among you';

  @override
  GameSettings get defaultSettings => GameSettings(
        roundTimeSeconds: 90,
        numberOfRounds: 5,
      );

  @override
  Widget buildSettingsScreen(
      GameSettings settings, ValueChanged<GameSettings> onChanged) {
    return const SizedBox();
  }

  @override
  Widget buildPlayScreen(GameContext context) {
    return ImposterPlayScreen(context: context);
  }
}
