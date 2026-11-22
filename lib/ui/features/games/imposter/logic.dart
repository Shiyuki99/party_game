import 'dart:math';

import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';

enum ImposterPhase { revealRole, submitting, voting, roundResult, finished }

class ImposterState {
  final ImposterPhase phase;
  final RoleAssignment? roles;
  final String? activeCategory;
  final String? activeWord;
  final int round;
  final int totalRounds;
  final int currentRevealIndex;
  final int currentSubmitterIndex;
  final int currentSubmitRound;
  final Map<int, List<String>> submissions;
  final Map<int, int> votes;
  final String? resultMessage;
  final bool imposterCaught;
  final int remainingTime;

  const ImposterState({
    this.phase = ImposterPhase.revealRole,
    this.roles,
    this.activeCategory,
    this.activeWord,
    this.round = 1,
    this.totalRounds = 1,
    this.currentRevealIndex = 0,
    this.currentSubmitterIndex = 0,
    this.currentSubmitRound = 0,
    this.submissions = const {},
    this.votes = const {},
    this.resultMessage,
    this.imposterCaught = false,
    this.remainingTime = 0,
  });

  ImposterState copyWith({
    ImposterPhase? phase,
    RoleAssignment? roles,
    String? activeCategory,
    String? activeWord,
    int? round,
    int? totalRounds,
    int? currentRevealIndex,
    int? currentSubmitterIndex,
    int? currentSubmitRound,
    Map<int, List<String>>? submissions,
    Map<int, int>? votes,
    String? resultMessage,
    bool? imposterCaught,
    int? remainingTime,
  }) =>
      ImposterState(
        phase: phase ?? this.phase,
        roles: roles ?? this.roles,
        activeCategory: activeCategory ?? this.activeCategory,
        activeWord: activeWord ?? this.activeWord,
        round: round ?? this.round,
        totalRounds: totalRounds ?? this.totalRounds,
        currentRevealIndex: currentRevealIndex ?? this.currentRevealIndex,
        currentSubmitterIndex:
            currentSubmitterIndex ?? this.currentSubmitterIndex,
        currentSubmitRound: currentSubmitRound ?? this.currentSubmitRound,
        submissions: submissions ?? this.submissions,
        votes: votes ?? this.votes,
        resultMessage: resultMessage ?? this.resultMessage,
        imposterCaught: imposterCaught ?? this.imposterCaught,
        remainingTime: remainingTime ?? this.remainingTime,
      );
}

class ImposterLogic extends GameLogic {
  @override
  final GameContext context;
  @override
  bool get isFinished => _state.phase == ImposterPhase.finished;

  ImposterState _state = const ImposterState();
  ImposterState get gameState => _state;

  final Random _rng = Random();

  ImposterLogic(this.context);

  @override
  void init() {
    if (context.players.length < 2) {
      _state = _state.copyWith(phase: ImposterPhase.finished);
      notifyListeners();
      return;
    }
    _state = ImposterState(
      totalRounds: context.settings.numberOfRounds.clamp(1, 20),
      remainingTime: context.settings.roundTimeSeconds,
    );
    _startRound();
  }

  void _startRound() {
    final ids = context.players.map((p) => p.id).toList();
    final imposters = context.settings.numberOfImposters.clamp(
      1,
      ids.length - 1,
    );
    final roles = RoleAssignment.random(playerIds: ids, imposters: imposters);

    final categories = _loadCategories();
    final cat =
        categories.isNotEmpty ? categories[_rng.nextInt(categories.length)] : '';
    final word = cat.isNotEmpty ? _pickWordForCategory(cat) : '';

    _state = _state.copyWith(
      phase: ImposterPhase.revealRole,
      roles: roles,
      activeCategory: cat,
      activeWord: word,
      currentRevealIndex: 0,
      currentSubmitterIndex: 0,
      currentSubmitRound: 0,
      submissions: const {},
      votes: const {},
      resultMessage: null,
      imposterCaught: false,
      remainingTime: context.settings.roundTimeSeconds,
    );
    notifyListeners();
  }

  List<String> _loadCategories() {
    final categories = context.content['categories'] as Map<String, dynamic>?;
    if (categories == null || categories.isEmpty) return [];
    return categories.keys.toList();
  }

  String _pickWordForCategory(String cat) {
    final categories = context.content['categories'] as Map<String, dynamic>?;
    final words = categories?[cat] as List<dynamic>?;
    if (words != null && words.isNotEmpty) {
      return words[_rng.nextInt(words.length)] as String;
    }
    return '';
  }

  void revealNext() {
    if (_state.currentRevealIndex < context.players.length - 1) {
      _state = _state.copyWith(
        currentRevealIndex: _state.currentRevealIndex + 1,
      );
    } else {
      _state = _state.copyWith(phase: ImposterPhase.submitting);
    }
    notifyListeners();
  }

  void submitKeyword(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    final idx = _state.currentSubmitterIndex;
    final existing = List<String>.from(_state.submissions[idx] ?? []);
    existing.add(trimmed);
    final updated = Map<int, List<String>>.from(_state.submissions);
    updated[idx] = existing;

    final nextIdx = idx + 1;
    if (nextIdx >= context.players.length) {
      final nextRound = _state.currentSubmitRound + 1;
      if (nextRound >= context.settings.turnsPerPlayer) {
        _state = _state.copyWith(
          submissions: updated,
          phase: ImposterPhase.voting,
          currentSubmitterIndex: 0,
        );
      } else {
        _state = _state.copyWith(
          submissions: updated,
          currentSubmitterIndex: 0,
          currentSubmitRound: nextRound,
        );
      }
    } else {
      _state = _state.copyWith(
        submissions: updated,
        currentSubmitterIndex: nextIdx,
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
      _state = _state.copyWith(votes: updated);
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

    // A tie means the imposter slips away.
    final caught = top != null &&
        topCount == 1 &&
        _state.roles!.hasRole(context.players[top!].id, 'imposter');

    for (int i = 0; i < context.players.length; i++) {
      final isImp = _state.roles!
          .hasRole(context.players[i].id, 'imposter');
      context.addScore(
        context.players[i].id,
        caught ? (isImp ? 0 : 10) : (isImp ? 15 : 0),
      );
    }

    final imposterNames = _state
        .roles!.playersWithRole('imposter')
        .map((id) => context.players.firstWhere((p) => p.id == id).name)
        .join(', ');

    final message = caught
        ? 'Imposter caught! It was ${context.players[top!].name}.'
        : 'The imposter escaped. It was $imposterNames.';

    _state = _state.copyWith(
      phase: ImposterPhase.roundResult,
      votes: votes,
      resultMessage: message,
      imposterCaught: caught,
    );
    notifyListeners();
  }

  void nextRound() {
    if (_state.round >= _state.totalRounds) {
      _state = _state.copyWith(phase: ImposterPhase.finished);
    } else {
      _state = _state.copyWith(round: _state.round + 1);
      _startRound();
    }
    notifyListeners();
  }

  @override
  void handleAction(String action, {Map<String, dynamic>? payload}) {
    switch (action) {
      case 'reveal_next':
        revealNext();
      case 'submit_keyword':
        submitKeyword(payload?['keyword'] as String? ?? '');
      case 'vote':
        castVote(
          payload?['voterIdx'] as int? ?? 0,
          payload?['votedIdx'] as int? ?? 0,
        );
      case 'next_round':
        nextRound();
      case 'finish':
        _state = _state.copyWith(phase: ImposterPhase.finished);
        notifyListeners();
        context.onGameEnd();
    }
  }

  @override
  void tick() {
    if (_state.phase == ImposterPhase.finished ||
        _state.phase == ImposterPhase.roundResult) {
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
      case ImposterPhase.revealRole:
        _state = _state.copyWith(
          phase: ImposterPhase.submitting,
          remainingTime: context.settings.roundTimeSeconds,
        );
      case ImposterPhase.submitting:
        _state = _state.copyWith(
          phase: ImposterPhase.voting,
          remainingTime: context.settings.roundTimeSeconds,
        );
      case ImposterPhase.voting:
        _resolveVotes(_state.votes);
      default:
        break;
    }
    notifyListeners();
  }
}
