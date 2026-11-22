import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game/data/repositories/player_repository.dart';
import 'package:party_game/provider/app_providers.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_scaffold.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/game_engine/game_registry.dart';

class GameSelectScreen extends ConsumerWidget {
  const GameSelectScreen({super.key});

  Future<void> _confirmNewParty(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new party?'),
        content: const Text(
          'This clears all players and resets the scoreboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('New Party'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(playerRepositoryProvider.notifier).clear();
      ref.read(scoreboardServiceProvider).reset();
      if (context.mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = gamePlugins;
    final players = ref.watch(playerRepositoryProvider);
    final scores = ref.read(scoreboardServiceProvider).scores;
    final leaders = players.map((p) => MapEntry(p, scores[p.id] ?? 0)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AppScaffold(
      title: 'Select Game',
      actions: [
        IconButton(
          tooltip: 'New party',
          icon: const Icon(Icons.group_add_outlined),
          onPressed: () => _confirmNewParty(context, ref),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.groups_outlined, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('${players.length} players',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text('Party scores',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: leaders.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final entry = leaders[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: AppColors.playerColors[
                                    index % AppColors.playerColors.length],
                                child: Text(
                                  entry.key.name.isNotEmpty
                                      ? entry.key.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(entry.key.name,
                                  style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(width: 6),
                              Text('${entry.value}',
                                  style: const TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: games.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.games_outlined,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text('No games installed',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final game = games[index];
                      return _GameCard(
                        game: game,
                        onTap: () => context.push('/game-settings/${game.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GamePlugin game;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.playerColors[
        gamePlugins.indexOf(game) % AppColors.playerColors.length];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(game.icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                game.name,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                game.description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
