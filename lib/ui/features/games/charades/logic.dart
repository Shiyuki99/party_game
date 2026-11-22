import 'dart:math';

import 'package:party_game/ui/features/game_engine/game_plugin.dart';

enum CharadesPhase { showWord, acting, roundResult, finished }

class CharadesState {
  final CharadesPhase phase;
  final int round;
  final int totalRounds;
  final int actorIndex;
  final String word;
  final String? winnerId;
  final int pointsAwarded;
  final bool timedOut;
  final int remainingTime;

  const CharadesState({
    this.phase = CharadesPhase.showWord,
    this.round = 1,
    this.totalRounds = 1,
    this.actorIndex = 0,
    this.word = '',
    this.winnerId,
    this.pointsAwarded = 0,
    this.timedOut = false,
    this.remainingTime = 0,
  });

  CharadesState copyWith({
    CharadesPhase? phase,
    int? round,
    int? totalRounds,
    int? actorIndex,
    String? word,
    String? winnerId,
    int? pointsAwarded,
    bool? timedOut,
    int? remainingTime,
  }) =>
      CharadesState(
        phase: phase ?? this.phase,
        round: round ?? this.round,
        totalRounds: totalRounds ?? this.totalRounds,
        actorIndex: actorIndex ?? this.actorIndex,
        word: word ?? this.word,
        winnerId: winnerId ?? this.winnerId,
        pointsAwarded: pointsAwarded ?? this.pointsAwarded,
        timedOut: timedOut ?? this.timedOut,
        remainingTime: remainingTime ?? this.remainingTime,
      );
}

class CharadesLogic extends GameLogic {
  @override
  final GameContext context;
  @override
  bool get isFinished => _state.phase == CharadesPhase.finished;

  CharadesState _state = const CharadesState();
  CharadesState get gameState => _state;

  final Random _rng = Random();
  late final List<String> _words;
  final Set<String> _usedWords = {};

  CharadesLogic(this.context);

  bool get isTeamMode => context.settings.extra['charadesMode'] == 'team';

  @override
  void init() {
    final fromContent = context.content['words'] is List
        ? (context.content['words'] as List).whereType<String>().toList()
        : <String>[];
    _words = fromContent.isNotEmpty ? fromContent : _fallbackWords;

    if (context.players.length < 2) {
      _state = _state.copyWith(phase: CharadesPhase.finished);
      notifyListeners();
      return;
    }
    _state = CharadesState(
      totalRounds: context.settings.numberOfRounds.clamp(1, 30),
      remainingTime: context.settings.roundTimeSeconds,
    );
    _startRound();
  }

  void _startRound() {
    if (_usedWords.length >= _words.length) _usedWords.clear();
    final available = _words.where((w) => !_usedWords.contains(w)).toList();
    final word = available[_rng.nextInt(available.length)];
    _usedWords.add(word);

    final start = (context.settings.rotatingHost
            ? _rng.nextInt(context.players.length)
            : (_state.round - 1) % context.players.length);

    _state = _state.copyWith(
      phase: CharadesPhase.showWord,
      actorIndex: start,
      word: word,
      winnerId: null,
      pointsAwarded: 0,
      timedOut: false,
      remainingTime: context.settings.roundTimeSeconds,
    );
    notifyListeners();
  }

  void startActing() {
    if (_state.phase != CharadesPhase.showWord) return;
    _state = _state.copyWith(phase: CharadesPhase.acting);
    notifyListeners();
  }

  void guess(String playerId) {
    if (_state.phase != CharadesPhase.acting) return;
    final actor = context.players[_state.actorIndex];
    if (playerId == actor.id) return;

    final guesserIndex = context.players.indexWhere((p) => p.id == playerId);
    if (guesserIndex < 0) return;

    int points = 0;
    if (isTeamMode) {
      final team = guesserIndex.isEven ? 0 : 1;
      for (int i = 0; i < context.players.length; i++) {
        if (i.isEven ? team == 0 : team == 1) {
          context.addScore(context.players[i].id, 10);
          points += 10;
        }
      }
    } else {
      context.addScore(playerId, 10);
      points = 10;
    }

    _state = _state.copyWith(
      phase: CharadesPhase.roundResult,
      winnerId: playerId,
      pointsAwarded: points,
      timedOut: false,
    );
    notifyListeners();
  }

  void skip() {
    if (_state.phase != CharadesPhase.acting) return;
    _state = _state.copyWith(
      phase: CharadesPhase.roundResult,
      winnerId: null,
      pointsAwarded: 0,
      timedOut: true,
    );
    notifyListeners();
  }

  void nextRound() {
    if (_state.round >= _state.totalRounds) {
      _state = _state.copyWith(phase: CharadesPhase.finished);
    } else {
      _state = _state.copyWith(round: _state.round + 1);
      _startRound();
    }
    notifyListeners();
  }

  @override
  void handleAction(String action, {Map<String, dynamic>? payload}) {
    switch (action) {
      case 'start_acting':
        startActing();
      case 'guess':
        guess(payload?['playerId'] as String? ?? '');
      case 'skip':
        skip();
      case 'next_round':
        nextRound();
      case 'finish':
        _state = _state.copyWith(phase: CharadesPhase.finished);
        notifyListeners();
        context.onGameEnd();
    }
  }

  @override
  void tick() {
    if (_state.phase != CharadesPhase.acting) return;
    if (_state.remainingTime <= 0) return;
    final next = _state.remainingTime - 1;
    if (next > 0) {
      _state = _state.copyWith(remainingTime: next);
      notifyListeners();
    } else {
      _state = _state.copyWith(remainingTime: 0);
      skip();
    }
  }
}

const _fallbackWords = [
  'Elephant',
  'Guitar',
  'Pizza',
  'Robot',
  'Astronaut',
];
