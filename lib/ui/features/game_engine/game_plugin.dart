import 'package:flutter/material.dart';
import 'package:party_game/core/connection/connection_service.dart';
import 'package:party_game/data/models/player.dart';

class GameSettings {
  int roundTimeSeconds;
  int numberOfRounds;
  bool hostMode;
  bool rotatingHost;
  String? currentHostId;
  Map<String, dynamic> extra;

  GameSettings({
    this.roundTimeSeconds = 60,
    this.numberOfRounds = 3,
    this.hostMode = false,
    this.rotatingHost = false,
    this.currentHostId,
    Map<String, dynamic>? extra,
  }) : extra = extra ?? {};

  GameSettings copy() => GameSettings(
        roundTimeSeconds: roundTimeSeconds,
        numberOfRounds: numberOfRounds,
        hostMode: hostMode,
        rotatingHost: rotatingHost,
        currentHostId: currentHostId,
        extra: Map.from(extra),
      );
}

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

abstract class GamePlugin {
  String get id;
  String get name;
  IconData get icon;
  String get description;
  GameSettings get defaultSettings;
  Widget buildSettingsScreen(GameSettings settings, ValueChanged<GameSettings> onChanged);
  Widget buildPlayScreen(GameContext context);
}
