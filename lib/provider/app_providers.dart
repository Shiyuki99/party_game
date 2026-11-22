import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:party_game/core/connection/connection_service.dart';
import 'package:party_game/core/connection/connection_factory.dart';
import 'package:party_game/core/content/content_service.dart';
import 'package:party_game/core/scoreboard/scoreboard_service.dart';
import 'package:party_game/data/models/connection_type.dart';
import 'package:party_game/data/models/party_type.dart';
import 'package:party_game/data/services/content_repository.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';

class ConnectionTypeNotifier extends Notifier<ConnectionType> {
  @override
  ConnectionType build() => ConnectionType.passAndPlay;

  void set(ConnectionType type) => state = type;
}
final connectionTypeProvider =
    NotifierProvider<ConnectionTypeNotifier, ConnectionType>(
        ConnectionTypeNotifier.new);

class PartyTypeNotifier extends Notifier<PartyType> {
  @override
  PartyType build() => PartyType.passAndPlay;

  void set(PartyType type) => state = type;
}
final partyTypeProvider =
    NotifierProvider<PartyTypeNotifier, PartyType>(PartyTypeNotifier.new);

final connectionServiceProvider = Provider<ConnectionService>((ref) {
  final type = ref.watch(connectionTypeProvider);
  return createConnectionService(type);
});

final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final contentServiceProvider = Provider<ContentService>((ref) {
  final client = ref.watch(httpClientProvider);
  final contentBox = Hive.box('game_content');
  final settingsBox = Hive.box('app_settings');
  return ContentService(
    client: client,
    contentBox: contentBox,
    settingsBox: settingsBox,
  );
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final service = ref.watch(contentServiceProvider);
  return ContentRepository(contentService: service);
});

final scoreboardServiceProvider = Provider<ScoreboardService>((ref) {
  final box = Hive.box('scoreboard');
  final service = ScoreboardService(persistBox: box);
  service.loadPersisted();
  return service;
});

class HostIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}
final hostIdProvider =
    NotifierProvider<HostIdNotifier, String?>(HostIdNotifier.new);

/// Settings chosen on the settings screen, keyed by game id. Consumed by the
/// play screen so tweaks made by the host actually reach the game logic.
class ActiveGameSettingsNotifier extends Notifier<Map<String, GameSettings>> {
  @override
  Map<String, GameSettings> build() => const {};

  void set(String gameId, GameSettings settings) =>
      state = {...state, gameId: settings};

  GameSettings of(String gameId, GameSettings fallback) =>
      state[gameId] ?? fallback;
}
final activeGameSettingsProvider =
    NotifierProvider<ActiveGameSettingsNotifier, Map<String, GameSettings>>(
        ActiveGameSettingsNotifier.new);
