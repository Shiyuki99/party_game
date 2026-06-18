import 'package:flutter/material.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';

class PlayerAvatar extends StatelessWidget {
  final String name;
  final int index;
  final double size;
  final bool isHost;

  const PlayerAvatar({
    super.key,
    required this.name,
    required this.index,
    this.size = 40,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.playerColors[index % AppColors.playerColors.length];
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: color,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                initials.toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (isHost)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.star,
                    size: size * 0.35,
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
