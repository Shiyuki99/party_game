import 'package:flutter/material.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/charades/logic.dart';
import 'package:party_game/ui/features/games/charades/screen.dart';

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
        mode: GameMode.timeBased,
        roundTimeSeconds: 60,
        numberOfRounds: 10,
        turnsPerPlayer: 1,
        extra: const {'charadesMode': 'solo'},
      );

  @override
  Widget buildSettingsScreen(
    BuildContext context,
    GameSettings settings,
    ValueChanged<GameSettings> onChanged,
  ) {
    final mode = settings.extra['charadesMode'] as String? ?? 'solo';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Text('Play style',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'solo',
                  label: Text('Everyone'),
                  icon: Icon(Icons.person_outline),
                ),
                ButtonSegment(
                  value: 'team',
                  label: Text('Teams'),
                  icon: Icon(Icons.groups_outlined),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (v) {
                final c = settings.copy();
                c.extra = {...settings.extra, 'charadesMode': v.first};
                onChanged(c);
              },
            ),
            const SizedBox(height: 12),
            Text(
              mode == 'team'
                  ? 'Split by player order (A, B, A, B). The whole team scores when one member guesses.'
                  : 'Anyone except the actor can guess. First correct guess scores 10 points.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  GameLogic createLogic(GameContext context) => CharadesLogic(context);

  @override
  Widget buildScreen(GameLogic logic, GameContext context) {
    return CharadesScreen(
      logic: logic as CharadesLogic,
      context: context,
    );
  }
}
