import 'dart:math';

enum GameMode { timeBased, roundBased }

class PlayerTurn {
  final String playerId;
  final int order;

  const PlayerTurn({required this.playerId, required this.order});
}

class GameSettings {
  GameMode mode;
  int roundTimeSeconds;
  int numberOfRounds;
  int turnsPerPlayer;
  int numberOfImposters;
  bool rotatingHost;
  Map<String, dynamic> extra;

  GameSettings({
    this.mode = GameMode.roundBased,
    this.roundTimeSeconds = 60,
    this.numberOfRounds = 5,
    this.turnsPerPlayer = 1,
    this.numberOfImposters = 1,
    this.rotatingHost = false,
    Map<String, dynamic>? extra,
  }) : extra = extra ?? {};

  GameSettings copy() => GameSettings(
        mode: mode,
        roundTimeSeconds: roundTimeSeconds,
        numberOfRounds: numberOfRounds,
        turnsPerPlayer: turnsPerPlayer,
        numberOfImposters: numberOfImposters,
        rotatingHost: rotatingHost,
        extra: Map.from(extra),
      );
}

class PlayerOrder {
  final List<String> playerIds;
  PlayerOrder(List<String> ids) : playerIds = List.unmodifiable(ids);

  factory PlayerOrder.random(List<String> ids, {int? seed}) {
    final list = List<String>.from(ids);
    final rng = seed != null ? Random(seed) : Random();
    list.shuffle(rng);
    return PlayerOrder(list);
  }

  String get current => playerIds[_index % playerIds.length];
  int get currentIndex => _index % playerIds.length;
  bool get isComplete => _index >= playerIds.length;
  int get remaining => playerIds.length - (_index % playerIds.length);

  int _index = 0;
  void advance() => _index++;
  void reset() => _index = 0;

  PlayerOrder copy() {
    final p = PlayerOrder(List.from(playerIds));
    p._index = _index;
    return p;
  }
}

class RoleAssignment {
  final Map<String, String> roles; // playerId -> role name

  const RoleAssignment(this.roles);

  String roleOf(String playerId) => roles[playerId] ?? '';
  bool hasRole(String playerId, String role) => roles[playerId] == role;
  List<String> playersWithRole(String role) =>
      roles.entries.where((e) => e.value == role).map((e) => e.key).toList();

  factory RoleAssignment.random({
    required List<String> playerIds,
    required int imposters,
    String citizenRole = 'citizen',
    String imposterRole = 'imposter',
    int? seed,
  }) {
    final rng = seed != null ? Random(seed) : Random();
    final shuffled = List<String>.from(playerIds)..shuffle(rng);
    final imposters_ = shuffled.take(imposters).toSet();
    final roles = <String, String>{};
    for (final id in playerIds) {
      roles[id] = imposters_.contains(id) ? imposterRole : citizenRole;
    }
    return RoleAssignment(roles);
  }
}
