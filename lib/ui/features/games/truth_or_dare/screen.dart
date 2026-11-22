import 'package:flutter/material.dart';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/game/game_phase_header.dart';
import 'package:party_game/ui/core/widgets/game/game_player_card.dart';
import 'package:party_game/ui/core/widgets/game/game_result_display.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/truth_or_dare/logic.dart';
import 'package:party_game/ui/features/games/truth_or_dare/models.dart';

class TruthOrDareScreen extends StatelessWidget {
  final TruthOrDareLogic logic;
  final GameContext context;

  const TruthOrDareScreen({
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
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          child: switch (state.phase) {
            TruthDarePhase.choose => _ChoosePhase(
                key: const ValueKey('choose'),
                logic: logic,
                state: state,
                players: this.context.players,
              ),
            TruthDarePhase.prompt => _PromptPhase(
                key: const ValueKey('prompt'),
                logic: logic,
                state: state,
                players: this.context.players,
              ),
            _ => _FinishedPhase(key: const ValueKey('finished'), logic: logic),
          },
        );
      },
    );
  }
}

class _ChoosePhase extends StatelessWidget {
  final TruthOrDareLogic logic;
  final TruthDareState state;
  final List<Player> players;

  const _ChoosePhase({
    super.key,
    required this.logic,
    required this.state,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    final answerer = players.firstWhere((p) => p.id == state.answererId);
    final asker = players.firstWhere((p) => p.id == state.askerId);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GamePhaseHeader(
            title: 'Truth or Dare',
            subtitle: '${asker.name} asks · ${answerer.name} answers',
            round: state.round,
            totalRounds: state.totalRounds,
          ),
          const Spacer(),
          GamePlayerCard(
            player: answerer,
            index: players.indexOf(answerer),
            avatarSize: 88,
            subtitle: 'Your choice',
          ),
          const SizedBox(height: 32),
          Text('Pick one!', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Truth',
                  icon: Icons.chat_bubble_outline,
                  color: AppColors.accent,
                  onPressed: () => logic.choose(AnswerType.truth),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  label: 'Dare',
                  icon: Icons.bolt,
                  color: AppColors.secondary,
                  onPressed: () => logic.choose(AnswerType.dare),
                ),
              ),
            ],
          ),
          if (TruthOrDareSettings.fromExtra(logic.context.settings.extra)
              .allowCustomContent) ...[
            const SizedBox(height: 16),
            _CustomInput(logic: logic),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _CustomInput extends StatefulWidget {
  final TruthOrDareLogic logic;
  const _CustomInput({required this.logic});

  @override
  State<_CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<_CustomInput> {
  final _controller = TextEditingController();
  AnswerType _type = AnswerType.truth;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Add your own:'),
                const SizedBox(width: 8),
                SegmentedButton<AnswerType>(
                  segments: const [
                    ButtonSegment(value: AnswerType.truth, label: Text('Truth')),
                    ButtonSegment(value: AnswerType.dare, label: Text('Dare')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) => setState(() => _type = v.first),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Write a prompt...'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Add prompt',
                  onPressed: () {
                    widget.logic.addCustom(_type, _controller.text);
                    _controller.clear();
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptPhase extends StatelessWidget {
  final TruthOrDareLogic logic;
  final TruthDareState state;
  final List<Player> players;

  const _PromptPhase({
    super.key,
    required this.logic,
    required this.state,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    final answerer = players.firstWhere((p) => p.id == state.answererId);
    final isTruth = state.choice == AnswerType.truth;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GamePhaseHeader(
            title: isTruth ? 'Truth' : 'Dare',
            subtitle: '${answerer.name}, it is your turn',
            round: state.round,
            totalRounds: state.totalRounds,
          ),
          const Spacer(),
          Card(
            color: isTruth
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.secondary.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                state.prompt ?? '',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Spacer(),
          AppButton(
            label: 'Done — Next Round',
            icon: Icons.check,
            onPressed: () => logic.handleAction('complete'),
          ),
        ],
      ),
    );
  }
}

class _FinishedPhase extends StatelessWidget {
  final TruthOrDareLogic logic;

  const _FinishedPhase({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    final state = logic.gameState;
    return GameResultDisplay(
      message: '${state.totalRounds} rounds completed!',
      success: true,
      details: {
        'Prompts completed': '${state.earnedPoints}',
        'Bravery points': '+${state.earnedPoints}',
      },
      buttonLabel: 'See Final Scores',
      onButton: () => logic.handleAction('finish'),
    );
  }
}
