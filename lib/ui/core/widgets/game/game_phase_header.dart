import 'package:flutter/material.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';

class GamePhaseHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int? remainingTime;
  final int? round;
  final int? totalRounds;

  const GamePhaseHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.remainingTime,
    this.round,
    this.totalRounds,
  });

  @override
  Widget build(BuildContext context) {
    final showProgress = round != null && totalRounds != null && totalRounds! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            if (remainingTime != null) ...[
              const SizedBox(width: 8),
              Semantics(
                label: '$remainingTime seconds remaining',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              fontFeatures: const [FontFeature.tabularFigures()],
                              fontWeight: FontWeight.w600,
                              color: remainingTime! < 15
                                  ? AppColors.error
                                  : AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
        if (showProgress) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (round! / totalRounds!).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceLight,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('$round/$totalRounds',
                  style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ],
      ],
    );
  }
}
