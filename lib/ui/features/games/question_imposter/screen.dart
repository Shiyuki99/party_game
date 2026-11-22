import 'package:flutter/material.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/game/game_phase_header.dart';
import 'package:party_game/ui/core/widgets/game/game_player_card.dart';
import 'package:party_game/ui/core/widgets/game/game_result_display.dart';
import 'package:party_game/ui/core/widgets/game/game_text_field.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/question_imposter/logic.dart';

class QuestionImposterScreen extends StatelessWidget {
  final QuestionImposterLogic logic;
  final GameContext context;

  const QuestionImposterScreen({
    super.key,
    required this.logic,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logic,
      builder: (ctx, _) {
        final state = logic.gameState;
        final timed = this.context.settings.mode == GameMode.timeBased;
        final child = switch (state.phase) {
          QuestionImposterPhase.reveal => _RevealPhase(
              logic: logic,
              state: state,
              remainingTime: timed ? state.remainingTime : null,
            ),
          QuestionImposterPhase.answering => _AnswerPhase(
              logic: logic,
              state: state,
              remainingTime: timed ? state.remainingTime : null,
            ),
          QuestionImposterPhase.voting => _VotePhase(
              logic: logic,
              state: state,
              remainingTime: timed ? state.remainingTime : null,
            ),
          QuestionImposterPhase.roundResult =>
            _RoundResultPhase(logic: logic, state: state),
          QuestionImposterPhase.finished => _FinishedPhase(logic: logic),
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
  final QuestionImposterLogic logic;
  final QuestionImposterState state;
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
    if (oldWidget.state.currentPlayerIndex !=
            widget.state.currentPlayerIndex ||
        oldWidget.state.round != widget.state.round) {
      setState(() => _revealed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final players = widget.logic.context.players;
    final player = players[state.currentPlayerIndex];
    final isImposter = state.imposters.contains(state.currentPlayerIndex);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GamePhaseHeader(
            title: 'Your Question',
            subtitle: 'Player ${state.currentPlayerIndex + 1}/${players.length}',
            round: state.round,
            totalRounds: state.totalRounds,
            remainingTime: widget.remainingTime,
          ),
          const Spacer(),
          GamePlayerCard(
            player: player,
            index: state.currentPlayerIndex,
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
              child: isImposter
                  ? Column(
                      children: [
                        const Icon(Icons.theater_comedy,
                            size: 40, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text('YOU ARE AN IMPOSTER',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: AppColors.error),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        const Text(
                          'Nobody will tell you the question. Listen to the '
                          'answers and fake one that fits in.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Icon(Icons.quiz_outlined,
                            size: 40, color: AppColors.accent),
                        const SizedBox(height: 12),
                        Text(state.question,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center),
                      ],
                    ),
            ),
          const Spacer(),
          if (_revealed)
            AppButton(
              label: 'Got It',
              icon: Icons.check,
              onPressed: () => widget.logic.handleAction('acknowledge'),
            ),
        ],
      ),
    );
  }
}

class _AnswerPhase extends StatefulWidget {
  final QuestionImposterLogic logic;
  final QuestionImposterState state;
  final int? remainingTime;

  const _AnswerPhase({
    required this.logic,
    required this.state,
    required this.remainingTime,
  });

  @override
  State<_AnswerPhase> createState() => _AnswerPhaseState();
}

class _AnswerPhaseState extends State<_AnswerPhase> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.logic.handleAction('answer', payload: {'answer': text});
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final player = widget.logic.context.players[state.currentPlayerIndex];
    final isImposter = state.imposters.contains(state.currentPlayerIndex);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GamePhaseHeader(
            title: 'Your Answer',
            subtitle: '${player.name} · answer ${state.answers.length + 1}/${widget.logic.context.players.length}',
            round: state.round,
            totalRounds: state.totalRounds,
            remainingTime: widget.remainingTime,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isImposter
                  ? AppColors.error.withValues(alpha: 0.12)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isImposter
                  ? 'Make up an answer — act natural!'
                  : state.question,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          GameTextField(
            controller: _controller,
            hintText: 'Type your answer...',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Submit Answer',
            icon: Icons.send,
            onPressed: _submit,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _VotePhase extends StatelessWidget {
  final QuestionImposterLogic logic;
  final QuestionImposterState state;
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
    int? selected;

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
          const SizedBox(height: 12),
          Text('The question was:',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(state.question,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Expanded(
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (ctx, i) => GamePlayerCard(
                        player: players[i],
                        index: i,
                        isSelected: selected == i,
                        subtitle: state.answers.containsKey(i)
                            ? '"${state.answers[i]}"'
                            : null,
                        trailing: selected == i
                            ? const Icon(Icons.check_circle,
                                color: AppColors.success)
                            : null,
                        onTap: () => setState(() => selected = i),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Cast Vote',
                    icon: Icons.how_to_vote,
                    onPressed: selected == null
                        ? null
                        : () {
                            if (selected == voterIdx) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('You cannot vote for yourself.')),
                              );
                              return;
                            }
                            logic.handleAction('vote', payload: {
                              'voterIdx': voterIdx,
                              'votedIdx': selected,
                            });
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundResultPhase extends StatelessWidget {
  final QuestionImposterLogic logic;
  final QuestionImposterState state;

  const _RoundResultPhase({
    required this.logic,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return GameResultDisplay(
      message: state.resultMessage ?? 'Round over',
      success: state.imposterCaught,
      details: {'Question': state.question},
      buttonLabel: state.round >= state.totalRounds
          ? 'See Final Scores'
          : 'Next Round',
      onButton: () => logic.handleAction('next_round'),
    );
  }
}

class _FinishedPhase extends StatelessWidget {
  final QuestionImposterLogic logic;

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
