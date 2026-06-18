import 'package:flutter/material.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/truth_or_dare/models.dart';
import 'package:party_game/ui/features/games/truth_or_dare/settings.dart';
import 'package:party_game/ui/features/games/truth_or_dare/play.dart';

class TruthOrDarePlugin implements GamePlugin {
  @override
  String get id => 'truth_or_dare';

  @override
  String get name => 'Truth or Dare';

  @override
  IconData get icon => Icons.psychology;

  @override
  String get description => 'Take turns asking truth or dare';

  @override
  GameSettings get defaultSettings => GameSettings(
        roundTimeSeconds: 60,
        numberOfRounds: 10,
        extra: TruthOrDareSettings().toExtra(),
      );

  @override
  Widget buildSettingsScreen(
      GameSettings settings, ValueChanged<GameSettings> onChanged) {
    final gameSettings =
        TruthOrDareSettings.fromExtra(settings.extra);
    return TruthOrDareSettingsWidget(
      settings: gameSettings,
      onChanged: (s) {
        final updated = settings.copy();
        updated.extra = s.toExtra();
        onChanged(updated);
      },
    );
  }

  @override
  Widget buildPlayScreen(GameContext context) {
    final gameSettings =
        TruthOrDareSettings.fromExtra(context.settings.extra);
    return TruthOrDarePlayScreen(
      context: context,
      gameSettings: gameSettings,
    );
  }
}
