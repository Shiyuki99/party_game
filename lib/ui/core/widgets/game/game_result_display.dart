import 'package:flutter/material.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';

class GameResultDisplay extends StatelessWidget {
  final String message;
  final bool success;
  final Map<String, String> details;
  final String buttonLabel;
  final VoidCallback onButton;

  const GameResultDisplay({
    super.key,
    required this.message,
    required this.success,
    this.details = const {},
    this.buttonLabel = 'Next',
    required this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          Icon(
            success ? Icons.celebration : Icons.sentiment_dissatisfied,
            size: 64,
            color: success ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: success ? AppColors.success : AppColors.error,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ...details.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${e.key}: ${e.value}',
                    style: Theme.of(context).textTheme.titleMedium),
              )),
          const Spacer(),
          AppButton(label: buttonLabel, onPressed: onButton),
        ],
      ),
    );
  }
}
