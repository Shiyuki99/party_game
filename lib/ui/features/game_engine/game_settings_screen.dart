import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game/data/repositories/player_repository.dart';
import 'package:party_game/provider/app_providers.dart';
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
    final chosen = ref
        .read(activeGameSettingsProvider.notifier)
        .of(widget.gameId, _plugin.defaultSettings);
    _settings = chosen.copy()
      ..extra = Map.from(chosen.extra);
  }

  void _start() {
    ref
        .read(activeGameSettingsProvider.notifier)
        .set(widget.gameId, _settings);
    context.push('/game-play/${widget.gameId}');
  }

  @override
  Widget build(BuildContext context) {
    final playerCount = ref.watch(playerRepositoryProvider).length;

    return AppScaffold(
      title: _plugin.name,
      body: ListView(
        children: [
          Text('Game Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(_plugin.description,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          _modeSelector(),
          const SizedBox(height: 12),
          if (_settings.mode == GameMode.roundBased) _roundsSlider(),
          if (_settings.mode == GameMode.timeBased) _timeSlider(),
          const SizedBox(height: 12),
          _turnsSlider(),
          const SizedBox(height: 12),
          _plugin.buildSettingsScreen(context, _settings, (s) {
            setState(() => _settings = s);
          }),
          const SizedBox(height: 24),
          if (playerCount < 2)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add at least 2 players in the lobby to start.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Start Game',
            icon: Icons.play_arrow,
            onPressed: playerCount >= 2 ? _start : null,
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _modeSelector() {
    return _sectionCard(
      icon: Icons.tune,
      title: 'Mode',
      child: SegmentedButton<GameMode>(
        segments: const [
          ButtonSegment(
              value: GameMode.roundBased,
              label: Text('Rounds'),
              icon: Icon(Icons.repeat)),
          ButtonSegment(
              value: GameMode.timeBased,
              label: Text('Timed'),
              icon: Icon(Icons.timer)),
        ],
        selected: {_settings.mode},
        onSelectionChanged: (v) => setState(() => _settings.mode = v.first),
      ),
    );
  }

  Widget _roundsSlider() {
    return _sectionCard(
      icon: Icons.repeat,
      title: 'Rounds  ·  ${_settings.numberOfRounds}',
      child: Slider(
        value: _settings.numberOfRounds.toDouble(),
        min: 1,
        max: 20,
        divisions: 19,
        label: '${_settings.numberOfRounds}',
        onChanged: (v) =>
            setState(() => _settings.numberOfRounds = v.toInt()),
      ),
    );
  }

  Widget _timeSlider() {
    return _sectionCard(
      icon: Icons.timer,
      title: 'Time per round  ·  ${_settings.roundTimeSeconds}s',
      child: Slider(
        value: _settings.roundTimeSeconds.toDouble(),
        min: 15,
        max: 180,
        divisions: 11,
        label: '${_settings.roundTimeSeconds}s',
        onChanged: (v) =>
            setState(() => _settings.roundTimeSeconds = v.roundToNearest(15)),
      ),
    );
  }

  Widget _turnsSlider() {
    return _sectionCard(
      icon: Icons.swap_horiz,
      title: 'Turns per player  ·  ${_settings.turnsPerPlayer}',
      child: Slider(
        value: _settings.turnsPerPlayer.toDouble(),
        min: 1,
        max: 5,
        divisions: 4,
        label: '${_settings.turnsPerPlayer}',
        onChanged: (v) =>
            setState(() => _settings.turnsPerPlayer = v.toInt()),
      ),
    );
  }
}

extension on num {
  int roundToNearest(int step) => (this / step).round() * step;
}
