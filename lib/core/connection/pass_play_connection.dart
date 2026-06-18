import 'dart:async';
import 'package:party_game/core/connection/connection_service.dart';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/data/models/connection_type.dart';

class PassPlayConnectionService extends ConnectionService {
  final List<Player> _players = [];
  final _onMessageController = StreamController<NetworkMessage>.broadcast();
  final _onPlayerJoinController = StreamController<Player>.broadcast();
  final _onPlayerLeaveController = StreamController<String>.broadcast();

  @override
  ConnectionType get type => ConnectionType.passAndPlay;

  @override
  Stream<NetworkMessage> get onMessage => _onMessageController.stream;

  @override
  Stream<Player> get onPlayerJoin => _onPlayerJoinController.stream;

  @override
  Stream<String> get onPlayerLeave => _onPlayerLeaveController.stream;

  @override
  Future<void> initialize({required bool isHost}) async {}

  void addPlayer(Player player) {
    _players.add(player);
    _onPlayerJoinController.add(player);
  }

  void removePlayer(String playerId) {
    _players.removeWhere((p) => p.id == playerId);
    _onPlayerLeaveController.add(playerId);
  }

  List<Player> get players => List.unmodifiable(_players);

  @override
  Future<void> send(String playerId, NetworkMessage message) async {
    _onMessageController.add(message);
  }

  @override
  Future<void> broadcast(NetworkMessage message, {String? excludeId}) async {
    _onMessageController.add(message);
  }

  @override
  Future<void> disconnect() async {
    await _onMessageController.close();
    await _onPlayerJoinController.close();
    await _onPlayerLeaveController.close();
  }
}
