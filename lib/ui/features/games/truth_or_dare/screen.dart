import 'dart:math';
import 'package:flutter/material.dart';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/game/game_player_card.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/truth_or_dare/models.dart';

enum _ToDPhase { spinning, chooseType, questioning }

class TruthOrDareScreen extends StatefulWidget {
  final GameContext context;
  final TruthOrDareSettings gameSettings;

  const TruthOrDareScreen({
    super.key,
    required this.context,
    required this.gameSettings,
  });

  @override
  State<TruthOrDareScreen> createState() => _TruthOrDareScreenState();
}

class _TruthOrDareScreenState extends State<TruthOrDareScreen> {
  late List<Player> _availablePlayers;
  _ToDPhase _phase = _ToDPhase.spinning;
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
    final c = widget.context.content;
    if (c['truths'] is List) {
      _truths.addAll((c['truths'] as List).cast<String>());
    }
    if (c['dares'] is List) {
      _dares.addAll((c['dares'] as List).cast<String>());
    }
    _truths.addAll(_defaultTruths);
    _dares.addAll(_defaultDares);
  }

  void _spin() {
    final players = _availablePlayers;
    if (players.length < 2) return;
    List<Player> candidates;
    if (widget.gameSettings.everyoneOncePerRound) {
      candidates = players.where((p) => !_askedThisRound.contains(p.id)).toList();
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
      final ac = candidates.where((p) => p.id != _lastAsker).toList();
      asker = ac.isNotEmpty ? ac[_rng.nextInt(ac.length)].id : candidates[_rng.nextInt(candidates.length)].id;
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
      _phase = _ToDPhase.chooseType;
    });
  }

  void _chooseType(AnswerType type) {
    setState(() {
      _chosenType = type;
      _phase = _ToDPhase.questioning;
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
      _phase = _ToDPhase.spinning;
    });
    _spin();
  }

  @override
  Widget build(BuildContext context) {
    final answerer = widget.context.players.firstWhere((p) => p.id == _selectedAnswerer);
    final asker = widget.context.players.firstWhere((p) => p.id == _selectedAsker);
    final answererIdx = widget.context.players.indexOf(answerer);
    final askerIdx = widget.context.players.indexOf(asker);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(_phase == _ToDPhase.questioning ? '' : 'Spin!',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 40),
          if (_phase == _ToDPhase.chooseType) ...[
            Text('Questioner', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            GamePlayerCard(player: asker, index: askerIdx, avatarSize: 64),
            const SizedBox(height: 32),
            Text('Choose', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Truth',
                    onPressed: () => _chooseType(AnswerType.truth),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    label: 'Dare',
                    onPressed: () => _chooseType(AnswerType.dare),
                  ),
                ),
              ],
            ),
          ],
          if (_phase == _ToDPhase.questioning) ...[
            Text('Answerer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            GamePlayerCard(player: answerer, index: answererIdx, avatarSize: 80),
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
            Text('Asked by ${asker.name}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            AppButton(label: 'Next Round', onPressed: _nextRound),
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
