/// One playoff series — mirrors `PlayoffSeries` in `src/interfaces/index.ts`.
class PlayoffSeries {
  final int round;
  final String opponent;
  final int gamesWon;
  final int gamesLost;
  final bool isComplete;

  const PlayoffSeries({
    required this.round,
    required this.opponent,
    required this.gamesWon,
    required this.gamesLost,
    required this.isComplete,
  });

  factory PlayoffSeries.fromJson(Map<String, dynamic> json) => PlayoffSeries(
    round: json['round'] as int,
    opponent: json['opponent'] as String,
    gamesWon: json['gamesWon'] as int,
    gamesLost: json['gamesLost'] as int,
    isComplete: json['isComplete'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'round': round,
    'opponent': opponent,
    'gamesWon': gamesWon,
    'gamesLost': gamesLost,
    'isComplete': isComplete,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayoffSeries &&
          round == other.round &&
          opponent == other.opponent &&
          gamesWon == other.gamesWon &&
          gamesLost == other.gamesLost &&
          isComplete == other.isComplete;

  @override
  int get hashCode =>
      Object.hash(round, opponent, gamesWon, gamesLost, isComplete);
}
