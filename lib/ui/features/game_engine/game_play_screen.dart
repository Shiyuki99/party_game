import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_game/data/repositories/player_repository.dart';
import 'package:party_game/provider/app_providers.dart';
import 'package:party_game/ui/core/widgets/app_scaffold.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/game_engine/game_registry.dart';

class GamePlayScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GamePlayScreen({super.key, required this.gameId});

  @override
  ConsumerState<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends ConsumerState<GamePlayScreen> {
  late GamePlugin _plugin;
  late GameLogic _logic;
  Timer? _timer;
  bool _gameEnded = false;

  @override
  void initState() {
    super.initState();
    _plugin = gamePlugins.firstWhere((g) => g.id == widget.gameId);
    _initGame();
  }

  void _initGame() {
    final players = ref.read(playerRepositoryProvider);
    final connection = ref.read(connectionServiceProvider);
    final scoreboard = ref.read(scoreboardServiceProvider);
    final content = ref.read(contentRepositoryProvider).getContent(widget.gameId) ?? {};

    _logic = _plugin.createLogic(
      GameContext(
        players: players,
        connection: connection,
        content: content,
        settings: _plugin.defaultSettings,
        addScore: (playerId, points) => scoreboard.addScore(playerId, points),
        onGameEnd: _handleGameEnd,
      ),
    );
    _logic.init();

    if (_plugin.defaultSettings.mode == GameMode.timeBased) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _logic.tick());
          if (_logic.isFinished) _handleGameEnd();
        }
      });
    }

    setState(() {});
  }

  void _handleGameEnd() {
    _timer?.cancel();
    setState(() => _gameEnded = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gameEnded) {
      return AppScaffold(
        title: 'Game Over',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Game Over!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to Menu'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: _plugin.buildUI(_logic, _logic.context),
      ),
    );
  }
}
