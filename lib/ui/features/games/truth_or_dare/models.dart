class TruthOrDareSettings {
  bool noRepeatAsker;
  bool everyoneOncePerRound;
  bool lastPlayerCantAsk;
  bool allowCustomContent;

  TruthOrDareSettings({
    this.noRepeatAsker = true,
    this.everyoneOncePerRound = true,
    this.lastPlayerCantAsk = true,
    this.allowCustomContent = false,
  });

  TruthOrDareSettings copy() => TruthOrDareSettings(
        noRepeatAsker: noRepeatAsker,
        everyoneOncePerRound: everyoneOncePerRound,
        lastPlayerCantAsk: lastPlayerCantAsk,
        allowCustomContent: allowCustomContent,
      );

  Map<String, dynamic> toExtra() => {
        'noRepeatAsker': noRepeatAsker,
        'everyoneOncePerRound': everyoneOncePerRound,
        'lastPlayerCantAsk': lastPlayerCantAsk,
        'allowCustomContent': allowCustomContent,
      };

  factory TruthOrDareSettings.fromExtra(Map<String, dynamic> extra) =>
      TruthOrDareSettings(
        noRepeatAsker: extra['noRepeatAsker'] as bool? ?? true,
        everyoneOncePerRound: extra['everyoneOncePerRound'] as bool? ?? true,
        lastPlayerCantAsk: extra['lastPlayerCantAsk'] as bool? ?? true,
        allowCustomContent: extra['allowCustomContent'] as bool? ?? false,
      );
}

enum AnswerType { truth, dare }

class RoundPair {
  final String askerId;
  final String answererId;
  AnswerType? choice;

  RoundPair({
    required this.askerId,
    required this.answererId,
    this.choice,
  });
}
