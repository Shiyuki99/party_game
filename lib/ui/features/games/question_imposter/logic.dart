import 'package:party_game/ui/features/game_engine/game_plugin.dart';

class QuestionImposterLogic extends GameLogic {
  @override
  final GameContext context;
  @override
  bool get isFinished => false;

  QuestionImposterLogic(this.context);

  @override
  void init() {}

  @override
  void handleAction(String action, {Map<String, dynamic>? payload}) {}

  @override
  void tick() {}
}
