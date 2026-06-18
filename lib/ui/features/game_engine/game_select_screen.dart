import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_scaffold.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/game_engine/game_registry.dart';

class GameSelectScreen extends ConsumerWidget {
  const GameSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = gamePlugins;

    return AppScaffold(
      title: 'Select Game',
      body: games.isEmpty
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                  onTap: () =>
                      context.push('/game-settings/${game.id}'),
                );
              },
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(game.icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                game.name,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                game.description,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
