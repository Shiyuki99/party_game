import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game/ui/features/game_engine/game_play_screen.dart';
import 'package:party_game/ui/features/game_engine/game_settings_screen.dart';
import 'package:party_game/ui/features/game_engine/game_select_screen.dart';
import 'package:party_game/ui/features/party_flow/join_screen/join_screen.dart';
import 'package:party_game/ui/features/party_flow/lobby_screen/lobby_screen.dart';
import 'package:party_game/ui/features/party_flow/party_type_screen/party_type_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'partyType',
        builder: (context, state) => const PartyTypeScreen(),
      ),
      GoRoute(
        path: '/join',
        name: 'join',
        builder: (context, state) => const JoinScreen(),
      ),
      GoRoute(
        path: '/lobby',
        name: 'lobby',
        builder: (context, state) => const LobbyScreen(),
      ),
      GoRoute(
        path: '/game-select',
        name: 'gameSelect',
        builder: (context, state) => const GameSelectScreen(),
      ),
      GoRoute(
        path: '/game-settings/:gameId',
        name: 'gameSettings',
        builder: (context, state) => GameSettingsScreen(
          gameId: state.pathParameters['gameId']!,
        ),
      ),
      GoRoute(
        path: '/game-play/:gameId',
        name: 'gamePlay',
        builder: (context, state) => GamePlayScreen(
          gameId: state.pathParameters['gameId']!,
        ),
      ),
    ],
  );
});
