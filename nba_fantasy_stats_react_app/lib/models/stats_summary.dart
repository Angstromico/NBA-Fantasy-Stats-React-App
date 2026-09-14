/// Aggregate season statistics — mirrors `StatsSummary` in `src/interfaces/index.ts`.
class StatsSummary {
  final int wins;
  final int losses;
  final int teamWins;
  final int teamLosses;
  final int playerWins;
  final int playerLosses;
  final int missedWins;
  final int missedLosses;
  final int gamesPlayed;
  final int gamesMissed;
  final int playoffWins;
  final int playoffLosses;
  final double playerWinPercentage;
  final double missedWinPercentage;
  final int currentStreak;
  final int longestWinStreak;
  final int longestLossStreak;
  final double winPercentage;
  final double playoffWinPercentage;
  final int buzzerBeaters;
  final int regularBuzzerBeaters;
  final int playoffBuzzerBeaters;
  final StatAverages averages;
  final StatAverages seasonAverages;
  final StatAverages playoffAverages;

  const StatsSummary({
    required this.wins,
    required this.losses,
    required this.teamWins,
    required this.teamLosses,
    required this.playerWins,
    required this.playerLosses,
    required this.missedWins,
    required this.missedLosses,
    required this.gamesPlayed,
    required this.gamesMissed,
    required this.playoffWins,
    required this.playoffLosses,
    required this.playerWinPercentage,
    required this.missedWinPercentage,
    required this.currentStreak,
    required this.longestWinStreak,
    required this.longestLossStreak,
    required this.winPercentage,
    required this.playoffWinPercentage,
    required this.buzzerBeaters,
    required this.regularBuzzerBeaters,
    required this.playoffBuzzerBeaters,
    required this.averages,
    required this.seasonAverages,
    required this.playoffAverages,
  });

  factory StatsSummary.fromJson(Map<String, dynamic> json) => StatsSummary(
    wins: json['wins'] as int,
    losses: json['losses'] as int,
    teamWins: json['teamWins'] as int,
    teamLosses: json['teamLosses'] as int,
    playerWins: json['playerWins'] as int,
    playerLosses: json['playerLosses'] as int,
    missedWins: json['missedWins'] as int,
    missedLosses: json['missedLosses'] as int,
    gamesPlayed: json['gamesPlayed'] as int,
    gamesMissed: json['gamesMissed'] as int,
    playoffWins: json['playoffWins'] as int,
    playoffLosses: json['playoffLosses'] as int,
    playerWinPercentage: (json['playerWinPercentage'] as num).toDouble(),
    missedWinPercentage: (json['missedWinPercentage'] as num).toDouble(),
    currentStreak: json['currentStreak'] as int,
    longestWinStreak: json['longestWinStreak'] as int,
    longestLossStreak: json['longestLossStreak'] as int,
    winPercentage: (json['winPercentage'] as num).toDouble(),
    playoffWinPercentage: (json['playoffWinPercentage'] as num).toDouble(),
    buzzerBeaters: json['buzzerBeaters'] as int,
    regularBuzzerBeaters: json['regularBuzzerBeaters'] as int,
    playoffBuzzerBeaters: json['playoffBuzzerBeaters'] as int,
    averages: StatAverages.fromJson(json['averages'] as Map<String, dynamic>),
    seasonAverages: StatAverages.fromJson(
      json['seasonAverages'] as Map<String, dynamic>,
    ),
    playoffAverages: StatAverages.fromJson(
      json['playoffAverages'] as Map<String, dynamic>,
    ),
  );

  Map<String, dynamic> toJson() => {
    'wins': wins,
    'losses': losses,
    'teamWins': teamWins,
    'teamLosses': teamLosses,
    'playerWins': playerWins,
    'playerLosses': playerLosses,
    'missedWins': missedWins,
    'missedLosses': missedLosses,
    'gamesPlayed': gamesPlayed,
    'gamesMissed': gamesMissed,
    'playoffWins': playoffWins,
    'playoffLosses': playoffLosses,
    'playerWinPercentage': playerWinPercentage,
    'missedWinPercentage': missedWinPercentage,
    'currentStreak': currentStreak,
    'longestWinStreak': longestWinStreak,
    'longestLossStreak': longestLossStreak,
    'winPercentage': winPercentage,
    'playoffWinPercentage': playoffWinPercentage,
    'buzzerBeaters': buzzerBeaters,
    'regularBuzzerBeaters': regularBuzzerBeaters,
    'playoffBuzzerBeaters': playoffBuzzerBeaters,
    'averages': averages.toJson(),
    'seasonAverages': seasonAverages.toJson(),
    'playoffAverages': playoffAverages.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsSummary &&
          wins == other.wins &&
          losses == other.losses &&
          teamWins == other.teamWins &&
          teamLosses == other.teamLosses &&
          playerWins == other.playerWins &&
          playerLosses == other.playerLosses &&
          missedWins == other.missedWins &&
          missedLosses == other.missedLosses &&
          gamesPlayed == other.gamesPlayed &&
          gamesMissed == other.gamesMissed &&
          playoffWins == other.playoffWins &&
          playoffLosses == other.playoffLosses &&
          playerWinPercentage == other.playerWinPercentage &&
          missedWinPercentage == other.missedWinPercentage &&
          currentStreak == other.currentStreak &&
          longestWinStreak == other.longestWinStreak &&
          longestLossStreak == other.longestLossStreak &&
          winPercentage == other.winPercentage &&
          playoffWinPercentage == other.playoffWinPercentage &&
          buzzerBeaters == other.buzzerBeaters &&
          regularBuzzerBeaters == other.regularBuzzerBeaters &&
          playoffBuzzerBeaters == other.playoffBuzzerBeaters &&
          averages == other.averages &&
          seasonAverages == other.seasonAverages &&
          playoffAverages == other.playoffAverages;

  @override
  int get hashCode => Object.hash(
    Object.hash(
      wins,
      losses,
      teamWins,
      teamLosses,
      playerWins,
      playerLosses,
      missedWins,
      missedLosses,
      gamesPlayed,
      gamesMissed,
      playoffWins,
      playoffLosses,
      playerWinPercentage,
      missedWinPercentage,
      currentStreak,
      longestWinStreak,
      longestLossStreak,
    ),
    winPercentage,
    playoffWinPercentage,
    buzzerBeaters,
    regularBuzzerBeaters,
    playoffBuzzerBeaters,
    averages,
    seasonAverages,
    playoffAverages,
  );
}

/// Averages block used by `StatsSummary` — one of `averages`,
/// `seasonAverages`, `playoffAverages` in `src/interfaces/index.ts`.
class StatAverages {
  final double points;
  final double assists;
  final double rebounds;
  final double blocks;
  final double steals;
  final double minutes;

  const StatAverages({
    required this.points,
    required this.assists,
    required this.rebounds,
    required this.blocks,
    required this.steals,
    required this.minutes,
  });

  factory StatAverages.fromJson(Map<String, dynamic> json) => StatAverages(
    points: (json['points'] as num).toDouble(),
    assists: (json['assists'] as num).toDouble(),
    rebounds: (json['rebounds'] as num).toDouble(),
    blocks: (json['blocks'] as num).toDouble(),
    steals: (json['steals'] as num).toDouble(),
    minutes: (json['minutes'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'points': points,
    'assists': assists,
    'rebounds': rebounds,
    'blocks': blocks,
    'steals': steals,
    'minutes': minutes,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatAverages &&
          points == other.points &&
          assists == other.assists &&
          rebounds == other.rebounds &&
          blocks == other.blocks &&
          steals == other.steals &&
          minutes == other.minutes;

  @override
  int get hashCode =>
      Object.hash(points, assists, rebounds, blocks, steals, minutes);
}
