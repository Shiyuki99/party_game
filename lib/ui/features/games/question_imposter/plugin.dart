import 'package:flutter/material.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/question_imposter/play.dart';

class QuestionImposterPlugin implements GamePlugin {
  @override
  String get id => 'question_imposter';

  @override
  String get name => 'Question Imposter';

  @override
  IconData get icon => Icons.quiz;

  @override
  String get description => 'Spot the imposter by their answers';

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
    return QuestionImposterPlayScreen(context: context);
  }
}
