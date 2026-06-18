import 'package:flutter/material.dart';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/ui/core/widgets/player_avatar.dart';

class PlayerList extends StatelessWidget {
  final List<Player> players;
  final bool showScores;
  final bool compact;

  const PlayerList({
    super.key,
    required this.players,
    this.showScores = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: players.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        return PlayerAvatar(
          name: p.name,
          index: i,
          isHost: p.isHost,
          size: compact ? 36 : 48,
        );
      }).toList(),
    );
  }
}
