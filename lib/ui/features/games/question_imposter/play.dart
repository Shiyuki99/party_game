import 'dart:math';
import 'package:flutter/material.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/player_avatar.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';

enum _QiPhase { revealRole, answer, vote, result }

class QuestionImposterPlayScreen extends StatefulWidget {
  final GameContext context;
  const QuestionImposterPlayScreen({super.key, required this.context});

  @override
  State<QuestionImposterPlayScreen> createState() =>
      _QuestionImposterPlayScreenState();
}

class _QuestionImposterPlayScreenState
    extends State<QuestionImposterPlayScreen> {
  final _rng = Random();
  late int _imposterIndex;
  String _question = '';
  final _answers = <int, String>{};
  final _votes = <int, int>{};
  int _currentPlayerIndex = 0;
  int? _votedFor;
  String? _resultMsg;
  _QiPhase _phase = _QiPhase.revealRole;

  final _questions = [
    'What is your favorite food?',
    'Where do you see yourself in 5 years?',
    'What superpower would you choose?',
    'What is your dream travel destination?',
    'What hobby do you enjoy most?',
    'What is your favorite movie genre?',
    'What animal would you be?',
    'What is your biggest achievement?',
    'What do you do to relax?',
    'What is your favorite season?',
  ];

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    _question = _questions[_rng.nextInt(_questions.length)];
    setState(() {
      _imposterIndex = _rng.nextInt(widget.context.players.length);
      _currentPlayerIndex = 0;
      _answers.clear();
      _votes.clear();
      _votedFor = null;
      _resultMsg = null;
      _phase = _QiPhase.revealRole;
    });
  }

  void _submitAnswer(String answer) {
    setState(() {
      _answers[_currentPlayerIndex] = answer;
      if (_currentPlayerIndex < widget.context.players.length - 1) {
        _currentPlayerIndex++;
        _phase = _QiPhase.revealRole;
      } else {
        _phase = _QiPhase.vote;
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
        _resolve();
      }
    });
  }

  void _resolve() {
    final counts = <int, int>{};
    for (final v in _votes.values) {
      counts.update(v, (c) => c + 1, ifAbsent: () => 1);
    }
    int? top;
    int max = 0;
    counts.forEach((pid, c) {
      if (c > max) { max = c; top = pid; }
    });

    final imposterCaught = top == _imposterIndex;
    _resultMsg = imposterCaught ? 'Imposter caught!' : 'Imposter wins!';
    if (imposterCaught) {
      for (int i = 0; i < widget.context.players.length; i++) {
        if (i != _imposterIndex) {
          widget.context.addScore(widget.context.players[i].id, 10);
        }
      }
    } else {
      widget.context.addScore(widget.context.players[_imposterIndex].id, 15);
    }
    setState(() => _phase = _QiPhase.result);
  }

  void _nextRound() {
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
          if (_phase == _QiPhase.revealRole) ...[
            const Spacer(),
            Text('Player ${_currentPlayerIndex + 1}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            PlayerAvatar(name: current.name, index: _currentPlayerIndex, size: 80),
            const SizedBox(height: 32),
            if (current.id == players[_imposterIndex].id) ...[
              Text('You are the IMPOSTER!',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error)),
              const SizedBox(height: 16),
              Text('Everyone else has a question. Make up a believable answer.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ] else ...[
              Text('Your question:',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_question,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                ),
              ),
            ],
            const SizedBox(height: 32),
            AppButton(
                label: 'Got it', onPressed: () => setState(() => _phase = _QiPhase.answer)),
            const Spacer(),
          ],
          if (_phase == _QiPhase.answer) ...[
            Text('${current.name}, answer:',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            TextField(
              decoration: const InputDecoration(hintText: 'Your answer...'),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) _submitAnswer(v.trim());
              },
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Submit',
              onPressed: () => _submitAnswer(''),
            ),
          ],
          if (_phase == _QiPhase.vote) ...[
            Text('The question was:',
                style: Theme.of(context).textTheme.titleMedium),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_question,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (ctx, i) => Card(
                  color: _votedFor == i ? AppColors.primary : null,
                  child: ListTile(
                    leading: PlayerAvatar(name: players[i].name, index: i),
                    title: Text(players[i].name),
                    subtitle: _answers.containsKey(i)
                        ? Text('"${_answers[i]}"',
                            style: const TextStyle(
                                color: AppColors.textSecondary))
                        : null,
                    trailing: _votedFor == i
                        ? const Icon(Icons.check_circle,
                            color: AppColors.accent)
                        : null,
                    onTap: () => setState(() => _votedFor = i),
                  ),
                ),
              ),
            ),
            AppButton(
              label: 'Vote',
              onPressed: _votedFor != null ? _vote : null,
            ),
          ],
          if (_phase == _QiPhase.result) ...[
            const Spacer(),
            Text(_resultMsg!,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _resultMsg!.contains('caught')
                      ? AppColors.success
                      : AppColors.error,
                )),
            const SizedBox(height: 16),
            Text('Imposter: ${players[_imposterIndex].name}',
                style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            AppButton(label: 'Next Round', onPressed: _nextRound),
          ],
        ],
      ),
    );
  }
}
