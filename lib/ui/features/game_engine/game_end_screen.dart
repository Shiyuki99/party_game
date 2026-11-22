import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_game/data/repositories/player_repository.dart';
import 'package:party_game/provider/app_providers.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/app_scaffold.dart';

class GameEndScreen extends ConsumerWidget {
  final String gameName;
  final VoidCallback onPlayAgain;
  final VoidCallback onOtherGames;
  final VoidCallback onNewParty;

  const GameEndScreen({
    super.key,
    required this.gameName,
    required this.onPlayAgain,
    required this.onOtherGames,
    required this.onNewParty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playerRepositoryProvider);
    final scores = ref.read(scoreboardServiceProvider).scores;
    final standings = players.map((p) => MapEntry(p, scores[p.id] ?? 0)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = standings.take(3).toList();

    return AppScaffold(
      title: 'Game Over',
      showBack: false,
      body: Column(
        children: [
          const SizedBox(height: 8),
          Icon(Icons.emoji_events, size: 64, color: AppColors.warning),
          const SizedBox(height: 12),
          Text('$gameName complete!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('Final standings',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          if (top.isEmpty)
            const Expanded(
              child: Center(child: Text('No scores recorded.')),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (top.length > 1) _PodiumPlace(entry: top[1], place: 2),
                      const SizedBox(width: 12),
                      _PodiumPlace(entry: top[0], place: 1, highlight: true),
                      if (top.length > 2) ...[
                        const SizedBox(width: 12),
                        _PodiumPlace(entry: top[2], place: 3),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: standings.length,
                      itemBuilder: (context, index) {
                        final entry = standings[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.playerColors[
                                  index % AppColors.playerColors.length],
                              child: Text('${index + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            title: Text(entry.key.name),
                            trailing: Text('${entry.value} pts',
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Play Again',
            icon: Icons.replay,
            onPressed: onPlayAgain,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Other Games',
                  icon: Icons.games_outlined,
                  outlined: true,
                  onPressed: onOtherGames,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'New Party',
                  icon: Icons.group_add_outlined,
                  outlined: true,
                  onPressed: onNewParty,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final MapEntry<dynamic, int> entry;
  final int place;
  final bool highlight;

  const _PodiumPlace({
    required this.entry,
    required this.place,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (place) {
      1 => AppColors.warning,
      2 => AppColors.textSecondary,
      _ => const Color(0xFFCD7F32),
    };
    return Column(
      children: [
        CircleAvatar(
          radius: highlight ? 36 : 30,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(Icons.emoji_events, color: color, size: highlight ? 36 : 28),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 96,
          child: Text(
            entry.key.name as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Text('${entry.value} pts',
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
