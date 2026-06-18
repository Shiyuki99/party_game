import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/app_scaffold.dart';
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

          _buildTimeSetting(),
          const SizedBox(height: 16),

          _buildRoundsSetting(),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Host Mode'),
            subtitle: const Text('Host creates the content'),
            value: _settings.hostMode,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => setState(() => _settings.hostMode = v),
          ),

          if (_settings.hostMode)
            SwitchListTile(
              title: const Text('Rotating Host'),
              subtitle: const Text('Host role rotates each round'),
              value: _settings.rotatingHost,
              activeTrackColor: AppColors.primary,
              onChanged: (v) => setState(() => _settings.rotatingHost = v),
            ),

          const SizedBox(height: 24),

          _plugin.buildSettingsScreen(_settings, (s) {
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

  Widget _buildTimeSetting() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Round Time', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _settings.roundTimeSeconds.toDouble(),
                    min: 10,
                    max: 300,
                    divisions: 29,
                    activeColor: AppColors.primary,
                    label: '${_settings.roundTimeSeconds}s',
                    onChanged: (v) =>
                        setState(() => _settings.roundTimeSeconds = v.toInt()),
                  ),
                ),
                Text(
                  '${_settings.roundTimeSeconds}s',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundsSetting() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Number of Rounds', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.repeat, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _settings.numberOfRounds.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    activeColor: AppColors.primary,
                    label: '${_settings.numberOfRounds}',
                    onChanged: (v) =>
                        setState(() => _settings.numberOfRounds = v.toInt()),
                  ),
                ),
                Text(
                  '${_settings.numberOfRounds}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
