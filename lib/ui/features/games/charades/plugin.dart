import 'package:flutter/material.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/charades/play.dart';

class CharadesLogic extends GameLogic {
  @override
  final GameContext context;
  @override
  bool get isFinished => false;

  CharadesLogic(this.context);

  @override
  void init() {}

  @override
  void handleAction(String action, {Map<String, dynamic>? payload}) {}

  @override
  void tick() {}

  @override
  Map<String, dynamic> get state => {};
}

class CharadesPlugin implements GamePlugin {
  @override
  String get id => 'charades';

  @override
  String get name => 'Charades';

  @override
  IconData get icon => Icons.theater_comedy;

  @override
  String get description => 'Act it out, guess the word';

  @override
  GameSettings get defaultSettings => GameSettings(
        numberOfRounds: 10,
        turnsPerPlayer: 1,
      );

  @override
  Widget buildSettingsScreen(
      BuildContext context, GameSettings settings, ValueChanged<GameSettings> onChanged) {
    return const SizedBox();
  }

  @override
  GameLogic createLogic(GameContext context) => CharadesLogic(context);

  @override
  Widget buildUI(GameLogic logic, GameContext context) {
    return CharadesPlayScreen(context: context);
  }
}
