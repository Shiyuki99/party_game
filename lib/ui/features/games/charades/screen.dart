import 'dart:math';
import 'package:flutter/material.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/game/game_player_card.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';

enum _CharadesPhase { showWord, acting, result }

class CharadesScreen extends StatefulWidget {
  final GameContext context;

  const CharadesScreen({super.key, required this.context});

  @override
  State<CharadesScreen> createState() => _CharadesScreenState();
}

class _CharadesScreenState extends State<CharadesScreen> {
  final _rng = Random();
  int _currentActorIndex = 0;
  late String _word;
  _CharadesPhase _phase = _CharadesPhase.showWord;
  String? _winnerId;

  final _words = [
    'Elephant', 'Guitar', 'Pizza', 'Superman', 'Ballet',
    'Surfing', 'Robot', 'Pirate', 'Volcano', 'Painting',
    'Zombie', 'Astronaut', 'Ninja', 'Dragon', 'Snowman',
    'Chef', 'Wizard', 'Kangaroo', 'Helicopter', 'Tornado',
  ];

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    setState(() {
      _word = _words[_rng.nextInt(_words.length)];
      _phase = _CharadesPhase.showWord;
      _winnerId = null;
    });
  }

  void _startActing() {
    setState(() => _phase = _CharadesPhase.acting);
  }

  void _guess(String playerId) {
    setState(() {
      _winnerId = playerId;
      _phase = _CharadesPhase.result;
    });
    widget.context.addScore(playerId, 10);
  }

  void _nextRound() {
    _currentActorIndex = (_currentActorIndex + 1) % widget.context.players.length;
    _newRound();
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.context.players;
    final actor = players[_currentActorIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('Charades - Round ${_currentActorIndex + 1}',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          if (_phase == _CharadesPhase.showWord) ...[
            GamePlayerCard(player: actor, index: _currentActorIndex, avatarSize: 80),
            const SizedBox(height: 16),
            Text('Your word:', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_word,
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Show to ${actor.name} only, then tap start',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton(label: 'Start Acting', onPressed: _startActing),
          ],
          if (_phase == _CharadesPhase.acting) ...[
            Text('${actor.name} is acting!',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (ctx, i) {
                  if (players[i].id == actor.id) return const SizedBox();
                  return GamePlayerCard(
                    player: players[i],
                    index: i,
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _guess(players[i].id),
                  );
                },
              ),
            ),
          ],
          if (_phase == _CharadesPhase.result) ...[
            Text('The word was: $_word',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(
                '${players.firstWhere((p) => p.id == _winnerId).name} guessed!',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            const SizedBox(height: 24),
            AppButton(label: 'Next Round', onPressed: _nextRound),
          ],
        ],
      ),
    );
  }
}
