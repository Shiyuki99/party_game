import 'package:flutter/material.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/features/games/truth_or_dare/models.dart';

class TruthOrDareSettingsWidget extends StatelessWidget {
  final TruthOrDareSettings settings;
  final ValueChanged<TruthOrDareSettings> onChanged;

  const TruthOrDareSettingsWidget({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Game Rules', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildToggle(
          'No Repeat Asker',
          'Same player can\'t ask twice in a row',
          settings.noRepeatAsker,
          (v) => onChanged(settings.copy()..noRepeatAsker = v),
        ),
        _buildToggle(
          'Everyone Once Per Round',
          'Each player questioned once before repeat',
          settings.everyoneOncePerRound,
          (v) => onChanged(settings.copy()..everyoneOncePerRound = v),
        ),
        _buildToggle(
          'Last Player Can\'t Ask',
          'Last answerer can\'t be next asker',
          settings.lastPlayerCantAsk,
          (v) => onChanged(settings.copy()..lastPlayerCantAsk = v),
        ),
        _buildToggle(
          'Allow Custom Content',
          'Players can input their own truths/dares',
          settings.allowCustomContent,
          (v) => onChanged(settings.copy()..allowCustomContent = v),
        ),
      ],
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        activeTrackColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}
