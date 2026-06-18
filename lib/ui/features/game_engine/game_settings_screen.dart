import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/app_scaffold.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/game_engine/game_registry.dart';

class GameSettingsScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GameSettingsScreen({super.key, required this.gameId});

  @override
  ConsumerState<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends ConsumerState<GameSettingsScreen> {
  late GamePlugin _plugin;
  late GameSettings _settings;

  @override
  void initState() {
    super.initState();
    _plugin = gamePlugins.firstWhere((g) => g.id == widget.gameId);
    _settings = _plugin.defaultSettings.copy();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _plugin.name,
      body: ListView(
        children: [
          Text('Game Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          _ModeSelector(),
          const SizedBox(height: 16),
          if (_settings.mode == GameMode.roundBased) _RoundsSlider(),
          if (_settings.mode == GameMode.timeBased) _TimeSlider(),
          const SizedBox(height: 8),
          _TurnsSlider(),
          const SizedBox(height: 16),
          _plugin.buildSettingsScreen(context, _settings, (s) {
            setState(() => _settings = s);
          }),
          const SizedBox(height: 32),
          AppButton(
            label: 'Start Game',
            onPressed: () => context.push('/game-play/${widget.gameId}'),
          ),
        ],
      ),
    );
  }

  Widget _ModeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.settings, color: AppColors.primary),
            const SizedBox(width: 12),
            Text('Mode', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            SegmentedButton<GameMode>(
              segments: const [
                ButtonSegment(value: GameMode.roundBased, label: Text('Rounds')),
                ButtonSegment(value: GameMode.timeBased, label: Text('Timed')),
              ],
              selected: {_settings.mode},
              onSelectionChanged: (v) => setState(() => _settings.mode = v.first),
            ),
          ],
        ),
      ),
    );
  }

  Widget _RoundsSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rounds', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                const Icon(Icons.repeat, color: AppColors.primary),
                Expanded(
                  child: Slider(
                    value: _settings.numberOfRounds.toDouble(),
                    min: 1, max: 30, divisions: 29,
                    activeColor: AppColors.primary,
                    label: '${_settings.numberOfRounds}',
                    onChanged: (v) => setState(() => _settings.numberOfRounds = v.toInt()),
                  ),
                ),
                Text('${_settings.numberOfRounds}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _TimeSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time per Action', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                const Icon(Icons.timer, color: AppColors.primary),
                Expanded(
                  child: Slider(
                    value: _settings.roundTimeSeconds.toDouble(),
                    min: 10, max: 300, divisions: 29,
                    activeColor: AppColors.primary,
                    label: '${_settings.roundTimeSeconds}s',
                    onChanged: (v) => setState(() => _settings.roundTimeSeconds = v.toInt()),
                  ),
                ),
                Text('${_settings.roundTimeSeconds}s'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _TurnsSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Turns per Player', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                const Icon(Icons.swap_horiz, color: AppColors.primary),
                Expanded(
                  child: Slider(
                    value: _settings.turnsPerPlayer.toDouble(),
                    min: 1, max: 10, divisions: 9,
                    activeColor: AppColors.primary,
                    label: '${_settings.turnsPerPlayer}',
                    onChanged: (v) => setState(() => _settings.turnsPerPlayer = v.toInt()),
                  ),
                ),
                Text('${_settings.turnsPerPlayer}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
