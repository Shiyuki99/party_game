import 'package:flutter/material.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/question_imposter/logic.dart';
import 'package:party_game/ui/features/games/question_imposter/screen.dart';

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
        numberOfRounds: 5,
        numberOfImposters: 1,
        turnsPerPlayer: 1,
      );

  @override
  Widget buildSettingsScreen(
      BuildContext context, GameSettings settings, ValueChanged<GameSettings> onChanged) {
    return const SizedBox();
  }

  @override
  GameLogic createLogic(GameContext context) =>
      QuestionImposterLogic(context);

  @override
  Widget buildScreen(GameLogic logic, GameContext context) {
    return QuestionImposterScreen(context: context);
  }
}
