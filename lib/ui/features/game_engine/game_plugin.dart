import 'package:flutter/material.dart';
import 'package:party_game/core/connection/connection_service.dart';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';

class GameContext {
  final List<Player> players;
  final ConnectionService connection;
  final Map<String, dynamic> content;
  final GameSettings settings;
  final void Function(String playerId, int points) addScore;
  final VoidCallback onGameEnd;

  GameContext({
    required this.players,
    required this.connection,
    required this.content,
    required this.settings,
    required this.addScore,
    required this.onGameEnd,
  });
}

abstract class GameLogic {
  GameContext get context;
  bool get isFinished;

  void init();
  void handleAction(String action, {Map<String, dynamic>? payload});
  void tick(); // called every second for timer
}

abstract class GamePlugin {
  String get id;
  String get name;
  IconData get icon;
  String get description;
  GameSettings get defaultSettings;
  Widget buildSettingsScreen(BuildContext context, GameSettings settings, ValueChanged<GameSettings> onChanged);
  GameLogic createLogic(GameContext context);
  Widget buildUI(GameLogic logic, GameContext context);
}
