import 'dart:math';
import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';

enum ImposterPhase { revealRole, submitting, voting, result }

class ImposterState {
  final ImposterPhase phase;
  final PlayerOrder? order;
  final RoleAssignment? roles;
  final String? activeCategory;
  final String? activeWord;
  final int currentRevealIndex;
  final int currentSubmitterIndex;
  final int currentSubmitRound;
  final Map<int, List<String>> submissions;
  final Map<int, int> votes;
  final String? resultMessage;
  final int remainingTime;

  const ImposterState({
    this.phase = ImposterPhase.revealRole,
    this.order,
    this.roles,
    this.activeCategory,
    this.activeWord,
    this.currentRevealIndex = 0,
    this.currentSubmitterIndex = 0,
    this.currentSubmitRound = 0,
    this.submissions = const {},
    this.votes = const {},
    this.resultMessage,
    this.remainingTime = 0,
  });

  ImposterState copyWith({
    ImposterPhase? phase,
    PlayerOrder? order,
    RoleAssignment? roles,
    String? activeCategory,
    String? activeWord,
    int? currentRevealIndex,
    int? currentSubmitterIndex,
    int? currentSubmitRound,
    Map<int, List<String>>? submissions,
    Map<int, int>? votes,
    String? resultMessage,
    int? remainingTime,
  }) =>
      ImposterState(
        phase: phase ?? this.phase,
        order: order ?? this.order,
        roles: roles ?? this.roles,
        activeCategory: activeCategory ?? this.activeCategory,
        activeWord: activeWord ?? this.activeWord,
        currentRevealIndex: currentRevealIndex ?? this.currentRevealIndex,
        currentSubmitterIndex:
            currentSubmitterIndex ?? this.currentSubmitterIndex,
        currentSubmitRound: currentSubmitRound ?? this.currentSubmitRound,
        submissions: submissions ?? this.submissions,
        votes: votes ?? this.votes,
        resultMessage: resultMessage ?? this.resultMessage,
        remainingTime: remainingTime ?? this.remainingTime,
      );
}

class ImposterLogic extends GameLogic {
  @override
  final GameContext context;
  @override
  bool get isFinished => _state.phase == ImposterPhase.result;

  ImposterState _state = const ImposterState();
  ImposterState get gameState => _state;

  final _rng = Random();

  ImposterLogic(this.context);

  @override
  void init() {
    final ids = context.players.map((p) => p.id).toList();
    final order = PlayerOrder.random(ids);
    final roles = RoleAssignment.random(
      playerIds: ids,
      imposters: context.settings.numberOfImposters.clamp(1, ids.length - 1),
    );

    final cats = _loadCategories();
    final cat = cats[_rng.nextInt(cats.length)];
    final word = _pickWordForCategory(cat);

    _state = ImposterState(
      phase: ImposterPhase.revealRole,
      order: order,
      roles: roles,
      activeCategory: cat,
      activeWord: word,
      currentRevealIndex: 0,
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
      _state = _state.copyWith(
        phase: ImposterPhase.submitting,
        currentSubmitterIndex: 0,
        currentSubmitRound: 0,
      );
    }
    notifyListeners();
  }

  void submitKeyword(String keyword) {
    final idx = _state.currentSubmitterIndex;
    final existing = List<String>.from(_state.submissions[idx] ?? []);
    existing.add(keyword);
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
    final updated = Map<int, int>.from(_state.votes);
    updated[voterIdx] = votedIdx;

    if (updated.length >= context.players.length) {
      _resolveVotes(updated);
    } else {
      _state = _state.copyWith(votes: updated);
    }
    notifyListeners();
  }

  void _resolveVotes(Map<int, int> votes) {
    final counts = <int, int>{};
    for (final v in votes.values) {
      counts.update(v, (c) => c + 1, ifAbsent: () => 1);
    }
    int? top;
    int max = 0;
    counts.forEach((idx, c) {
      if (c > max) {
        max = c;
        top = idx;
      }
    });

    final topId = context.players[top!].id;
    final isImposter = _state.roles!.hasRole(topId, 'imposter');

    for (int i = 0; i < context.players.length; i++) {
      final pid = context.players[i].id;
      final isImp = _state.roles!.hasRole(pid, 'imposter');
      if (isImposter) {
        context.addScore(pid, isImp ? 0 : 10);
      } else {
        context.addScore(pid, isImp ? 15 : 0);
      }
    }

    final imposterNames = _state
        .roles!.playersWithRole('imposter')
        .map((id) => context.players.firstWhere((p) => p.id == id).name)
        .join(', ');

    _state = _state.copyWith(
      phase: ImposterPhase.result,
      resultMessage: isImposter
          ? 'Imposter caught! It was ${context.players[top!].name}'
          : 'Imposter $imposterNames escaped!',
    );
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
            payload?['votedIdx'] as int? ?? 0);
    }
  }

  @override
  void tick() {
    if (_state.remainingTime > 0) {
      _state = _state.copyWith(remainingTime: _state.remainingTime - 1);
      notifyListeners();
    }
  }
}
