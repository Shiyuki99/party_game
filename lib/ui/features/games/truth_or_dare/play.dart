import 'dart:math';
import 'package:flutter/material.dart';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/player_avatar.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/truth_or_dare/models.dart';

enum _GamePhase { spinning, chooseType, questioning }

class TruthOrDarePlayScreen extends StatefulWidget {
  final GameContext context;
  final TruthOrDareSettings gameSettings;

  const TruthOrDarePlayScreen({
    super.key,
    required this.context,
    required this.gameSettings,
  });

  @override
  State<TruthOrDarePlayScreen> createState() => _TruthOrDarePlayScreenState();
}

class _TruthOrDarePlayScreenState extends State<TruthOrDarePlayScreen> {
  late List<Player> _availablePlayers;
  int _currentRound = 0;
  _GamePhase _phase = _GamePhase.spinning;
  String? _selectedAnswerer;
  String? _selectedAsker;
  AnswerType? _chosenType;

  final _truths = <String>[];
  final _dares = <String>[];
  final _askedThisRound = <String>{};
  String? _lastAsker;

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _availablePlayers = List.from(widget.context.players);
    _loadContent();
    _spin();
  }

  void _loadContent() {
    final content = widget.context.content;
    if (content['truths'] is List) {
      _truths.addAll((content['truths'] as List).cast<String>());
    }
    if (content['dares'] is List) {
      _dares.addAll((content['dares'] as List).cast<String>());
    }
    _truths.addAll(_defaultTruths);
    _dares.addAll(_defaultDares);
  }

  void _spin() {
    final players = _availablePlayers;
    if (players.length < 2) return;

    List<Player> candidates;
    if (widget.gameSettings.everyoneOncePerRound) {
      candidates = players
          .where((p) => !_askedThisRound.contains(p.id))
          .toList();
      if (candidates.length < 2) {
        _askedThisRound.clear();
        candidates = List.from(players);
      }
    } else {
      candidates = List.from(players);
    }

    if (widget.gameSettings.lastPlayerCantAsk && _lastAsker != null) {
      candidates.removeWhere((p) => p.id == _lastAsker);
    }

    candidates.shuffle(_rng);
    final answerer = candidates.removeAt(0);
    String? asker;

    if (widget.gameSettings.noRepeatAsker && _lastAsker != null) {
      final askerCandidates = candidates.where((p) => p.id != _lastAsker).toList();
      asker = askerCandidates.isNotEmpty
          ? askerCandidates[_rng.nextInt(askerCandidates.length)].id
          : candidates[_rng.nextInt(candidates.length)].id;
    } else {
      asker = candidates[_rng.nextInt(candidates.length)].id;
    }

    if (widget.gameSettings.everyoneOncePerRound) {
      _askedThisRound.add(answerer.id);
    }

    _lastAsker = asker;
    setState(() {
      _selectedAnswerer = answerer.id;
      _selectedAsker = asker;
      _phase = _GamePhase.chooseType;
    });
  }

  void _chooseType(AnswerType type) {
    setState(() {
      _chosenType = type;
      _phase = _GamePhase.questioning;
    });
  }

  String _getContent(AnswerType type) {
    final pool = type == AnswerType.truth ? _truths : _dares;
    if (pool.isEmpty) return type == AnswerType.truth ? 'Tell the truth!' : 'Do a dare!';
    return pool[_rng.nextInt(pool.length)];
  }

  void _nextRound() {
    setState(() {
      _chosenType = null;
      _phase = _GamePhase.spinning;
    });
    _spin();
  }

  @override
  Widget build(BuildContext context) {
    final answerer = widget.context.players
        .firstWhere((p) => p.id == _selectedAnswerer);
    final asker = widget.context.players
        .firstWhere((p) => p.id == _selectedAsker);
    final answererIdx = widget.context.players.indexOf(answerer);
    final askerIdx = widget.context.players.indexOf(asker);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text('Round ${_currentRound + 1}',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 40),

          if (_phase == _GamePhase.chooseType) ...[
            Text('Questioner', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            PlayerAvatar(name: asker.name, index: askerIdx, size: 64),
            const SizedBox(height: 32),
            Text('Choose', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Truth',
                    color: AppColors.accent,
                    onPressed: () => _chooseType(AnswerType.truth),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    label: 'Dare',
                    color: AppColors.secondary,
                    onPressed: () => _chooseType(AnswerType.dare),
                  ),
                ),
              ],
            ),
          ],

          if (_phase == _GamePhase.questioning) ...[
            Text('Answerer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            PlayerAvatar(name: answerer.name, index: answererIdx, size: 80),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _getContent(_chosenType!),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Asked by ${asker.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
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

const _defaultTruths = [
  'What is your biggest fear?',
  'Have you ever lied to a friend?',
  'What is the most embarrassing thing you\'ve done?',
  'Who do you secretly admire?',
  'What is your guilty pleasure?',
  'Have you ever cheated in a game?',
  'What is the worst gift you\'ve received?',
  'What is a secret you\'ve never told anyone?',
];

const _defaultDares = [
  'Do 10 push-ups',
  'Sing a song loudly',
  'Speak in an accent for 1 minute',
  'Let someone draw on your face',
  'Dance for 30 seconds',
  'Call a friend and say "I love you"',
  'Hold your breath for 15 seconds',
  'Do your best animal impression',
];
