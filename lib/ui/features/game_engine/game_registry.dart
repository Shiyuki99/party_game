import 'package:party_game/ui/features/game_engine/game_plugin.dart';
import 'package:party_game/ui/features/games/truth_or_dare/plugin.dart';
import 'package:party_game/ui/features/games/imposter/plugin.dart';
import 'package:party_game/ui/features/games/question_imposter/plugin.dart';
import 'package:party_game/ui/features/games/charades/plugin.dart';

final gamePlugins = <GamePlugin>[
  TruthOrDarePlugin(),
  ImposterPlugin(),
  QuestionImposterPlugin(),
  CharadesPlugin(),
];
