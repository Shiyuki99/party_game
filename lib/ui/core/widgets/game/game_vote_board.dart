import 'package:flutter/material.dart';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/ui/core/widgets/game/game_player_card.dart';

class GameVoteBoard extends StatelessWidget {
  final List<Player> players;
  final int? selectedIndex;
  final Map<int, String>? subtitles; // playerIndex → subtitle text
  final void Function(int index) onVote;

  const GameVoteBoard({
    super.key,
    required this.players,
    required this.selectedIndex,
    this.subtitles,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (ctx, i) => GamePlayerCard(
        player: players[i],
        index: i,
        isSelected: selectedIndex == i,
        subtitle: subtitles?[i],
        trailing: selectedIndex == i
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        onTap: () => onVote(i),
      ),
    );
  }
}
