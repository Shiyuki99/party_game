import 'package:flutter/material.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/imposter/logic.dart';
import 'package:party_game/ui/features/games/imposter/screen.dart';

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
        numberOfRounds: 5,
        numberOfImposters: 1,
        turnsPerPlayer: 2,
      );

  @override
  Widget buildSettingsScreen(
      BuildContext context, GameSettings settings, ValueChanged<GameSettings> onChanged) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Imposters',
                style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                const Icon(Icons.person_off, color: AppColors.primary),
                Expanded(
                  child: Slider(
                    value: settings.numberOfImposters.toDouble(),
                    min: 1, max: 3, divisions: 2,
                    activeColor: AppColors.primary,
                    label: '${settings.numberOfImposters}',
                    onChanged: (v) {
                      final c = settings.copy();
                      c.numberOfImposters = v.toInt();
                      onChanged(c);
                    },
                  ),
                ),
                Text('${settings.numberOfImposters}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  GameLogic createLogic(GameContext context) => ImposterLogic(context);

  @override
  Widget buildScreen(GameLogic logic, GameContext context) {
    return ImposterScreen(logic: logic as ImposterLogic, context: context);
  }
}
