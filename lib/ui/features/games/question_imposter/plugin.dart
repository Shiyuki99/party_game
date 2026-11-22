import 'package:flutter/material.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
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
    BuildContext context,
    GameSettings settings,
    ValueChanged<GameSettings> onChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_off, color: AppColors.primary),
                const SizedBox(width: 12),
                Text('Imposters',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Slider(
              value: settings.numberOfImposters.toDouble(),
              min: 1,
              max: 3,
              divisions: 2,
              label: '${settings.numberOfImposters}',
              onChanged: (v) {
                final c = settings.copy();
                c.numberOfImposters = v.toInt();
                onChanged(c);
              },
            ),
            Text(
              'Imposters do not see the question and must bluff their way '
              'through the answers.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  GameLogic createLogic(GameContext context) =>
      QuestionImposterLogic(context);

  @override
  Widget buildScreen(GameLogic logic, GameContext context) {
    return QuestionImposterScreen(
      logic: logic as QuestionImposterLogic,
      context: context,
    );
  }
}
