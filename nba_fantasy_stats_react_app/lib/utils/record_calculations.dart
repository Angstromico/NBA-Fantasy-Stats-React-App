import 'package:nba_fantasy_stats_react_app/data/nba_records.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';

/// Dart port of `src/utils/recordCalculations.ts` — career-best streaks and
/// totals compared against real, verifiable NBA records.

/// Consecutive-games info for one scoring threshold.
class ScoringStreakInfo {
  const ScoringStreakInfo({
    required this.threshold,
    required this.current,
    required this.longest,
    this.longestStart,
    this.longestEnd,
  });

  final int threshold;
  final int current;
  final int longest;
  final String? longestStart;
  final String? longestEnd;
}

/// The tracked player's career-best streaks and totals.
class RecordAchievements {
  const RecordAchievements({
    required this.currentWinStreak,
    required this.longestWinStreak,
    this.longestWinStart,
    this.longestWinEnd,
    required this.currentLossStreak,
    required this.longestLossStreak,
    this.longestLossStart,
    this.longestLossEnd,
    required this.scoringStreaks,
    required this.singleGamePoints,
    this.singleGamePointsSeason,
    required this.seasonPoints,
    this.seasonPointsSeason,
    required this.seasonWins,
    this.seasonWinsSeason,
  });

  final int currentWinStreak;
  final int longestWinStreak;
  final String? longestWinStart;
  final String? longestWinEnd;
  final int currentLossStreak;
  final int longestLossStreak;
  final String? longestLossStart;
  final String? longestLossEnd;
  final List<ScoringStreakInfo> scoringStreaks;
  final int singleGamePoints;
  final String? singleGamePointsSeason;
  final int seasonPoints;
  final String? seasonPointsSeason;
  final int seasonWins;
  final String? seasonWinsSeason;
}

/// One record compared against the player's best — drives the "BROKEN" /
/// "remaining" UI states.
class RecordComparison {
  const RecordComparison({
    required this.record,
    required this.playerValue,
    this.currentValue,
    required this.broken,
    required this.remaining,
  });

  final NBARecord record;
  final int playerValue;

  /// Live streak value, present only for streak-based metrics.
  final int? currentValue;
  final bool broken;
  final num remaining;
}

const List<int> _scoringThresholds = [10, 20, 30, 40, 50];

List<GameStats> _sortGamesChronologically(List<GameStats> games) {
  final sorted = [...games];
  sorted.sort((a, b) {
    final dateCompare = a.date.compareTo(b.date);
    return dateCompare != 0 ? dateCompare : a.gameNumber - b.gameNumber;
  });
  return sorted;
}

/// Consecutive games with at least [threshold] points, based on games played
/// (a missed/absent game does not break a scoring streak).
ScoringStreakInfo calculateScoringStreak(List<GameStats> games, int threshold) {
  final playedGames = _sortGamesChronologically(
    games,
  ).where((game) => !game.isAbsent).toList();

  var current = 0;
  var longest = 0;
  var temp = 0;
  String? tempStart;
  String? longestStart;
  String? longestEnd;

  for (final game in playedGames) {
    if (game.points >= threshold) {
      if (temp == 0) {
        tempStart = game.date;
      }
      temp++;
      if (temp > longest) {
        longest = temp;
        longestStart = tempStart;
        longestEnd = game.date;
      }
    } else {
      temp = 0;
      tempStart = null;
    }
  }

  for (var i = playedGames.length - 1; i >= 0; i--) {
    if (playedGames[i].points >= threshold) {
      current++;
    } else {
      break;
    }
  }

  return ScoringStreakInfo(
    threshold: threshold,
    current: current,
    longest: longest,
    longestStart: longestStart,
    longestEnd: longestEnd,
  );
}

/// Win/loss streak info — current and longest, with date ranges.
class WinLossStreaks {
  const WinLossStreaks({
    required this.currentWinStreak,
    required this.longestWinStreak,
    this.longestWinStart,
    this.longestWinEnd,
    required this.currentLossStreak,
    required this.longestLossStreak,
    this.longestLossStart,
    this.longestLossEnd,
  });

  final int currentWinStreak;
  final int longestWinStreak;
  final String? longestWinStart;
  final String? longestWinEnd;
  final int currentLossStreak;
  final int longestLossStreak;
  final String? longestLossStart;
  final String? longestLossEnd;
}

WinLossStreaks calculateWinLossStreaks(List<GameStats> games) {
  final ordered = _sortGamesChronologically(games);

  var longestWinStreak = 0;
  String? longestWinStart;
  String? longestWinEnd;
  var longestLossStreak = 0;
  String? longestLossStart;
  String? longestLossEnd;
  var tempWin = 0;
  String? tempWinStart;
  var tempLoss = 0;
  String? tempLossStart;

  for (final game in ordered) {
    if (game.won) {
      if (tempWin == 0) {
        tempWinStart = game.date;
      }
      tempWin++;
      tempLoss = 0;
      if (tempWin > longestWinStreak) {
        longestWinStreak = tempWin;
        longestWinStart = tempWinStart;
        longestWinEnd = game.date;
      }
    } else {
      if (tempLoss == 0) {
        tempLossStart = game.date;
      }
      tempLoss++;
      tempWin = 0;
      if (tempLoss > longestLossStreak) {
        longestLossStreak = tempLoss;
        longestLossStart = tempLossStart;
        longestLossEnd = game.date;
      }
    }
  }

  var currentWinStreak = 0;
  for (var i = ordered.length - 1; i >= 0; i--) {
    if (ordered[i].won) {
      currentWinStreak++;
    } else {
      break;
    }
  }

  var currentLossStreak = 0;
  for (var i = ordered.length - 1; i >= 0; i--) {
    if (!ordered[i].won) {
      currentLossStreak++;
    } else {
      break;
    }
  }

  return WinLossStreaks(
    currentWinStreak: currentWinStreak,
    longestWinStreak: longestWinStreak,
    longestWinStart: longestWinStart,
    longestWinEnd: longestWinEnd,
    currentLossStreak: currentLossStreak,
    longestLossStreak: longestLossStreak,
    longestLossStart: longestLossStart,
    longestLossEnd: longestLossEnd,
  );
}

/// Aggregates the player's career-best streaks and totals from all logged
/// games.
RecordAchievements getRecordAchievements(List<GameStats> games) {
  final winLoss = calculateWinLossStreaks(games);

  final seasonTotals = <String, ({int points, int wins})>{};
  for (final game in games) {
    final season = game.season.isNotEmpty ? game.season : 'unknown';
    final existing = seasonTotals[season] ?? (points: 0, wins: 0);
    seasonTotals[season] = (
      points: existing.points + (game.isAbsent ? 0 : game.points),
      wins: existing.wins + (game.won ? 1 : 0),
    );
  }

  var singleGamePoints = 0;
  String? singleGamePointsSeason;
  var seasonPoints = 0;
  String? seasonPointsSeason;
  var seasonWins = 0;
  String? seasonWinsSeason;

  for (final game in games.where((game) => !game.isAbsent)) {
    if (game.points > singleGamePoints) {
      singleGamePoints = game.points;
      singleGamePointsSeason = game.season;
    }
  }

  seasonTotals.forEach((season, totals) {
    if (totals.points > seasonPoints) {
      seasonPoints = totals.points;
      seasonPointsSeason = season;
    }
    if (totals.wins > seasonWins) {
      seasonWins = totals.wins;
      seasonWinsSeason = season;
    }
  });

  return RecordAchievements(
    currentWinStreak: winLoss.currentWinStreak,
    longestWinStreak: winLoss.longestWinStreak,
    longestWinStart: winLoss.longestWinStart,
    longestWinEnd: winLoss.longestWinEnd,
    currentLossStreak: winLoss.currentLossStreak,
    longestLossStreak: winLoss.longestLossStreak,
    longestLossStart: winLoss.longestLossStart,
    longestLossEnd: winLoss.longestLossEnd,
    scoringStreaks: [
      for (final threshold in _scoringThresholds)
        calculateScoringStreak(games, threshold),
    ],
    singleGamePoints: singleGamePoints,
    singleGamePointsSeason: singleGamePointsSeason,
    seasonPoints: seasonPoints,
    seasonPointsSeason: seasonPointsSeason,
    seasonWins: seasonWins,
    seasonWinsSeason: seasonWinsSeason,
  );
}

ScoringStreakInfo _getScoringStreak(
  RecordAchievements achievements,
  int threshold,
) => achievements.scoringStreaks.firstWhere(
  (streak) => streak.threshold == threshold,
  orElse: () => ScoringStreakInfo(threshold: threshold, current: 0, longest: 0),
);

/// The player's all-time-best value for a record metric.
int getAchievementValue(
  RecordAchievements achievements,
  NBARecordMetric metric,
) => switch (metric) {
  NBARecordMetric.winStreak => achievements.longestWinStreak,
  NBARecordMetric.scoringStreak10 => _getScoringStreak(
    achievements,
    10,
  ).longest,
  NBARecordMetric.scoringStreak20 => _getScoringStreak(
    achievements,
    20,
  ).longest,
  NBARecordMetric.scoringStreak30 => _getScoringStreak(
    achievements,
    30,
  ).longest,
  NBARecordMetric.scoringStreak40 => _getScoringStreak(
    achievements,
    40,
  ).longest,
  NBARecordMetric.scoringStreak50 => _getScoringStreak(
    achievements,
    50,
  ).longest,
  NBARecordMetric.singleGamePoints => achievements.singleGamePoints,
  NBARecordMetric.seasonPoints => achievements.seasonPoints,
  NBARecordMetric.seasonWins => achievements.seasonWins,
};

/// The live (current-run) streak value for a metric, or null for
/// totals-based metrics.
int? getCurrentValue(RecordAchievements achievements, NBARecordMetric metric) =>
    switch (metric) {
      NBARecordMetric.winStreak => achievements.currentWinStreak,
      NBARecordMetric.scoringStreak10 => _getScoringStreak(
        achievements,
        10,
      ).current,
      NBARecordMetric.scoringStreak20 => _getScoringStreak(
        achievements,
        20,
      ).current,
      NBARecordMetric.scoringStreak30 => _getScoringStreak(
        achievements,
        30,
      ).current,
      NBARecordMetric.scoringStreak40 => _getScoringStreak(
        achievements,
        40,
      ).current,
      NBARecordMetric.scoringStreak50 => _getScoringStreak(
        achievements,
        50,
      ).current,
      _ => null,
    };

/// Compares every NBA record against the player's career-best marks.
List<RecordComparison> compareToNBARecords(RecordAchievements achievements) {
  final comparisons = <RecordComparison>[];
  for (final record in nbaRecords) {
    final playerValue = getAchievementValue(achievements, record.metric);
    final currentValue = getCurrentValue(achievements, record.metric);
    comparisons.add(
      RecordComparison(
        record: record,
        playerValue: playerValue,
        currentValue: currentValue,
        broken: playerValue >= record.value,
        remaining: playerValue >= record.value ? 0 : record.value - playerValue,
      ),
    );
  }
  return comparisons;
}

/// Comparisons where the player has already reached or broken the record.
List<RecordComparison> getBrokenRecords(List<GameStats> games) =>
    compareToNBARecords(
      getRecordAchievements(games),
    ).where((comparison) => comparison.broken).toList();
