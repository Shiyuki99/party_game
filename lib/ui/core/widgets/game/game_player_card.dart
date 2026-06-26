import 'package:flutter/material.dart';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';

class GamePlayerCard extends StatelessWidget {
  final Player player;
  final int index;
  final double avatarSize;
  final String? subtitle;
  final Widget? trailing;
  final bool isSelected;
  final VoidCallback? onTap;

  const GamePlayerCard({
    super.key,
    required this.player,
    required this.index,
    this.avatarSize = 48,
    this.subtitle,
    this.trailing,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.playerColors[index % AppColors.playerColors.length];
    return Card(
      color: isSelected ? AppColors.primary : null,
      child: ListTile(
        leading: CircleAvatar(
          radius: avatarSize / 2,
          backgroundColor: color,
          child: Text(
            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: avatarSize * 0.4,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(player.name),
        subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
        trailing: trailing,
        onTap: onTap,
        selected: isSelected,
      ),
    );
  }
}
