import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/models/playoff_series.dart';
import 'package:nba_fantasy_stats_react_app/models/season_awards.dart';

/// Per-stat-category milestone counts — mirrors the shape of
/// `statisticalMilestones.points` etc. in `src/interfaces/index.ts`
/// (keys are threshold labels like `'10+'`, values are counts).
typedef StatMilestoneCounts = Map<String, int>;

/// One ultra-rare stat-line game — mirrors the `games` entries of `eliteLines`.
class EliteLineGame {
  final String tier; // 'quadruple' | 'quintuple' | 'doubleQuintuple'
  final String date;
  final int points;
  final int assists;
  final int rebounds;
  final int blocks;
  final int steals;

  const EliteLineGame({
    required this.tier,
    required this.date,
    required this.points,
    required this.assists,
    required this.rebounds,
    required this.blocks,
    required this.steals,
  });

  factory EliteLineGame.fromJson(Map<String, dynamic> json) => EliteLineGame(
        tier: json['tier'] as String,
        date: json['date'] as String,
        points: json['points'] as int,
        assists: json['assists'] as int,
        rebounds: json['rebounds'] as int,
        blocks: json['blocks'] as int,
        steals: json['steals'] as int,
      );

  Map<String, dynamic> toJson() => {
        'tier': tier,
        'date': date,
        'points': points,
        'assists': assists,
        'rebounds': rebounds,
        'blocks': blocks,
        'steals': steals,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EliteLineGame &&
          tier == other.tier &&
          date == other.date &&
          points == other.points &&
          assists == other.assists &&
          rebounds == other.rebounds &&
          blocks == other.blocks &&
          steals == other.steals;

  @override
  int get hashCode =>
      Object.hash(tier, date, points, assists, rebounds, blocks, steals);
}

/// Ultra-rare all-around stat lines — mirrors `statisticalMilestones.eliteLines`.
class EliteLines {
  final int quadrupleDoubles;
  final int quintupleDoubles;
  final int doubleQuintupleDoubles;
  final List<EliteLineGame> games;

  const EliteLines({
    required this.quadrupleDoubles,
    required this.quintupleDoubles,
    required this.doubleQuintupleDoubles,
    required this.games,
  });

  factory EliteLines.fromJson(Map<String, dynamic> json) => EliteLines(
        quadrupleDoubles: json['quadrupleDoubles'] as int,
        quintupleDoubles: json['quintupleDoubles'] as int,
        doubleQuintupleDoubles: json['doubleQuintupleDoubles'] as int,
        games: (json['games'] as List<dynamic>)
            .map((g) => EliteLineGame.fromJson(g as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'quadrupleDoubles': quadrupleDoubles,
        'quintupleDoubles': quintupleDoubles,
        'doubleQuintupleDoubles': doubleQuintupleDoubles,
        'games': games.map((g) => g.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EliteLines &&
          quadrupleDoubles == other.quadrupleDoubles &&
          quintupleDoubles == other.quintupleDoubles &&
          doubleQuintupleDoubles == other.doubleQuintupleDoubles &&
          _listEquals(games, other.games);

  @override
  int get hashCode => Object.hash(quadrupleDoubles, quintupleDoubles,
      doubleQuintupleDoubles, Object.hashAll(games));
}

/// Statistical milestones — mirrors `SeasonStats['statisticalMilestones']`
/// (the exported `StatisticalMilestones` type in `src/interfaces/index.ts`).
class StatisticalMilestones {
  final StatMilestoneCounts points;
  final StatMilestoneCounts assists;
  final StatMilestoneCounts rebounds;
  final StatMilestoneCounts blocks;
  final StatMilestoneCounts steals;
  final EliteLines eliteLines;

  const StatisticalMilestones({
    required this.points,
    required this.assists,
    required this.rebounds,
    required this.blocks,
    required this.steals,
    required this.eliteLines,
  });

  factory StatisticalMilestones.fromJson(Map<String, dynamic> json) =>
      StatisticalMilestones(
        points: _readCounts(json['points']),
        assists: _readCounts(json['assists']),
        rebounds: _readCounts(json['rebounds']),
        blocks: _readCounts(json['blocks']),
        steals: _readCounts(json['steals']),
        eliteLines:
            EliteLines.fromJson(json['eliteLines'] as Map<String, dynamic>),
      );

  static StatMilestoneCounts _readCounts(Object? raw) =>
      (raw as Map<Object?, Object?>).map(
        (k, v) => MapEntry(k! as String, v as int),
      );

  Map<String, dynamic> toJson() => {
        'points': points,
        'assists': assists,
        'rebounds': rebounds,
        'blocks': blocks,
        'steals': steals,
        'eliteLines': eliteLines.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatisticalMilestones &&
          _mapEquals(points, other.points) &&
          _mapEquals(assists, other.assists) &&
          _mapEquals(rebounds, other.rebounds) &&
          _mapEquals(blocks, other.blocks) &&
          _mapEquals(steals, other.steals) &&
          eliteLines == other.eliteLines;

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(points.entries),
        Object.hashAllUnordered(assists.entries),
        Object.hashAllUnordered(rebounds.entries),
        Object.hashAllUnordered(blocks.entries),
        Object.hashAllUnordered(steals.entries),
        eliteLines,
      );
}

/// One NBA season of aggregated stats — mirrors `SeasonStats` in
/// `src/interfaces/index.ts`.
class SeasonStats {
  final String seasonYear;
  final int gamesPlayed;
  final int playerGamesPlayed;
  final int gamesMissed;
  final List<GameStats> regularSeasonGames;
  final List<GameStats> playoffGames;
  final int wins;
  final int losses;
  final int teamWins;
  final int teamLosses;
  final int playerWins;
  final int playerLosses;
  final int missedWins;
  final int missedLosses;
  final int playoffWins;
  final int playoffLosses;
  final bool madePlayoffs;
  final List<PlayoffSeries> playoffSeries;
  final int currentStreak;
  final int longestWinStreak;
  final int longestLossStreak;
  final int doubleDoubles;
  final int tripleDoubles;
  final int careerDoubleDoubles;
  final int careerTripleDoubles;
  final int buzzerBeaters;
  final int regularBuzzerBeaters;
  final int playoffBuzzerBeaters;
  final int careerBuzzerBeaters;
  final StatisticalMilestones statisticalMilestones;
  final SeasonAwards? seasonAwards;

  const SeasonStats({
    required this.seasonYear,
    required this.gamesPlayed,
    required this.playerGamesPlayed,
    required this.gamesMissed,
    required this.regularSeasonGames,
    required this.playoffGames,
    required this.wins,
    required this.losses,
    required this.teamWins,
    required this.teamLosses,
    required this.playerWins,
    required this.playerLosses,
    required this.missedWins,
    required this.missedLosses,
    required this.playoffWins,
    required this.playoffLosses,
    required this.madePlayoffs,
    required this.playoffSeries,
    required this.currentStreak,
    required this.longestWinStreak,
    required this.longestLossStreak,
    required this.doubleDoubles,
    required this.tripleDoubles,
    required this.careerDoubleDoubles,
    required this.careerTripleDoubles,
    required this.buzzerBeaters,
    required this.regularBuzzerBeaters,
    required this.playoffBuzzerBeaters,
    required this.careerBuzzerBeaters,
    required this.statisticalMilestones,
    this.seasonAwards,
  });

  factory SeasonStats.fromJson(Map<String, dynamic> json) => SeasonStats(
        seasonYear: json['seasonYear'] as String,
        gamesPlayed: json['gamesPlayed'] as int,
        playerGamesPlayed: json['playerGamesPlayed'] as int,
        gamesMissed: json['gamesMissed'] as int,
        regularSeasonGames: _readGames(json['regularSeasonGames']),
        playoffGames: _readGames(json['playoffGames']),
        wins: json['wins'] as int,
        losses: json['losses'] as int,
        teamWins: json['teamWins'] as int,
        teamLosses: json['teamLosses'] as int,
        playerWins: json['playerWins'] as int,
        playerLosses: json['playerLosses'] as int,
        missedWins: json['missedWins'] as int,
        missedLosses: json['missedLosses'] as int,
        playoffWins: json['playoffWins'] as int,
        playoffLosses: json['playoffLosses'] as int,
        madePlayoffs: json['madePlayoffs'] as bool,
        playoffSeries: (json['playoffSeries'] as List<dynamic>? ?? [])
            .map((s) =>
                PlayoffSeries.fromJson(s as Map<String, dynamic>))
            .toList(),
        currentStreak: json['currentStreak'] as int,
        longestWinStreak: json['longestWinStreak'] as int,
        longestLossStreak: json['longestLossStreak'] as int,
        doubleDoubles: json['doubleDoubles'] as int,
        tripleDoubles: json['tripleDoubles'] as int,
        careerDoubleDoubles: json['careerDoubleDoubles'] as int,
        careerTripleDoubles: json['careerTripleDoubles'] as int,
        buzzerBeaters: json['buzzerBeaters'] as int,
        regularBuzzerBeaters: json['regularBuzzerBeaters'] as int,
        playoffBuzzerBeaters: json['playoffBuzzerBeaters'] as int,
        careerBuzzerBeaters: json['careerBuzzerBeaters'] as int,
        statisticalMilestones: StatisticalMilestones.fromJson(
            json['statisticalMilestones'] as Map<String, dynamic>),
        seasonAwards: json['seasonAwards'] == null
            ? null
            : SeasonAwards.fromJson(
                json['seasonAwards'] as Map<String, dynamic>),
      );

  static List<GameStats> _readGames(Object? raw) => (raw as List<dynamic>? ?? [])
      .map((g) => GameStats.fromJson(g as Map<String, dynamic>))
      .toList();

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
        'seasonYear': seasonYear,
        'gamesPlayed': gamesPlayed,
        'playerGamesPlayed': playerGamesPlayed,
        'gamesMissed': gamesMissed,
        'regularSeasonGames':
            regularSeasonGames.map((g) => g.toJson()).toList(),
        'playoffGames': playoffGames.map((g) => g.toJson()).toList(),
        'wins': wins,
        'losses': losses,
        'teamWins': teamWins,
        'teamLosses': teamLosses,
        'playerWins': playerWins,
        'playerLosses': playerLosses,
        'missedWins': missedWins,
        'missedLosses': missedLosses,
        'playoffWins': playoffWins,
        'playoffLosses': playoffLosses,
        'madePlayoffs': madePlayoffs,
        'playoffSeries': playoffSeries.map((s) => s.toJson()).toList(),
        'currentStreak': currentStreak,
        'longestWinStreak': longestWinStreak,
        'longestLossStreak': longestLossStreak,
        'doubleDoubles': doubleDoubles,
        'tripleDoubles': tripleDoubles,
        'careerDoubleDoubles': careerDoubleDoubles,
        'careerTripleDoubles': careerTripleDoubles,
        'buzzerBeaters': buzzerBeaters,
        'regularBuzzerBeaters': regularBuzzerBeaters,
        'playoffBuzzerBeaters': playoffBuzzerBeaters,
        'careerBuzzerBeaters': careerBuzzerBeaters,
        'statisticalMilestones': statisticalMilestones.toJson(),
      };
    // Optional fields are omitted when null, matching JSON.stringify in the
    // React app (undefined properties are dropped, not written as null).
    if (seasonAwards != null) {
      json['seasonAwards'] = seasonAwards!.toJson();
    }
    return json;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonStats && _jsonEquals(this, other);

  @override
  int get hashCode => Object.hash(seasonYear, gamesPlayed, gamesMissed, wins,
      losses, madePlayoffs, currentStreak, buzzerBeaters);
}

bool _listEquals(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals(Map<String, int> a, Map<String, int> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (a[key] != b[key]) return false;
  }
  return true;
}

/// Deep equality via JSON round-trip — pragmatic for large aggregate models.
bool _jsonEquals(SeasonStats a, SeasonStats b) =>
    a.toJson().toString() == b.toJson().toString();
