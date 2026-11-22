import 'dart:math';

import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/truth_or_dare/models.dart';

enum TruthDarePhase { ready, choose, prompt, finished }

class TruthDareState {
  final TruthDarePhase phase;
  final int round;
  final int totalRounds;
  final String? askerId;
  final String? answererId;
  final AnswerType? choice;
  final String? prompt;
  final int earnedPoints;

  const TruthDareState({
    this.phase = TruthDarePhase.ready,
    this.round = 1,
    this.totalRounds = 1,
    this.askerId,
    this.answererId,
    this.choice,
    this.prompt,
    this.earnedPoints = 0,
  });

  TruthDareState copyWith({
    TruthDarePhase? phase,
    int? round,
    int? totalRounds,
    String? askerId,
    String? answererId,
    AnswerType? choice,
    String? prompt,
    int? earnedPoints,
  }) =>
      TruthDareState(
        phase: phase ?? this.phase,
        round: round ?? this.round,
        totalRounds: totalRounds ?? this.totalRounds,
        askerId: askerId ?? this.askerId,
        answererId: answererId ?? this.answererId,
        choice: choice ?? this.choice,
        prompt: prompt ?? this.prompt,
        earnedPoints: earnedPoints ?? this.earnedPoints,
      );
}

class TruthOrDareLogic extends GameLogic {
  @override
  final GameContext context;
  @override
  bool get isFinished => _state.phase == TruthDarePhase.finished;

  TruthDareState _state = const TruthDareState();
  TruthDareState get gameState => _state;

  late final TruthOrDareSettings _rules;
  final List<String> _truths = [];
  final List<String> _dares = [];
  final Set<String> _usedTruths = {};
  final Set<String> _usedDares = {};
  final Set<String> _askedThisRound = {};
  String? _lastAsker;
  final Random _rng = Random();

  TruthOrDareLogic(this.context);

  @override
  void init() {
    _rules = TruthOrDareSettings.fromExtra(context.settings.extra);
    _loadContent();
    _state = TruthDareState(
      phase: TruthDarePhase.ready,
      round: 1,
      totalRounds: context.settings.numberOfRounds.clamp(1, 99),
    );
    _spin();
  }

  void _loadContent() {
    final content = context.content;
    if (content['truths'] is List) {
      _truths.addAll((content['truths'] as List).whereType<String>());
    }
    if (content['dares'] is List) {
      _dares.addAll((content['dares'] as List).whereType<String>());
    }
    if (_truths.isEmpty) _truths.addAll(_fallbackTruths);
    if (_dares.isEmpty) _dares.addAll(_fallbackDares);
  }

  void _spin() {
    final players = context.players;
    if (players.length < 2) {
      _state = _state.copyWith(phase: TruthDarePhase.finished);
      notifyListeners();
      return;
    }

    List<String> candidates = players.map((p) => p.id).toList();
    if (_rules.everyoneOncePerRound) {
      final fresh = candidates.where((id) => !_askedThisRound.contains(id)).toList();
      if (fresh.length >= 2) {
        candidates = fresh;
      } else {
        _askedThisRound.clear();
      }
    }
    if (_rules.lastPlayerCantAsk && _lastAsker != null) {
      candidates.removeWhere((id) => id == _lastAsker);
      if (candidates.length < 2) candidates = players.map((p) => p.id).toList();
    }
    candidates.shuffle(_rng);

    final answerer = candidates.removeAt(0);
    String asker;
    if (_rules.noRepeatAsker && _lastAsker != null) {
      final withoutLast = candidates.where((id) => id != _lastAsker).toList();
      final pool = withoutLast.isNotEmpty ? withoutLast : candidates;
      asker = pool[_rng.nextInt(pool.length)];
    } else {
      asker = candidates[_rng.nextInt(candidates.length)];
    }

    if (_rules.everyoneOncePerRound) _askedThisRound.add(answerer);
    _lastAsker = asker;

    _state = _state.copyWith(
      phase: TruthDarePhase.choose,
      askerId: asker,
      answererId: answerer,
      choice: null,
      prompt: null,
    );
    notifyListeners();
  }

  void choose(AnswerType type) {
    final pool = type == AnswerType.truth ? _truths : _dares;
    final used = type == AnswerType.truth ? _usedTruths : _usedDares;
    if (pool.isEmpty) return;
    if (used.length >= pool.length) used.clear();
    final available = pool.where((item) => !used.contains(item)).toList();
    final prompt = available[_rng.nextInt(available.length)];
    used.add(prompt);

    _state = _state.copyWith(
      phase: TruthDarePhase.prompt,
      choice: type,
      prompt: prompt,
    );
    notifyListeners();
  }

  void complete() {
    final answerer = _state.answererId;
    if (answerer != null) context.addScore(answerer, 1);

    if (_state.round >= _state.totalRounds) {
      _state = _state.copyWith(
        phase: TruthDarePhase.finished,
        earnedPoints: _state.earnedPoints + (answerer != null ? 1 : 0),
      );
    } else {
      _state = _state.copyWith(
        round: _state.round + 1,
        earnedPoints: _state.earnedPoints + (answerer != null ? 1 : 0),
      );
      _spin();
    }
    notifyListeners();
  }

  void addCustom(AnswerType type, String text) {
    if (!_rules.allowCustomContent) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    (type == AnswerType.truth ? _truths : _dares).add(trimmed);
    notifyListeners();
  }

  @override
  void handleAction(String action, {Map<String, dynamic>? payload}) {
    switch (action) {
      case 'choose':
        final raw = payload?['type'] as String?;
        if (raw == 'truth') choose(AnswerType.truth);
        if (raw == 'dare') choose(AnswerType.dare);
      case 'complete':
        complete();
      case 'custom':
        final raw = payload?['type'] as String?;
        final text = payload?['text'] as String? ?? '';
        if (raw == 'truth') addCustom(AnswerType.truth, text);
        if (raw == 'dare') addCustom(AnswerType.dare, text);
      case 'finish':
        _state = _state.copyWith(phase: TruthDarePhase.finished);
        notifyListeners();
        context.onGameEnd();
    }
  }

  @override
  void tick() {}
}

const _fallbackTruths = [
  'What is your biggest fear?',
  'What is your guilty pleasure?',
  'What is the most embarrassing thing you have done?',
];

const _fallbackDares = [
  'Do 10 push-ups',
  'Sing a song loudly',
  'Dance for 30 seconds',
];
