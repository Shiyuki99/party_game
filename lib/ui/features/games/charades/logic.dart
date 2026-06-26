import 'package:party_game/ui/features/game_engine/game_plugin.dart';

class CharadesLogic extends GameLogic {
  @override
  final GameContext context;
  @override
  bool get isFinished => false;

  CharadesLogic(this.context);

  @override
  void init() {}

  @override
  void handleAction(String action, {Map<String, dynamic>? payload}) {}

  @override
  void tick() {}
}
