import 'package:flutter/material.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/game/game_phase_header.dart';
import 'package:party_game/ui/core/widgets/game/game_player_card.dart';
import 'package:party_game/ui/core/widgets/game/game_result_display.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/charades/logic.dart';

class CharadesScreen extends StatelessWidget {
  final CharadesLogic logic;
  final GameContext context;

  const CharadesScreen({
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
          CharadesPhase.showWord => _ShowWordPhase(
              logic: logic,
              state: state,
              remainingTime: timed ? state.remainingTime : null,
            ),
          CharadesPhase.acting => _ActingPhase(
              logic: logic,
              state: state,
              remainingTime: timed ? state.remainingTime : null,
            ),
          CharadesPhase.roundResult =>
            _RoundResultPhase(logic: logic, state: state),
          CharadesPhase.finished => _FinishedPhase(logic: logic),
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

class _ShowWordPhase extends StatefulWidget {
  final CharadesLogic logic;
  final CharadesState state;
  final int? remainingTime;

  const _ShowWordPhase({
    required this.logic,
    required this.state,
    required this.remainingTime,
  });

  @override
  State<_ShowWordPhase> createState() => _ShowWordPhaseState();
}

class _ShowWordPhaseState extends State<_ShowWordPhase> {
  bool _revealed = false;

  @override
  void didUpdateWidget(covariant _ShowWordPhase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.round != widget.state.round ||
        oldWidget.state.word != widget.state.word) {
      setState(() => _revealed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final players = widget.logic.context.players;
    final actor = players[state.actorIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GamePhaseHeader(
            title: 'Charades',
            subtitle: '${actor.name} is up',
            round: state.round,
            totalRounds: state.totalRounds,
            remainingTime: widget.remainingTime,
          ),
          const Spacer(),
          GamePlayerCard(
            player: actor,
            index: state.actorIndex,
            avatarSize: 88,
            subtitle: 'Pass the device to ${actor.name}',
          ),
          const SizedBox(height: 24),
          if (!_revealed)
            AppButton(
              label: 'I\'m Ready — Show Word',
              icon: Icons.visibility,
              onPressed: () => setState(() => _revealed = true),
            )
          else
            Card(
              color: AppColors.accent.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  state.word,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.accent,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          const Spacer(),
          if (_revealed)
            AppButton(
              label: 'Start Acting',
              icon: Icons.play_arrow,
              onPressed: () => widget.logic.handleAction('start_acting'),
            ),
        ],
      ),
    );
  }
}

class _ActingPhase extends StatelessWidget {
  final CharadesLogic logic;
  final CharadesState state;
  final int? remainingTime;

  const _ActingPhase({
    required this.logic,
    required this.state,
    required this.remainingTime,
  });

  @override
  Widget build(BuildContext context) {
    final players = logic.context.players;
    final actor = players[state.actorIndex];
    final teamMode = logic.isTeamMode;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GamePhaseHeader(
            title: '${actor.name} is acting!',
            subtitle: teamMode ? 'Teams · first correct guess scores' : 'First to guess wins',
            round: state.round,
            totalRounds: state.totalRounds,
            remainingTime: remainingTime,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, i) {
                final player = players[i];
                if (player.id == actor.id) return const SizedBox.shrink();
                return GamePlayerCard(
                  player: player,
                  index: i,
                  subtitle: teamMode
                      ? (i.isEven ? 'Team A' : 'Team B')
                      : 'Tap if you guessed it',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => logic.handleAction('guess', payload: {
                    'playerId': player.id,
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Skip Word',
            icon: Icons.skip_next,
            outlined: true,
            onPressed: () => logic.handleAction('skip'),
          ),
        ],
      ),
    );
  }
}

class _RoundResultPhase extends StatelessWidget {
  final CharadesLogic logic;
  final CharadesState state;

  const _RoundResultPhase({
    required this.logic,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final players = logic.context.players;
    final winner = state.winnerId == null
        ? null
        : players.firstWhere((p) => p.id == state.winnerId);

    return GameResultDisplay(
      message: state.timedOut
          ? 'Time is up!'
          : '${winner?.name ?? 'Nobody'} guessed it!',
      success: !state.timedOut,
      details: {
        'Word': state.word,
        if (state.pointsAwarded > 0) 'Points': '+${state.pointsAwarded}',
      },
      buttonLabel: state.round >= state.totalRounds
          ? 'See Final Scores'
          : 'Next Round',
      onButton: () => logic.handleAction('next_round'),
    );
  }
}

class _FinishedPhase extends StatelessWidget {
  final CharadesLogic logic;

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
