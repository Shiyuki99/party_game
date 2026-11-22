import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game/core/connection/pass_play_connection.dart';
import 'package:party_game/data/models/connection_type.dart';
import 'package:party_game/data/repositories/player_repository.dart';
import 'package:party_game/provider/app_providers.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/app_scaffold.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _nameController = TextEditingController();

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final players = ref.read(playerRepositoryProvider);
    final player = ref
        .read(playerRepositoryProvider.notifier)
        .addPlayer(name, isHost: players.isEmpty);

    if (ref.read(connectionTypeProvider) == ConnectionType.passAndPlay) {
      final conn = ref.read(connectionServiceProvider);
      if (conn is PassPlayConnectionService) conn.addPlayer(player);
    }
    _nameController.clear();
  }

  void _removePlayer(String id) {
    ref.read(playerRepositoryProvider.notifier).removePlayer(id);
    final conn = ref.read(connectionServiceProvider);
    if (conn is PassPlayConnectionService) conn.removePlayer(id);
  }

  void _startGame() {
    if (ref.read(playerRepositoryProvider).length < 2) return;
    context.push('/game-select');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(playerRepositoryProvider);
    final canStart = players.length >= 2;

    return AppScaffold(
      title: 'Party Lobby',
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Player name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onSubmitted: (_) => _addPlayer(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                tooltip: 'Add player',
                onPressed: _addPlayer,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(56, 56),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add at least 2 players. Names can be anything — have fun with it.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (players.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline,
                        size: 72, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text('No players yet',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Add the first player above to get started.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        '${players.length} player${players.length > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          for (final p in players) {
                            final conn = ref.read(connectionServiceProvider);
                            if (conn is PassPlayConnectionService) {
                              conn.removePlayer(p.id);
                            }
                          }
                          ref.read(playerRepositoryProvider.notifier).clear();
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Clear all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.playerColors[
                                  index % AppColors.playerColors.length],
                              child: Text(
                                player.name.isNotEmpty
                                    ? player.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(player.name),
                            subtitle: player.isHost
                                ? const Text('Host',
                                    style:
                                        TextStyle(color: AppColors.warning))
                                : null,
                            trailing: IconButton(
                              tooltip: 'Remove ${player.name}',
                              icon: const Icon(Icons.close),
                              onPressed: () => _removePlayer(player.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          AppButton(
            label: canStart
                ? 'Choose a Game'
                : 'Add ${2 - players.length} more to start',
            icon: Icons.arrow_forward,
            onPressed: canStart ? _startGame : null,
          ),
        ],
      ),
    );
  }
}
