import 'package:flutter/material.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/game/game_phase_header.dart';
import 'package:party_game/ui/core/widgets/game/game_player_card.dart';
import 'package:party_game/ui/core/widgets/game/game_result_display.dart';
import 'package:party_game/ui/core/widgets/game/game_text_field.dart';
import 'package:party_game/ui/core/widgets/game/game_vote_board.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/imposter/logic.dart';

class ImposterScreen extends StatelessWidget {
  final ImposterLogic logic;
  final GameContext context;

  const ImposterScreen({super.key, required this.logic, required this.context});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logic,
      builder: (ctx, _) {
        final state = logic.gameState;
        final timed = this.context.settings.mode == GameMode.timeBased;
        final child = switch (state.phase) {
          ImposterPhase.revealRole => _RevealPhase(
              logic: logic,
              state: state,
              remainingTime: timed ? state.remainingTime : null,
            ),
          ImposterPhase.submitting => _SubmitPhase(
              logic: logic,
              state: state,
              remainingTime: timed ? state.remainingTime : null,
            ),
          ImposterPhase.voting => _VotePhase(
              logic: logic,
              state: state,
              remainingTime: timed ? state.remainingTime : null,
            ),
          ImposterPhase.roundResult =>
            _RoundResultPhase(logic: logic, state: state),
          ImposterPhase.finished => _FinishedPhase(logic: logic),
        };
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          child: child,
        );
      },
    );
  }
}

class _RevealPhase extends StatefulWidget {
  final ImposterLogic logic;
  final ImposterState state;
  final int? remainingTime;

  const _RevealPhase({
    required this.logic,
    required this.state,
    required this.remainingTime,
  });

  @override
  State<_RevealPhase> createState() => _RevealPhaseState();
}

class _RevealPhaseState extends State<_RevealPhase> {
  bool _revealed = false;

  @override
  void didUpdateWidget(covariant _RevealPhase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentRevealIndex !=
        widget.state.currentRevealIndex) {
      setState(() => _revealed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final players = widget.logic.context.players;
    final player = players[state.currentRevealIndex];
    final isImposter = state.roles?.hasRole(player.id, 'imposter') ?? false;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GamePhaseHeader(
            title: 'Secret Roles',
            subtitle: 'Player ${state.currentRevealIndex + 1}/${players.length}',
            round: state.round,
            totalRounds: state.totalRounds,
            remainingTime: widget.remainingTime,
          ),
          const Spacer(),
          GamePlayerCard(
            player: player,
            index: state.currentRevealIndex,
            avatarSize: 88,
            subtitle: 'Pass the device to ${player.name}',
          ),
          const SizedBox(height: 24),
          if (!_revealed)
            AppButton(
              label: 'I\'m Ready — Reveal',
              icon: Icons.visibility,
              onPressed: () => setState(() => _revealed = true),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isImposter
                    ? AppColors.error.withValues(alpha: 0.15)
                    : AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    isImposter ? Icons.theater_comedy : Icons.groups_outlined,
                    size: 40,
                    color: isImposter ? AppColors.error : AppColors.accent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isImposter ? 'YOU ARE THE IMPOSTER' : 'YOU ARE A CITIZEN',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: isImposter ? AppColors.error : AppColors.accent,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (isImposter)
                    Text(
                      'Blend in! Category: ${state.activeCategory}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    )
                  else ...[
                    Text('Category: ${state.activeCategory}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(state.activeWord ?? '',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppColors.accent,
                            ),
                        textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          const Spacer(),
          if (_revealed)
            AppButton(
              label: state.currentRevealIndex < players.length - 1
                  ? 'Next Player'
                  : 'Start Giving Clues',
              icon: Icons.arrow_forward,
              onPressed: () => widget.logic.handleAction('reveal_next'),
            ),
        ],
      ),
    );
  }
}

class _SubmitPhase extends StatefulWidget {
  final ImposterLogic logic;
  final ImposterState state;
  final int? remainingTime;

  const _SubmitPhase({
    required this.logic,
    required this.state,
    required this.remainingTime,
  });

  @override
  State<_SubmitPhase> createState() => _SubmitPhaseState();
}

class _SubmitPhaseState extends State<_SubmitPhase> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.logic.handleAction('submit_keyword', payload: {'keyword': text});
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final players = widget.logic.context.players;
    final player = players[state.currentSubmitterIndex];
    final total =
        players.length * widget.logic.context.settings.turnsPerPlayer;
    final submitted = state.submissions.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GamePhaseHeader(
            title: 'Give a Clue',
            subtitle: '${player.name} · round ${state.currentSubmitRound + 1}',
            round: state.round,
            totalRounds: state.totalRounds,
            remainingTime: widget.remainingTime,
          ),
          const SizedBox(height: 16),
          Text('Category: ${state.activeCategory ?? ''}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Say one word that fits — not too obvious!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          const Spacer(),
          GameTextField(
            controller: _controller,
            hintText: 'Your keyword...',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Submit Keyword',
            icon: Icons.send,
            onPressed: _submit,
          ),
          const Spacer(),
          Text('$submitted of $total clues given',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _VotePhase extends StatelessWidget {
  final ImposterLogic logic;
  final ImposterState state;
  final int? remainingTime;

  const _VotePhase({
    required this.logic,
    required this.state,
    required this.remainingTime,
  });

  @override
  Widget build(BuildContext context) {
    final players = logic.context.players;
    final voterIdx = state.votes.length;
    final voter = voterIdx < players.length ? players[voterIdx] : null;
    final subtitles = <int, String>{};
    for (final e in state.votes.entries) {
      subtitles[e.value] = '${subtitles[e.value] ?? ''} ✓'.trim();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GamePhaseHeader(
            title: 'Vote',
            subtitle: voter != null
                ? '${voter.name}, pick the imposter'
                : 'All votes are in',
            round: state.round,
            totalRounds: state.totalRounds,
            remainingTime: remainingTime,
          ),
          const SizedBox(height: 16),
          Text('Category: ${state.activeCategory}',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Expanded(
            child: GameVoteBoard(
              players: players,
              selectedIndex: null,
              subtitles: subtitles,
              onVote: (i) {
                if (voter != null && i != voterIdx) {
                  logic.handleAction('vote', payload: {
                    'voterIdx': voterIdx,
                    'votedIdx': i,
                  });
                } else if (i == voterIdx) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You cannot vote for yourself.')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundResultPhase extends StatelessWidget {
  final ImposterLogic logic;
  final ImposterState state;

  const _RoundResultPhase({
    required this.logic,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = state.round >= state.totalRounds;
    return GameResultDisplay(
      message: state.resultMessage ?? 'Round over',
      success: state.imposterCaught,
      details: {
        'Word': state.activeWord ?? '',
        'Category': state.activeCategory ?? '',
      },
      buttonLabel: isLast ? 'See Final Scores' : 'Next Round',
      onButton: () => logic.handleAction('next_round'),
    );
  }
}

class _FinishedPhase extends StatelessWidget {
  final ImposterLogic logic;

  const _FinishedPhase({required this.logic});

  @override
  Widget build(BuildContext context) {
    return GameResultDisplay(
      message: '${logic.gameState.totalRounds} rounds played!',
      success: true,
      buttonLabel: 'See Final Scores',
      onButton: () => logic.handleAction('finish'),
    );
  }
}
