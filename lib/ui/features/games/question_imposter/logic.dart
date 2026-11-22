import 'dart:math';

import 'package:party_game/ui/features/game_engine/game_plugin.dart';

enum QuestionImposterPhase { reveal, answering, voting, roundResult, finished }

class QuestionImposterState {
  final QuestionImposterPhase phase;
  final int round;
  final int totalRounds;
  final String question;
  final Set<int> imposters;
  final Map<int, String> answers;
  final Map<int, int> votes;
  final int currentPlayerIndex;
  final String? resultMessage;
  final bool imposterCaught;
  final int remainingTime;

  const QuestionImposterState({
    this.phase = QuestionImposterPhase.reveal,
    this.round = 1,
    this.totalRounds = 1,
    this.question = '',
    this.imposters = const {},
    this.answers = const {},
    this.votes = const {},
    this.currentPlayerIndex = 0,
    this.resultMessage,
    this.imposterCaught = false,
    this.remainingTime = 0,
  });

  QuestionImposterState copyWith({
    QuestionImposterPhase? phase,
    int? round,
    int? totalRounds,
    String? question,
    Set<int>? imposters,
    Map<int, String>? answers,
    Map<int, int>? votes,
    int? currentPlayerIndex,
    String? resultMessage,
    bool? imposterCaught,
    int? remainingTime,
  }) =>
      QuestionImposterState(
        phase: phase ?? this.phase,
        round: round ?? this.round,
        totalRounds: totalRounds ?? this.totalRounds,
        question: question ?? this.question,
        imposters: imposters ?? this.imposters,
        answers: answers ?? this.answers,
        votes: votes ?? this.votes,
        currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
        resultMessage: resultMessage ?? this.resultMessage,
        imposterCaught: imposterCaught ?? this.imposterCaught,
        remainingTime: remainingTime ?? this.remainingTime,
      );
}

class QuestionImposterLogic extends GameLogic {
  @override
  final GameContext context;
  @override
  bool get isFinished => _state.phase == QuestionImposterPhase.finished;

  QuestionImposterState _state = const QuestionImposterState();
  QuestionImposterState get gameState => _state;

  final Random _rng = Random();
  late final List<String> _questions;

  QuestionImposterLogic(this.context);

  @override
  void init() {
    final fromContent = context.content['questions'] is List
        ? (context.content['questions'] as List).whereType<String>().toList()
        : <String>[];
    _questions = fromContent.isNotEmpty ? fromContent : _fallbackQuestions;

    if (context.players.length < 2) {
      _state = _state.copyWith(phase: QuestionImposterPhase.finished);
      notifyListeners();
      return;
    }
    _state = QuestionImposterState(
      totalRounds: context.settings.numberOfRounds.clamp(1, 20),
      remainingTime: context.settings.roundTimeSeconds,
    );
    _startRound();
  }

  void _startRound() {
    final count = context.settings.numberOfImposters.clamp(
      1,
      context.players.length - 1,
    );
    final indices = List<int>.generate(context.players.length, (i) => i)
      ..shuffle(_rng);
    final imposters = indices.take(count).toSet();

    _state = _state.copyWith(
      phase: QuestionImposterPhase.reveal,
      question: _questions[_rng.nextInt(_questions.length)],
      imposters: imposters,
      answers: const {},
      votes: const {},
      currentPlayerIndex: 0,
      resultMessage: null,
      imposterCaught: false,
      remainingTime: context.settings.roundTimeSeconds,
    );
    notifyListeners();
  }

  void acknowledge() {
    if (_state.phase != QuestionImposterPhase.reveal) return;
    _state = _state.copyWith(phase: QuestionImposterPhase.answering);
    notifyListeners();
  }

  void submitAnswer(String answer) {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) return;
    final updated = Map<int, String>.from(_state.answers)
      ..[_state.currentPlayerIndex] = trimmed;

    if (updated.length >= context.players.length) {
      _state = _state.copyWith(
        answers: updated,
        phase: QuestionImposterPhase.voting,
        currentPlayerIndex: 0,
      );
    } else {
      _state = _state.copyWith(
        answers: updated,
        currentPlayerIndex: _state.currentPlayerIndex + 1,
      );
    }
    notifyListeners();
  }

  void castVote(int voterIdx, int votedIdx) {
    if (voterIdx == votedIdx) return;
    if (_state.votes.containsKey(voterIdx)) return;
    final updated = Map<int, int>.from(_state.votes)..[voterIdx] = votedIdx;

    if (updated.length >= context.players.length) {
      _resolveVotes(updated);
    } else {
      _state = _state.copyWith(
        votes: updated,
        currentPlayerIndex: voterIdx + 1,
      );
      notifyListeners();
    }
  }

  void _resolveVotes(Map<int, int> votes) {
    final counts = <int, int>{};
    for (final v in votes.values) {
      counts.update(v, (c) => c + 1, ifAbsent: () => 1);
    }
    int? top;
    int max = 0;
    int topCount = 0;
    counts.forEach((idx, c) {
      if (c > max) {
        max = c;
        top = idx;
        topCount = 1;
      } else if (c == max) {
        topCount++;
      }
    });

    final caught = top != null && topCount == 1 && _state.imposters.contains(top);

    for (int i = 0; i < context.players.length; i++) {
      final isImp = _state.imposters.contains(i);
      context.addScore(
        context.players[i].id,
        caught ? (isImp ? 0 : 10) : (isImp ? 15 : 0),
      );
    }

    final imposterNames = _state.imposters
        .map((i) => context.players[i].name)
        .join(', ');
    final int? topIdx = top;
    final topName = topIdx == null ? 'nobody' : context.players[topIdx].name;

    _state = _state.copyWith(
      phase: QuestionImposterPhase.roundResult,
      votes: votes,
      imposterCaught: caught,
      resultMessage: caught
          ? 'Caught! $topName was one of the imposters.'
          : 'The imposters got away. It was $imposterNames.',
    );
    notifyListeners();
  }

  void nextRound() {
    if (_state.round >= _state.totalRounds) {
      _state = _state.copyWith(phase: QuestionImposterPhase.finished);
    } else {
      _state = _state.copyWith(round: _state.round + 1);
      _startRound();
    }
    notifyListeners();
  }

  @override
  void handleAction(String action, {Map<String, dynamic>? payload}) {
    switch (action) {
      case 'acknowledge':
        acknowledge();
      case 'answer':
        submitAnswer(payload?['answer'] as String? ?? '');
      case 'vote':
        castVote(
          payload?['voterIdx'] as int? ?? 0,
          payload?['votedIdx'] as int? ?? 0,
        );
      case 'next_round':
        nextRound();
      case 'finish':
        _state = _state.copyWith(phase: QuestionImposterPhase.finished);
        notifyListeners();
        context.onGameEnd();
    }
  }

  @override
  void tick() {
    if (_state.phase == QuestionImposterPhase.finished ||
        _state.phase == QuestionImposterPhase.roundResult) {
      return;
    }
    final next = _state.remainingTime - 1;
    if (next > 0) {
      _state = _state.copyWith(remainingTime: next);
      notifyListeners();
      return;
    }
    // Time is up: move to the next phase and give it a fresh clock.
    switch (_state.phase) {
      case QuestionImposterPhase.reveal:
        _state = _state.copyWith(
          phase: QuestionImposterPhase.answering,
          remainingTime: context.settings.roundTimeSeconds,
        );
      case QuestionImposterPhase.answering:
        submitAnswer('(no answer)');
        _state = _state.copyWith(
          remainingTime: context.settings.roundTimeSeconds,
        );
      case QuestionImposterPhase.voting:
        _resolveVotes(_state.votes);
      default:
        break;
    }
    notifyListeners();
  }
}

const _fallbackQuestions = [
  'What is your favorite food?',
  'What superpower would you choose?',
  'What is your dream travel destination?',
];
