class Player {
  final String id;
  final String name;
  int score;
  bool isHost;

  Player({
    required this.id,
    required this.name,
    this.score = 0,
    this.isHost = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'score': score,
        'isHost': isHost,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        score: json['score'] as int? ?? 0,
        isHost: json['isHost'] as bool? ?? false,
      );

  Player copyWith({
    String? id,
    String? name,
    int? score,
    bool? isHost,
  }) =>
      Player(
        id: id ?? this.id,
        name: name ?? this.name,
        score: score ?? this.score,
        isHost: isHost ?? this.isHost,
      );
}
