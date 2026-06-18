import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:party_game/data/models/player.dart';
import 'package:uuid/uuid.dart';

class PlayerRepository extends Notifier<List<Player>> {
  @override
  List<Player> build() => [];

  Player addPlayer(String name, {bool isHost = false}) {
    final player = Player(
      id: const Uuid().v4(),
      name: name,
      isHost: isHost,
    );
    state = [...state, player];
    return player;
  }

  void removePlayer(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void clear() => state = [];
}

final playerRepositoryProvider =
    NotifierProvider<PlayerRepository, List<Player>>(
  PlayerRepository.new,
);
