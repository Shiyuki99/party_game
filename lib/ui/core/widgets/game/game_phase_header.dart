import 'package:flutter/material.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';

class GamePhaseHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int? remainingTime;

  const GamePhaseHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.remainingTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            if (remainingTime != null) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: remainingTime! < 15
                      ? AppColors.error.withValues(alpha: 0.2)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer,
                        size: 16,
                        color: remainingTime! < 15
                            ? AppColors.error
                            : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${remainingTime}s',
                        style: TextStyle(
                            color: remainingTime! < 15
                                ? AppColors.error
                                : AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}
