import 'package:flutter/material.dart';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/player_avatar.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/imposter/game.dart';

class ImposterUI extends StatefulWidget {
  final ImposterLogic logic;
  final GameContext context;

  const ImposterUI({super.key, required this.logic, required this.context});

  @override
  State<ImposterUI> createState() => _ImposterUIState();
}

class _ImposterUIState extends State<ImposterUI> {
  final _keywordCtrl = TextEditingController();
  int? _selectedVote;

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.logic.gameState;
    final players = widget.context.players;
    final isImposter = s.roles?.hasRole(
          players[s.currentRevealIndex].id,
          'imposter',
        ) ??
        false;

    switch (s.phase) {
      case ImposterPhase.revealRole:
        return _RevealRole(
          player: players[s.currentRevealIndex],
          idx: s.currentRevealIndex,
          isImposter: isImposter,
          category: s.activeCategory ?? '',
          word: s.activeWord ?? '',
          onDone: () => widget.logic.handleAction('reveal_next'),
        );
      case ImposterPhase.submitting:
        return _SubmitKeyword(
          player: players[s.currentSubmitterIndex],
          idx: s.currentSubmitterIndex,
          keywordCtrl: _keywordCtrl,
          round: s.currentSubmitRound + 1,
          maxRounds: widget.context.settings.turnsPerPlayer,
          onSubmit: () {
            final kw = _keywordCtrl.text.trim();
            if (kw.isNotEmpty) {
              widget.logic.handleAction('submit_keyword', payload: {'keyword': kw});
              _keywordCtrl.clear();
              setState(() {});
            }
          },
        );
      case ImposterPhase.voting:
        return _VoteScreen(
          players: players,
          selectedIdx: _selectedVote,
          submissions: s.submissions,
          onVote: (idx) {
            setState(() => _selectedVote = idx);
          },
          onSubmit: () {
            if (_selectedVote != null) {
              widget.logic.handleAction('vote', payload: {
                'voterIdx': s.currentSubmitterIndex,
                'votedIdx': _selectedVote,
              });
              setState(() => _selectedVote = null);
            }
          },
        );
      case ImposterPhase.result:
        return _Result(
          message: s.resultMessage ?? '',
          word: s.activeWord ?? '',
          category: s.activeCategory ?? '',
          imposterNames: s
              .roles!
              .playersWithRole('imposter')
              .map((id) => players.firstWhere((p) => p.id == id).name)
              .join(', '),
          onEnd: widget.context.onGameEnd,
        );
      default:
        return const SizedBox();
    }
  }
}

class _RevealRole extends StatelessWidget {
  final Player player;
  final int idx;
  final bool isImposter;
  final String category;
  final String word;
  final VoidCallback onDone;

  const _RevealRole({
    required this.player,
    required this.idx,
    required this.isImposter,
    required this.category,
    required this.word,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          Text('Player ${idx + 1}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          PlayerAvatar(name: player.name, index: idx, size: 80),
          const SizedBox(height: 32),
          if (isImposter) ...[
            const Text('YOU ARE THE IMPOSTER!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error)),
            const SizedBox(height: 16),
            Text('Category: $category',
                style: Theme.of(context).textTheme.titleMedium),
          ] else ...[
            const Text('Your word:',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text(word,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent)),
          ],
          const SizedBox(height: 24),
          Text('Hide & pass to next player',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          AppButton(label: 'Hide & Pass', onPressed: onDone),
          const Spacer(),
        ],
      ),
    );
  }
}

class _SubmitKeyword extends StatelessWidget {
  final Player player;
  final int idx;
  final TextEditingController keywordCtrl;
  final int round;
  final int maxRounds;
  final VoidCallback onSubmit;

  const _SubmitKeyword({
    required this.player,
    required this.idx,
    required this.keywordCtrl,
    required this.round,
    required this.maxRounds,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          PlayerAvatar(name: player.name, index: idx, size: 64),
          const SizedBox(height: 16),
          Text('Your turn', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Keyword $round of $maxRounds',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          TextField(
            controller: keywordCtrl,
            decoration: const InputDecoration(
              hintText: 'Say one related word...',
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Submit', onPressed: onSubmit),
          const Spacer(),
        ],
      ),
    );
  }
}

class _VoteScreen extends StatelessWidget {
  final List<Player> players;
  final int? selectedIdx;
  final Map<int, List<String>> submissions;
  final void Function(int) onVote;
  final VoidCallback onSubmit;

  const _VoteScreen({
    required this.players,
    required this.selectedIdx,
    required this.submissions,
    required this.onVote,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('Who is the imposter?',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Vote for the most suspicious player',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (ctx, i) {
                final kw = submissions[i] ?? [];
                return Card(
                  color: selectedIdx == i ? AppColors.primary : null,
                  child: ListTile(
                    leading: PlayerAvatar(name: players[i].name, index: i),
                    title: Text(players[i].name),
                    subtitle: kw.isNotEmpty
                        ? Text(kw.join(', '),
                            style: const TextStyle(
                                color: AppColors.textSecondary))
                        : null,
                    trailing: selectedIdx == i
                        ? const Icon(Icons.check_circle,
                            color: AppColors.accent)
                        : null,
                    onTap: () => onVote(i),
                  ),
                );
              },
            ),
          ),
          AppButton(
            label: 'Vote',
            onPressed: selectedIdx != null ? onSubmit : null,
          ),
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  final String message;
  final String word;
  final String category;
  final String imposterNames;
  final VoidCallback onEnd;

  const _Result({
    required this.message,
    required this.word,
    required this.category,
    required this.imposterNames,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final caught = message.contains('caught');
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          Text(message,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: caught ? AppColors.success : AppColors.error,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Word: $word', style: Theme.of(context).textTheme.titleLarge),
          Text('Category: $category',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text('Imposter(s): $imposterNames',
              style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          AppButton(label: 'End Game', onPressed: onEnd),
        ],
      ),
    );
  }
}
