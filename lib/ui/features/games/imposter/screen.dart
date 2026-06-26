import 'package:flutter/material.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/game/game_phase_header.dart';
import 'package:party_game/ui/core/widgets/game/game_player_card.dart';
import 'package:party_game/ui/core/widgets/game/game_result_display.dart';
import 'package:party_game/ui/core/widgets/game/game_text_field.dart';
import 'package:party_game/ui/core/widgets/game/game_vote_board.dart';
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
        switch (state.phase) {
          case ImposterPhase.revealRole:
            return _RevealPhase(logic: logic, state: state, ctx: ctx);
          case ImposterPhase.submitting:
            return _SubmitPhase(logic: logic, state: state, ctx: ctx);
          case ImposterPhase.voting:
            return _VotePhase(logic: logic, state: state, ctx: ctx);
          case ImposterPhase.result:
            return _ResultPhase(logic: logic, state: state, ctx: ctx);
        }
      },
    );
  }
}

class _RevealPhase extends StatelessWidget {
  final ImposterLogic logic;
  final ImposterState state;
  final BuildContext ctx;

  const _RevealPhase({
    required this.logic,
    required this.state,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    final player = logic.context.players[state.currentRevealIndex];
    final isImposter =
        state.roles?.hasRole(player.id, 'imposter') ?? false;
    final category = state.activeCategory ?? '';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GamePhaseHeader(
            title: 'Role Reveal',
            subtitle:
                'Player ${state.currentRevealIndex + 1}/${logic.context.players.length}',
            remainingTime: state.remainingTime,
          ),
          const Spacer(),
          GamePlayerCard(
            player: player,
            index: state.currentRevealIndex,
            avatarSize: 80,
          ),
          const SizedBox(height: 24),
          if (currentIsViewing(state.currentRevealIndex)) ...[
            Text(
              isImposter ? 'YOU ARE THE IMPOSTER!' : 'Category: $category',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isImposter ? Colors.red : Colors.green,
              ),
            ),
            if (!isImposter && state.activeWord != null) ...[
              const SizedBox(height: 8),
              Text('Word: ${state.activeWord}',
                  style: const TextStyle(fontSize: 18)),
            ],
            if (isImposter) ...[
              const SizedBox(height: 16),
              Text(
                  'Try to blend in with the other players.\nCategory: $category',
                  textAlign: TextAlign.center),
            ],
          ] else ...[
            const Text('Pass the device to this player.',
                style: TextStyle(fontSize: 16)),
          ],
          const Spacer(),
          AppButton(
            label: state.currentRevealIndex < logic.context.players.length - 1
                ? 'Next Player'
                : 'Start Game',
            onPressed: () => logic.handleAction('reveal_next'),
          ),
        ],
      ),
    );
  }

  bool currentIsViewing(int idx) => true;
}

class _SubmitPhase extends StatelessWidget {
  final ImposterLogic logic;
  final ImposterState state;
  final BuildContext ctx;

  const _SubmitPhase({
    required this.logic,
    required this.state,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    final player = logic.context.players[state.currentSubmitterIndex];
    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GamePhaseHeader(
            title: 'Keywords',
            subtitle:
                'Round ${state.currentSubmitRound + 1}/${logic.context.settings.turnsPerPlayer} - ${player.name}',
            remainingTime: state.remainingTime,
          ),
          const SizedBox(height: 16),
          Text('Category: ${state.activeCategory ?? ""}'),
          const SizedBox(height: 24),
          GameTextField(
            controller: controller,
            hintText: 'Enter a keyword...',
            textInputAction: TextInputAction.done,
            onSubmitted: (v) {
              if (v.isNotEmpty) {
                logic.handleAction('submit_keyword', payload: {'keyword': v});
                controller.clear();
              }
            },
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Submit Keyword',
            onPressed: () {
              if (controller.text.isNotEmpty) {
                logic.handleAction('submit_keyword',
                    payload: {'keyword': controller.text});
                controller.clear();
              }
            },
          ),
          const Spacer(),
          if (state.submissions.isNotEmpty) ...[
            Text('Submitted so far:',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...state.submissions.entries.expand((e) => e.value).map(
                  (k) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('- $k'),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _VotePhase extends StatelessWidget {
  final ImposterLogic logic;
  final ImposterState state;
  final BuildContext ctx;

  const _VotePhase({
    required this.logic,
    required this.state,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    final voterIdx = state.votes.length;
    final voter = voterIdx < logic.context.players.length
        ? logic.context.players[voterIdx]
        : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GamePhaseHeader(
            title: 'Vote',
            subtitle: voter != null ? '${voter.name} votes' : 'All votes cast',
            remainingTime: state.remainingTime,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GameVoteBoard(
              players: logic.context.players,
              selectedIndex: null,
              subtitles: _buildSubtitleMap(),
              onVote: (i) {
                logic.handleAction('vote',
                    payload: {'voterIdx': voterIdx, 'votedIdx': i});
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<int, String> _buildSubtitleMap() {
    final subs = <int, String>{};
    for (final e in state.votes.entries) {
      subs[e.key] = '→ ${logic.context.players[e.value].name}';
    }
    return subs;
  }
}

class _ResultPhase extends StatelessWidget {
  final ImposterLogic logic;
  final ImposterState state;
  final BuildContext ctx;

  const _ResultPhase({
    required this.logic,
    required this.state,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    return GameResultDisplay(
      message: state.resultMessage ?? 'Game Over',
      success: state.resultMessage?.contains('caught') ?? false,
      buttonLabel: 'End Game',
      onButton: () => logic.context.onGameEnd(),
    );
  }
}
