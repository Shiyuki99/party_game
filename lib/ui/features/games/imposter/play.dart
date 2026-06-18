import 'dart:math';
import 'package:flutter/material.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/player_avatar.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';

enum _ImposterPhase {
  assigningRoles,
  revealRole,
  description,
  voting,
  result,
}

class ImposterPlayScreen extends StatefulWidget {
  final GameContext context;

  const ImposterPlayScreen({super.key, required this.context});

  @override
  State<ImposterPlayScreen> createState() => _ImposterPlayScreenState();
}

class _ImposterPlayScreenState extends State<ImposterPlayScreen> {
  final _rng = Random();
  late int _imposterIndex;

  _ImposterPhase _phase = _ImposterPhase.assigningRoles;
  int _currentPlayerIndex = 0;
  String? _currentDescription;
  final _descriptions = <int, String>{};
  int? _votedFor;
  final _votes = <int, int>{};
  String? _lastRoundImposterGuess;

  final _wordPool = {
    'Food': ['Pizza', 'Sushi', 'Chocolate', 'Pasta', 'Ice Cream'],
    'Animals': ['Elephant', 'Penguin', 'Dolphin', 'Giraffe', 'Kangaroo'],
    'Movies': ['Inception', 'Avatar', 'Titanic', 'Joker', 'Gladiator'],
    'Countries': ['Japan', 'Brazil', 'Egypt', 'Canada', 'Australia'],
    'Sports': ['Soccer', 'Basketball', 'Tennis', 'Swimming', 'Boxing'],
    'Music': ['Guitar', 'Piano', 'Jazz', 'Rock', 'Classical'],
    'Video Games': ['Minecraft', 'Tetris', 'Zelda', 'Mario', 'Portal'],
    'Science': ['Gravity', 'DNA', 'Atom', 'Laser', 'Robot'],
  };

  String _activeCategory = 'Food';
  String _activeWord = 'Pizza';

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    final cats = _wordPool.keys.toList();
    _activeCategory = cats[_rng.nextInt(cats.length)];
    final words = _wordPool[_activeCategory]!;
    _activeWord = words[_rng.nextInt(words.length)];

    setState(() {
      _imposterIndex = _rng.nextInt(widget.context.players.length);
      _currentPlayerIndex = 0;
      _descriptions.clear();
      _votes.clear();
      _votedFor = null;
      _lastRoundImposterGuess = null;
      _phase = _ImposterPhase.revealRole;
    });
  }

  void _submitDescription(String desc) {
    setState(() {
      _descriptions[_currentPlayerIndex] = desc;
      _currentDescription = null;
      if (_currentPlayerIndex < widget.context.players.length - 1) {
        _currentPlayerIndex++;
        _phase = _ImposterPhase.revealRole;
      } else {
        _phase = _ImposterPhase.voting;
        _currentPlayerIndex = 0;
      }
    });
  }

  void _vote() {
    if (_votedFor == null) return;
    setState(() {
      _votes[_currentPlayerIndex] = _votedFor!;
      _votedFor = null;
      if (_currentPlayerIndex < widget.context.players.length - 1) {
        _currentPlayerIndex++;
      } else {
        _resolveVote();
      }
    });
  }

  void _resolveVote() {
    final voteCounts = <int, int>{};
    for (final v in _votes.values) {
      voteCounts.update(v, (c) => c + 1, ifAbsent: () => 1);
    }
    int? maxVoted;
    int maxCount = 0;
    voteCounts.forEach((pid, count) {
      if (count > maxCount) {
        maxCount = count;
        maxVoted = pid;
      }
    });

    _lastRoundImposterGuess = maxVoted == _imposterIndex ? 'Correct!' : 'Wrong!';
    if (maxVoted == _imposterIndex) {
      widget.context.addScore(
        widget.context.players
            .where((p) => p.id != widget.context.players[_imposterIndex].id)
            .first
            .id,
        10,
      );
    } else {
      widget.context.addScore(
        widget.context.players[_imposterIndex].id,
        10,
      );
    }
    setState(() => _phase = _ImposterPhase.result);
  }

  void _nextRound() {
    if (_currentPlayerIndex >= widget.context.settings.numberOfRounds) {
      widget.context.onGameEnd();
      return;
    }
    _currentPlayerIndex++;
    _startRound();
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.context.players;
    final current = players[_currentPlayerIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_phase == _ImposterPhase.revealRole) ...[
            const Spacer(),
            Text('Player ${_currentPlayerIndex + 1}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            PlayerAvatar(name: current.name, index: _currentPlayerIndex, size: 80),
            const SizedBox(height: 32),
            if (current.id == players[_imposterIndex].id) ...[
              const Text('You are the IMPOSTER!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.error)),
              const SizedBox(height: 16),
              Text('Category: $_activeCategory',
                  style: Theme.of(context).textTheme.titleMedium),
            ] else ...[
              const Text('Your word:',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              Text(_activeWord,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.accent)),
            ],
            const SizedBox(height: 32),
            Text('Pass phone to ${current.name}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            AppButton(
              label: 'Got it, next',
              onPressed: () => setState(() {
                _phase = _ImposterPhase.description;
              }),
            ),
            const Spacer(),
          ],
          if (_phase == _ImposterPhase.description) ...[
            Text('${current.name}, describe:',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Say ONE word related to your word',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            TextField(
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) _submitDescription(v.trim());
              },
              decoration: const InputDecoration(hintText: 'Your word...'),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Submit',
              onPressed: () {
                if (_currentDescription != null && _currentDescription!.trim().isNotEmpty) {
                  _submitDescription(_currentDescription!.trim());
                }
              },
            ),
          ],
          if (_phase == _ImposterPhase.voting) ...[
            Text('Vote!', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text('Who is the imposter?'),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (ctx, i) => Card(
                  color: _votedFor == i ? AppColors.primary : null,
                  child: ListTile(
                    leading: PlayerAvatar(name: players[i].name, index: i),
                    title: Text(players[i].name),
                    trailing: _votedFor == i
                        ? const Icon(Icons.check_circle, color: AppColors.accent)
                        : null,
                    onTap: () => setState(() => _votedFor = i),
                  ),
                ),
              ),
            ),
            AppButton(
              label: 'Submit Vote',
              onPressed: _votedFor != null ? _vote : null,
            ),
          ],
          if (_phase == _ImposterPhase.result) ...[
            const Spacer(),
            Text(_lastRoundImposterGuess == 'Correct!'
                ? 'Imposter Found!'
                : 'Imposter Escaped!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _lastRoundImposterGuess == 'Correct!'
                      ? AppColors.success
                      : AppColors.error,
                )),
            const SizedBox(height: 16),
            Text('The word was: $_activeWord',
                style: Theme.of(context).textTheme.titleLarge),
            Text('Category: $_activeCategory',
                style: Theme.of(context).textTheme.bodyMedium),
            Text('Imposter was: ${players[_imposterIndex].name}',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            AppButton(
              label: 'Next Round',
              onPressed: _nextRound,
            ),
          ],
        ],
      ),
    );
  }
}
