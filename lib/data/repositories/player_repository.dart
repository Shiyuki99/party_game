import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_game/data/models/player.dart';
import 'package:uuid/uuid.dart';

class PlayerRepository {
  final List<Player> _players = [];

  List<Player> get players => List.unmodifiable(_players);

  Player addPlayer(String name, {bool isHost = false}) {
    final player = Player(
      id: const Uuid().v4(),
      name: name,
      isHost: isHost,
    );
    _players.add(player);
    return player;
  }

  void removePlayer(String id) {
    _players.removeWhere((p) => p.id == id);
  }

  void clear() {
    _players.clear();
  }
}

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository();
});
