import 'package:flutter/material.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/truth_or_dare/models.dart';
import 'package:party_game/ui/features/games/truth_or_dare/settings.dart';
import 'package:party_game/ui/features/games/truth_or_dare/play.dart';

class TruthOrDareLogic extends GameLogic {
  @override
  final GameContext context;
  @override
  bool get isFinished => false;

  TruthOrDareLogic(this.context);

  @override
  void init() {}

  @override
  void handleAction(String action, {Map<String, dynamic>? payload}) {}

  @override
  void tick() {}

  @override
  Map<String, dynamic> get state => {};
}

class TruthOrDarePlugin implements GamePlugin {
  @override
  String get id => 'truth_or_dare';

  @override
  String get name => 'Truth or Dare';

  @override
  IconData get icon => Icons.psychology;

  @override
  String get description => 'Take turns asking truth or dare';

  @override
  GameSettings get defaultSettings => GameSettings(
        numberOfRounds: 10,
        turnsPerPlayer: 1,
        extra: TruthOrDareSettings().toExtra(),
      );

  @override
  Widget buildSettingsScreen(
      BuildContext context, GameSettings settings, ValueChanged<GameSettings> onChanged) {
    final gameSettings = TruthOrDareSettings.fromExtra(settings.extra);
    return TruthOrDareSettingsWidget(
      settings: gameSettings,
      onChanged: (s) {
        final c = settings.copy();
        c.extra = s.toExtra();
        onChanged(c);
      },
    );
  }

  @override
  GameLogic createLogic(GameContext context) => TruthOrDareLogic(context);

  @override
  Widget buildUI(GameLogic logic, GameContext context) {
    final gameSettings =
        TruthOrDareSettings.fromExtra(context.settings.extra);
    return TruthOrDarePlayScreen(
      context: context,
      gameSettings: gameSettings,
    );
  }
}
