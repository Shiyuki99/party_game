import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game/data/repositories/player_repository.dart';
import 'package:party_game/provider/app_providers.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_end_screen.dart';
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
  late GameSettings _settings;
  late GameLogic _logic;
  Timer? _timer;
  bool _gameEnded = false;

  @override
  void initState() {
    super.initState();
    _plugin = gamePlugins.firstWhere((g) => g.id == widget.gameId);
    _settings = ref
        .read(activeGameSettingsProvider.notifier)
        .of(widget.gameId, _plugin.defaultSettings);
    _startGame();
  }

  void _startGame() {
    final players = ref.read(playerRepositoryProvider);
    final connection = ref.read(connectionServiceProvider);
    final scoreboard = ref.read(scoreboardServiceProvider);
    final content =
        ref.read(contentRepositoryProvider).getContent(widget.gameId) ?? {};

    _gameEnded = false;
    _logic = _plugin.createLogic(
      GameContext(
        players: players,
        connection: connection,
        content: content,
        settings: _plugin.defaultSettings.copy()
          ..mode = _settings.mode
          ..roundTimeSeconds = _settings.roundTimeSeconds
          ..numberOfRounds = _settings.numberOfRounds
          ..turnsPerPlayer = _settings.turnsPerPlayer
          ..numberOfImposters = _settings.numberOfImposters
          ..rotatingHost = _settings.rotatingHost
          ..extra = Map.from(_settings.extra),
        addScore: (playerId, points) => scoreboard.addScore(playerId, points),
        onGameEnd: _handleGameEnd,
      ),
    );
    _logic.init();

    _timer?.cancel();
    if (_settings.mode == GameMode.timeBased) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) _logic.tick();
      });
    }
    if (mounted) setState(() {});
  }

  void _handleGameEnd() {
    _timer?.cancel();
    if (mounted) setState(() => _gameEnded = true);
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave game?'),
        content: const Text('Your current progress in this game will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }

  void _newParty() {
    ref.read(playerRepositoryProvider.notifier).clear();
    ref.read(scoreboardServiceProvider).reset();
    context.go('/');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gameEnded) {
      return GameEndScreen(
        gameName: _plugin.name,
        onPlayAgain: _startGame,
        onOtherGames: () => context.go('/game-select'),
        onNewParty: _newParty,
      );
    }

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_plugin.name),
          leading: IconButton(
            tooltip: 'Leave game',
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _confirmLeave,
          ),
        ),
        body: SafeArea(
          child: SizedBox.expand(
            child: _plugin.buildScreen(_logic, _logic.context),
          ),
        ),
      ),
    );
  }
}
