import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/core/connection/pass_play_connection.dart';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/ui/features/game_engine/game_core.dart';
import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/charades/logic.dart';
import 'package:party_game/ui/features/games/imposter/logic.dart';
import 'package:party_game/ui/features/games/question_imposter/logic.dart';
import 'package:party_game/ui/features/games/truth_or_dare/logic.dart';
import 'package:party_game/ui/features/games/truth_or_dare/models.dart';

Map<String, dynamic> _content(String id) =>
    jsonDecode(File('content/$id.json').readAsStringSync())
        as Map<String, dynamic>;

GameContext _context({
  required int playerCount,
  required String gameId,
  required GameSettings settings,
  Map<String, int>? scores,
}) {
  final players = List<Player>.generate(
    playerCount,
    (i) => Player(id: 'p$i', name: 'Player $i'),
  );
  return GameContext(
    players: players,
    connection: PassPlayConnectionService(),
    content: _content(gameId),
    settings: settings,
    addScore: (id, points) =>
        scores?.update(id, (v) => v + points, ifAbsent: () => points),
    onGameEnd: () {},
  );
}

void main() {
  group('Truth or Dare', () {
    test('runs configured rounds, never repeats asker, awards points', () {
      final scores = <String, int>{};
      final logic = TruthOrDareLogic(_context(
        playerCount: 4,
        gameId: 'truth_or_dare',
        settings: GameSettings(
          numberOfRounds: 4,
          extra: TruthOrDareSettings().toExtra(),
        ),
        scores: scores,
      ));

      logic.init();
      expect(logic.gameState.phase, TruthDarePhase.choose);
      String? previousAsker;
      for (var round = 1; round <= 4; round++) {
        expect(logic.gameState.round, round);
        expect(logic.gameState.askerId, isNot(previousAsker));
        previousAsker = logic.gameState.askerId;
        logic.choose(AnswerType.values[round % 2]);
        expect(logic.gameState.phase, TruthDarePhase.prompt);
        expect(logic.gameState.prompt, isNotEmpty);
        logic.handleAction('complete');
      }
      expect(logic.isFinished, isTrue);
      expect(scores.values.fold<int>(0, (a, b) => a + b), 4);
    });
  });

  group('Imposter', () {
    test('assigns roles, reveals, collects clues, resolves votes and rounds', () {
      final scores = <String, int>{};
      final logic = ImposterLogic(_context(
        playerCount: 4,
        gameId: 'imposter',
        settings: GameSettings(
          numberOfRounds: 2,
          numberOfImposters: 1,
          turnsPerPlayer: 1,
        ),
        scores: scores,
      ));

      logic.init();
      final imposters = logic.gameState.roles!.playersWithRole('imposter');
      expect(imposters, hasLength(1));
      expect(logic.gameState.activeWord, isNotEmpty);

      for (var i = 0; i < 4; i++) {
        logic.handleAction('reveal_next');
      }
      expect(logic.gameState.phase, ImposterPhase.submitting);

      for (var i = 0; i < 4; i++) {
        logic.handleAction('submit_keyword', payload: {'keyword': 'clue$i'});
      }
      expect(logic.gameState.phase, ImposterPhase.voting);

      final imposterIdx = int.parse(imposters.single.substring(1));
      for (var voter = 0; voter < 4; voter++) {
        logic.handleAction('vote', payload: {
          'voterIdx': voter,
          'votedIdx': voter == imposterIdx ? (voter + 1) % 4 : imposterIdx,
        });
      }
      expect(logic.gameState.phase, ImposterPhase.roundResult);
      expect(logic.gameState.imposterCaught, isTrue);
      expect(scores[imposters.single], 0);
      expect(scores.values.fold<int>(0, (a, b) => a + b), 30);

      logic.handleAction('next_round');
      expect(logic.gameState.round, 2);
      expect(logic.gameState.phase, ImposterPhase.revealRole);
      logic.handleAction('next_round');
      expect(logic.isFinished, isTrue);
    });
  });

  group('timed play', () {
    test('imposter clock advances phases without stalling at zero', () {
      final logic = ImposterLogic(_context(
        playerCount: 3,
        gameId: 'imposter',
        settings: GameSettings(
          mode: GameMode.timeBased,
          roundTimeSeconds: 15,
          numberOfRounds: 1,
        ),
      ));
      logic.init();
      for (var i = 0; i < 15; i++) {
        logic.tick();
      }
      expect(logic.gameState.phase, ImposterPhase.submitting);
      for (var i = 0; i < 15; i++) {
        logic.tick();
      }
      expect(logic.gameState.phase, ImposterPhase.voting);
    });
  });

  group('Question Imposter', () {
    test('hides question from imposters, scores on a correct vote', () {
      final scores = <String, int>{};
      final logic = QuestionImposterLogic(_context(
        playerCount: 4,
        gameId: 'question_imposter',
        settings: GameSettings(numberOfRounds: 1, numberOfImposters: 1),
        scores: scores,
      ));

      logic.init();
      final state = logic.gameState;
      expect(state.imposters, hasLength(1));
      expect(state.question, isNotEmpty);
      logic.handleAction('acknowledge');
      expect(logic.gameState.phase, QuestionImposterPhase.answering);

      for (var i = 0; i < 4; i++) {
        logic.handleAction('answer', payload: {'answer': 'answer $i'});
      }
      expect(logic.gameState.phase, QuestionImposterPhase.voting);
      expect(logic.gameState.answers, hasLength(4));

      final imposter = state.imposters.single;
      for (var voter = 0; voter < 4; voter++) {
        logic.handleAction('vote', payload: {
          'voterIdx': voter,
          'votedIdx': voter == imposter ? (voter + 1) % 4 : imposter,
        });
      }
      expect(logic.gameState.phase, QuestionImposterPhase.roundResult);
      expect(logic.gameState.imposterCaught, isTrue);
      expect(scores.values.fold<int>(0, (a, b) => a + b), 30);
      logic.handleAction('next_round');
      expect(logic.isFinished, isTrue);
    });
  });

  group('Charades', () {
    test('awards guesser, supports skip, respects round limit', () {
      final scores = <String, int>{};
      final logic = CharadesLogic(_context(
        playerCount: 4,
        gameId: 'charades',
        settings: GameSettings(
          mode: GameMode.timeBased,
          numberOfRounds: 3,
          extra: const {'charadesMode': 'solo'},
        ),
        scores: scores,
      ));

      logic.init();
      expect(logic.gameState.word, isNotEmpty);
      logic.handleAction('start_acting');
      final actorId = logic.context.players[logic.gameState.actorIndex].id;
      final guesser = logic.context.players.firstWhere((p) => p.id != actorId);
      logic.handleAction('guess', payload: {'playerId': guesser.id});
      expect(logic.gameState.phase, CharadesPhase.roundResult);
      expect(scores[guesser.id], 10);

      logic.handleAction('next_round');
      logic.handleAction('start_acting');
      logic.handleAction('skip');
      expect(logic.gameState.timedOut, isTrue);
      logic.handleAction('next_round');
      logic.handleAction('start_acting');
      logic.handleAction('next_round');
      expect(logic.isFinished, isTrue);
    });
  });
}
