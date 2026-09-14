import 'dart:math' as math;

import 'package:nba_fantasy_stats_react_app/models/career_highs.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/models/season_stats.dart';
import 'package:nba_fantasy_stats_react_app/models/stats_summary.dart';

/// Pure Dart port of `src/utils/statsCalculations.ts` — no Flutter
/// dependencies (Step 8 of FLUTTER_PLAN.md).

/// Mirrors `calculateStatisticalMilestones`.
StatisticalMilestones calculateStatisticalMilestones(List<GameStats> games) {
  final playedGames = games.where((g) => !g.isAbsent).toList();

  final points = <String, int>{
    '10+': 0,
    '20+': 0,
    '30+': 0,
    '35+': 0,
    '40+': 0,
    '50+': 0,
    '60+': 0,
    '70+': 0,
    '80+': 0,
    '100+': 0,
    '100++': 0,
  };
  final assists = <String, int>{
    '5+': 0,
    '10+': 0,
    '15+': 0,
    '20+': 0,
    '25+': 0,
  };
  final rebounds = <String, int>{
    '5+': 0,
    '10+': 0,
    '15+': 0,
    '20+': 0,
    '25+': 0,
  };
  final blocks = <String, int>{'2+': 0, '5+': 0, '10+': 0};
  final steals = <String, int>{'2+': 0, '5+': 0, '10+': 0};

  final eliteGames = <EliteLineGame>[];
  var quadrupleDoubles = 0;
  var quintupleDoubles = 0;
  var doubleQuintupleDoubles = 0;

  for (final game in playedGames) {
    // Points milestones - cumulative counting.
    if (game.points >= 10) points['10+'] = points['10+']! + 1;
    if (game.points >= 20) points['20+'] = points['20+']! + 1;
    if (game.points >= 30) points['30+'] = points['30+']! + 1;
    if (game.points >= 35) points['35+'] = points['35+']! + 1;
    if (game.points >= 40) points['40+'] = points['40+']! + 1;
    if (game.points >= 50) points['50+'] = points['50+']! + 1;
    if (game.points >= 60) points['60+'] = points['60+']! + 1;
    if (game.points >= 70) points['70+'] = points['70+']! + 1;
    if (game.points >= 80) points['80+'] = points['80+']! + 1;
    if (game.points >= 100) points['100+'] = points['100+']! + 1;
    if (game.points > 100) points['100++'] = points['100++']! + 1;

    // Assists milestones - cumulative counting.
    if (game.assists >= 5) assists['5+'] = assists['5+']! + 1;
    if (game.assists >= 10) assists['10+'] = assists['10+']! + 1;
    if (game.assists >= 15) assists['15+'] = assists['15+']! + 1;
    if (game.assists >= 20) assists['20+'] = assists['20+']! + 1;
    if (game.assists >= 25) assists['25+'] = assists['25+']! + 1;

    // Rebounds milestones - cumulative counting.
    if (game.rebounds >= 5) rebounds['5+'] = rebounds['5+']! + 1;
    if (game.rebounds >= 10) rebounds['10+'] = rebounds['10+']! + 1;
    if (game.rebounds >= 15) rebounds['15+'] = rebounds['15+']! + 1;
    if (game.rebounds >= 20) rebounds['20+'] = rebounds['20+']! + 1;
    if (game.rebounds >= 25) rebounds['25+'] = rebounds['25+']! + 1;

    // Blocks milestones - cumulative counting.
    if (game.blocks >= 2) blocks['2+'] = blocks['2+']! + 1;
    if (game.blocks >= 5) blocks['5+'] = blocks['5+']! + 1;
    if (game.blocks >= 10) blocks['10+'] = blocks['10+']! + 1;

    // Steals milestones - cumulative counting.
    if (game.steals >= 2) steals['2+'] = steals['2+']! + 1;
    if (game.steals >= 5) steals['5+'] = steals['5+']! + 1;
    if (game.steals >= 10) steals['10+'] = steals['10+']! + 1;

    // Ultra-rare all-around lines: each game counts once, at the best tier
    // it reaches.
    final statLine = [
      game.points,
      game.assists,
      game.rebounds,
      game.blocks,
      game.steals,
    ];
    final doubleDigitStats = statLine.where((v) => v >= 10).length;
    final twentyPlusStats = statLine.where((v) => v >= 20).length;

    String? tier;
    if (twentyPlusStats == 5) {
      tier = 'doubleQuintuple';
    } else if (doubleDigitStats == 5) {
      tier = 'quintuple';
    } else if (doubleDigitStats >= 4) {
      tier = 'quadruple';
    }

    if (tier != null) {
      eliteGames.add(
        EliteLineGame(
          tier: tier,
          date: game.date,
          points: game.points,
          assists: game.assists,
          rebounds: game.rebounds,
          blocks: game.blocks,
          steals: game.steals,
        ),
      );
      if (tier == 'quadruple') {
        quadrupleDoubles++;
      } else if (tier == 'quintuple') {
        quintupleDoubles++;
      } else {
        doubleQuintupleDoubles++;
      }
    }
  }

  return StatisticalMilestones(
    points: points,
    assists: assists,
    rebounds: rebounds,
    blocks: blocks,
    steals: steals,
    eliteLines: EliteLines(
      quadrupleDoubles: quadrupleDoubles,
      quintupleDoubles: quintupleDoubles,
      doubleQuintupleDoubles: doubleQuintupleDoubles,
      games: eliteGames,
    ),
  );
}

/// Result of `calculateStreaks`.
class Streaks {
  final int current;
  final int longestWin;
  final int longestLoss;

  const Streaks({
    required this.current,
    required this.longestWin,
    required this.longestLoss,
  });
}

/// Mirrors `calculateStreaks`. `current` is positive for a win streak,
/// negative for a loss streak, 0 for no games.
Streaks calculateStreaks(List<GameStats> games) {
  var currentStreak = 0;
  var longestWinStreak = 0;
  var longestLossStreak = 0;
  var tempWinStreak = 0;
  var tempLossStreak = 0;

  for (var i = games.length - 1; i >= 0; i--) {
    if (currentStreak == 0) {
      currentStreak = games[i].won ? 1 : -1;
    } else {
      if ((currentStreak > 0 && games[i].won) ||
          (currentStreak < 0 && !games[i].won)) {
        currentStreak = currentStreak > 0
            ? currentStreak + 1
            : currentStreak - 1;
      } else {
        break;
      }
    }
  }

  for (final game in games) {
    if (game.won) {
      tempWinStreak++;
      tempLossStreak = 0;
      longestWinStreak = math.max(longestWinStreak, tempWinStreak);
    } else {
      tempLossStreak++;
      tempWinStreak = 0;
      longestLossStreak = math.max(longestLossStreak, tempLossStreak);
    }
  }

  return Streaks(
    current: currentStreak,
    longestWin: longestWinStreak,
    longestLoss: longestLossStreak,
  );
}

/// Mirrors `calculateAverages` — returns zeros when the player played no
/// games (absences are excluded).
StatAverages calculateAverages(List<GameStats> games) {
  final playedGames = games.where((g) => !g.isAbsent).toList();
  if (playedGames.isEmpty) {
    return const StatAverages(
      points: 0,
      assists: 0,
      rebounds: 0,
      blocks: 0,
      steals: 0,
      minutes: 0,
    );
  }

  double avg(int Function(GameStats) pick) =>
      playedGames.map(pick).reduce((a, b) => a + b) / playedGames.length;

  return StatAverages(
    points: avg((g) => g.points),
    assists: avg((g) => g.assists),
    rebounds: avg((g) => g.rebounds),
    blocks: avg((g) => g.blocks),
    steals: avg((g) => g.steals),
    minutes: avg((g) => g.minutes),
  );
}

/// Mirrors `calculateCareerHighs`.
CareerHighs calculateCareerHighs(List<GameStats> allGames) {
  final playedGames = allGames.where((g) => !g.isAbsent).toList();
  if (playedGames.isEmpty) {
    return const CareerHighs(
      points: 0,
      assists: 0,
      rebounds: 0,
      blocks: 0,
      steals: 0,
      minutes: 0,
      doubleDoubles: 0,
      tripleDoubles: 0,
    );
  }

  int maxOf(int Function(GameStats) pick) =>
      playedGames.map(pick).reduce(math.max);

  return CareerHighs(
    points: maxOf((g) => g.points),
    assists: maxOf((g) => g.assists),
    rebounds: maxOf((g) => g.rebounds),
    blocks: maxOf((g) => g.blocks),
    steals: maxOf((g) => g.steals),
    minutes: maxOf((g) => g.minutes),
    doubleDoubles: playedGames.where((g) => g.isDoubleDouble).length,
    tripleDoubles: playedGames.where((g) => g.isTripleDouble).length,
  );
}

/// Mirrors `checkPlayoffQualification`.
bool checkPlayoffQualification(List<GameStats> regularSeasonGames) {
  final wins = regularSeasonGames.where((g) => g.won).length;
  final totalGames = regularSeasonGames.length;
  final losses = totalGames - wins;

  // The app does not model full conference standings, so a completed
  // non-losing 82-game season is the minimum simulated qualification.
  return totalGames >= 82 && wins >= losses;
}

/// Mirrors `getSeasonYear` — NBA seasons run October to June of the next
/// year, e.g. 2025-10-15 -> `2025-26`.
String getSeasonYear(String dateString) {
  final date = DateTime.parse(dateString);
  final year = date.year;
  final month = date.month;

  if (month >= 9) {
    return '$year-${(year + 1).toString().substring(2)}';
  } else {
    return '${year - 1}-${year.toString().substring(2)}';
  }
}

/// Mirrors `organizeSeasonStats` — groups games into seasons (most recent
/// first) and aggregates each season's numbers.
List<SeasonStats> organizeSeasonStats(List<GameStats> allGames) {
  final seasonsMap = <String, List<GameStats>>{};

  for (final game in allGames) {
    final seasonYear = game.season.isNotEmpty
        ? game.season
        : getSeasonYear(game.date);
    seasonsMap.putIfAbsent(seasonYear, () => []).add(game);
  }

  final seasons = <SeasonStats>[];

  seasonsMap.forEach((seasonYear, games) {
    final regularSeasonGames = games
        .where((g) => g.gameType == GameType.regular)
        .toList();
    final playoffGames = games
        .where((g) => g.gameType == GameType.playoffs)
        .toList();
    final playedGames = games.where((g) => !g.isAbsent).toList();
    final missedGames = games.where((g) => g.isAbsent).toList();

    final wins = games.where((g) => g.won).length;
    final losses = games.length - wins;
    final playerWins = playedGames.where((g) => g.won).length;
    final playerLosses = playedGames.length - playerWins;
    final missedWins = missedGames.where((g) => g.won).length;
    final missedLosses = missedGames.length - missedWins;
    final playoffWins = playoffGames.where((g) => g.won).length;
    final playoffLosses = playoffGames.length - playoffWins;

    final streaks = calculateStreaks(games);
    final doubleDoubles = games.where((g) => g.isDoubleDouble).length;
    final tripleDoubles = games.where((g) => g.isTripleDouble).length;
    final buzzerBeaters = games.where((g) => g.isBuzzerBeater).length;
    final regularBuzzerBeaters = regularSeasonGames
        .where((g) => g.isBuzzerBeater)
        .length;
    final playoffBuzzerBeaters = playoffGames
        .where((g) => g.isBuzzerBeater)
        .length;

    seasons.add(
      SeasonStats(
        seasonYear: seasonYear,
        gamesPlayed: games.length,
        playerGamesPlayed: playedGames.length,
        gamesMissed: missedGames.length,
        regularSeasonGames: regularSeasonGames,
        playoffGames: playoffGames,
        wins: wins,
        losses: losses,
        teamWins: wins,
        teamLosses: losses,
        playerWins: playerWins,
        playerLosses: playerLosses,
        missedWins: missedWins,
        missedLosses: missedLosses,
        playoffWins: playoffWins,
        playoffLosses: playoffLosses,
        madePlayoffs: checkPlayoffQualification(regularSeasonGames),
        playoffSeries: const [],
        currentStreak: streaks.current,
        longestWinStreak: streaks.longestWin,
        longestLossStreak: streaks.longestLoss,
        doubleDoubles: doubleDoubles,
        tripleDoubles: tripleDoubles,
        careerDoubleDoubles: allGames.where((g) => g.isDoubleDouble).length,
        careerTripleDoubles: allGames.where((g) => g.isTripleDouble).length,
        buzzerBeaters: buzzerBeaters,
        regularBuzzerBeaters: regularBuzzerBeaters,
        playoffBuzzerBeaters: playoffBuzzerBeaters,
        careerBuzzerBeaters: allGames.where((g) => g.isBuzzerBeater).length,
        statisticalMilestones: calculateStatisticalMilestones(games),
      ),
    );
  });

  seasons.sort((a, b) => b.seasonYear.compareTo(a.seasonYear));
  return seasons;
}

/// Mirrors `calculateStatsSummary`.
StatsSummary calculateStatsSummary(List<GameStats> allGames) {
  final regularSeasonGames = allGames
      .where((g) => g.gameType == GameType.regular)
      .toList();
  final playoffGames = allGames
      .where((g) => g.gameType == GameType.playoffs)
      .toList();
  final playedGames = allGames.where((g) => !g.isAbsent).toList();
  final missedGames = allGames.where((g) => g.isAbsent).toList();

  final wins = allGames.where((g) => g.won).length;
  final losses = allGames.length - wins;
  final playerWins = playedGames.where((g) => g.won).length;
  final playerLosses = playedGames.length - playerWins;
  final missedWins = missedGames.where((g) => g.won).length;
  final missedLosses = missedGames.length - missedWins;
  final playoffWins = playoffGames.where((g) => g.won).length;
  final playoffLosses = playoffGames.length - playoffWins;

  final streaks = calculateStreaks(allGames);

  return StatsSummary(
    wins: wins,
    losses: losses,
    teamWins: wins,
    teamLosses: losses,
    playerWins: playerWins,
    playerLosses: playerLosses,
    missedWins: missedWins,
    missedLosses: missedLosses,
    gamesPlayed: playedGames.length,
    gamesMissed: missedGames.length,
    playoffWins: playoffWins,
    playoffLosses: playoffLosses,
    playerWinPercentage: playedGames.isNotEmpty
        ? playerWins / playedGames.length
        : 0,
    missedWinPercentage: missedGames.isNotEmpty
        ? missedWins / missedGames.length
        : 0,
    currentStreak: streaks.current,
    longestWinStreak: streaks.longestWin,
    longestLossStreak: streaks.longestLoss,
    winPercentage: allGames.isNotEmpty ? wins / allGames.length : 0,
    playoffWinPercentage: playoffGames.isNotEmpty
        ? playoffWins / playoffGames.length
        : 0,
    buzzerBeaters: allGames.where((g) => g.isBuzzerBeater).length,
    regularBuzzerBeaters: regularSeasonGames
        .where((g) => g.isBuzzerBeater)
        .length,
    playoffBuzzerBeaters: playoffGames.where((g) => g.isBuzzerBeater).length,
    averages: calculateAverages(allGames),
    seasonAverages: calculateAverages(regularSeasonGames),
    playoffAverages: calculateAverages(playoffGames),
  );
}
