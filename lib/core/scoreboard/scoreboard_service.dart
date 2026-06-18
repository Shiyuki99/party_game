import 'package:hive/hive.dart';
import 'package:party_game/data/models/player.dart';

class ScoreboardService {
  final Map<String, int> _scores = {};
  final Box _persistBox;

  ScoreboardService({required Box persistBox}) : _persistBox = persistBox;

  Map<String, int> get scores => Map.unmodifiable(_scores);

  void setPlayers(List<Player> players) {
    for (final p in players) {
      _scores.putIfAbsent(p.id, () => p.score);
    }
    _persist();
  }

  void addScore(String playerId, int points) {
    _scores.update(playerId, (v) => v + points, ifAbsent: () => points);
    _persist();
  }

  void setScore(String playerId, int score) {
    _scores[playerId] = score;
    _persist();
  }

  int getScore(String playerId) => _scores[playerId] ?? 0;

  List<MapEntry<String, int>> get sorted =>
      _scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  void _persist() {
    _persistBox.put('scores', _scores);
  }

  void loadPersisted() {
    final saved = _persistBox.get('scores');
    if (saved is Map) {
      _scores.addAll(saved.cast<String, int>());
    }
  }

  void reset() {
    _scores.clear();
    _persistBox.delete('scores');
  }
}
