import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game/core/connection/pass_play_connection.dart';
import 'package:party_game/data/models/connection_type.dart';
import 'package:party_game/data/models/party_type.dart';
import 'package:party_game/data/models/player.dart';
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
    final isHost = players.isEmpty;
    ref.read(playerRepositoryProvider.notifier).addPlayer(name, isHost: isHost);

    if (ref.read(connectionTypeProvider) == ConnectionType.passAndPlay) {
      final conn = ref.read(connectionServiceProvider);
      final player = Player(id: '', name: name, isHost: isHost);
      if (conn is PassPlayConnectionService) {
        conn.addPlayer(player);
      }
    }

    _nameController.clear();
  }

  void _startGame() {
    final players = ref.read(playerRepositoryProvider);
    if (players.isEmpty) return;
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

    return AppScaffold(
      title: 'Party Lobby',
      showBack: true,
      body: Column(
        children: [
          if (ref.watch(partyTypeProvider) == PartyType.passAndPlay) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Player name...',
                    ),
                    onSubmitted: (_) => _addPlayer(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _addPlayer,
                  icon: const Icon(Icons.add),
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          if (players.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline,
                        size: 64, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text('No players yet',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${players.length} player${players.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.playerColors[
                                index % AppColors.playerColors.length],
                            child: Text(
                              player.name.isNotEmpty
                                  ? player.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(player.name),
                          subtitle: player.isHost
                              ? const Text('Host',
                                  style: TextStyle(color: AppColors.warning))
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.close,
                                color: AppColors.textHint),
                            onPressed: () => ref
                                .read(playerRepositoryProvider.notifier)
                                .removePlayer(player.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          AppButton(
            label: players.isEmpty ? 'Add Players to Start' : 'Start Game',
            onPressed: players.isEmpty ? null : _startGame,
          ),
        ],
      ),
    );
  }
}
