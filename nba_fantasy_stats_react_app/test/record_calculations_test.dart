import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/data/nba_records.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/utils/record_calculations.dart';

GameStats _game({
  int points = 0,
  bool won = false,
  bool isAbsent = false,
  GameType gameType = GameType.regular,
  String season = '2025-26',
  String date = '2026-01-15',
  int gameNumber = 1,
}) => GameStats(
  id: '${date}_${gameNumber}_$points$won$season',
  date: date,
  team: 'MyTeam',
  opponent: 'Rivals',
  gameNumber: gameNumber,
  gameType: gameType,
  absenceType: isAbsent ? AbsenceType.rest : AbsenceType.none,
  isAbsent: isAbsent,
  points: points,
  assists: 0,
  rebounds: 0,
  blocks: 0,
  steals: 0,
  minutes: 0,
  won: won,
  isDoubleDouble: false,
  isTripleDouble: false,
  isBuzzerBeater: false,
  season: season,
);

void main() {
  group('calculateScoringStreak', () {
    test('counts current and longest streaks above the threshold', () {
      final info = calculateScoringStreak([
        _game(points: 12, date: '2026-01-01'),
        _game(points: 8, date: '2026-01-02'),
        _game(points: 20, date: '2026-01-03'),
        _game(points: 30, date: '2026-01-04'),
      ], 10);

      expect(info.threshold, 10);
      expect(info.current, 2);
      expect(info.longest, 2);
      expect(info.longestStart, '2026-01-03');
      expect(info.longestEnd, '2026-01-04');
    });

    test('absent games do not break a scoring streak', () {
      final info = calculateScoringStreak([
        _game(points: 12, date: '2026-01-01'),
        _game(isAbsent: true, date: '2026-01-02'),
        _game(points: 14, date: '2026-01-03'),
      ], 10);

      expect(info.current, 2);
      expect(info.longest, 2);
    });

    test('sorts by date then game number before measuring', () {
      final info = calculateScoringStreak([
        _game(points: 12, date: '2026-01-03', gameNumber: 1),
        _game(points: 12, date: '2026-01-01', gameNumber: 2),
      ], 10);

      expect(info.current, 2);
      expect(info.longestStart, '2026-01-01');
    });

    test('returns zero streaks with no qualifying games', () {
      final info = calculateScoringStreak([_game(points: 4)], 10);
      expect(info.current, 0);
      expect(info.longest, 0);
      expect(info.longestStart, isNull);
    });
  });

  group('calculateWinLossStreaks', () {
    test('tracks win and loss streaks with date ranges', () {
      final streaks = calculateWinLossStreaks([
        _game(won: true, date: '2026-01-01'),
        _game(won: true, date: '2026-01-02'),
        _game(won: false, date: '2026-01-03'),
        _game(won: false, date: '2026-01-04'),
        _game(won: false, date: '2026-01-05'),
        _game(won: true, date: '2026-01-06'),
      ]);

      expect(streaks.currentWinStreak, 1);
      expect(streaks.currentLossStreak, 0);
      expect(streaks.longestWinStreak, 2);
      expect(streaks.longestWinStart, '2026-01-01');
      expect(streaks.longestWinEnd, '2026-01-02');
      expect(streaks.longestLossStreak, 3);
      expect(streaks.longestLossStart, '2026-01-03');
      expect(streaks.longestLossEnd, '2026-01-05');
    });

    test('returns zero streaks with no games', () {
      final streaks = calculateWinLossStreaks([]);
      expect(streaks.currentWinStreak, 0);
      expect(streaks.longestWinStreak, 0);
      expect(streaks.longestLossStreak, 0);
    });
  });

  group('getRecordAchievements', () {
    test('finds single-game best and per-season totals/wins', () {
      final achievements = getRecordAchievements([
        _game(points: 44, won: true, season: '2024-25', date: '2025-01-01'),
        _game(points: 20, won: true, season: '2024-25', date: '2025-01-02'),
        _game(points: 61, won: false, season: '2025-26', date: '2026-01-01'),
      ]);

      expect(achievements.singleGamePoints, 61);
      expect(achievements.singleGamePointsSeason, '2025-26');
      expect(achievements.seasonPoints, 64); // 44 + 20
      expect(achievements.seasonPointsSeason, '2024-25');
      expect(achievements.seasonWins, 2);
      expect(achievements.seasonWinsSeason, '2024-25');
    });

    test('excludes absent games from points but keeps their wins', () {
      final achievements = getRecordAchievements([
        _game(isAbsent: true, won: true, points: 99, season: '2025-26'),
        _game(points: 10, won: false, season: '2025-26'),
      ]);

      expect(achievements.singleGamePoints, 10);
      expect(achievements.seasonPoints, 10);
      expect(achievements.seasonWins, 1);
    });

    test('provides all five scoring thresholds', () {
      final achievements = getRecordAchievements([_game(points: 55)]);
      expect(achievements.scoringStreaks.map((s) => s.threshold).toList(), [
        10,
        20,
        30,
        40,
        50,
      ]);
      expect(achievements.scoringStreaks.last.longest, 1);
    });
  });

  group('compareToNBARecords', () {
    test('marks broken records and computes remaining distance', () {
      // 34 straight wins breaks the 33-game record; 34 straight 30+ games
      // stays under Wilt's 65.
      final games = List.generate(
        34,
        (i) => _game(
          won: true,
          points: 32,
          date: '2026-01-${(i + 1).toString().padLeft(2, '0')}',
        ),
      );
      final achievements = getRecordAchievements(games);
      final comparisons = compareToNBARecords(achievements);

      final winStreak = comparisons.firstWhere(
        (c) => c.record.id == 'win-streak-33',
      );
      expect(winStreak.broken, isTrue);
      expect(winStreak.remaining, 0);
      expect(winStreak.currentValue, 34);

      final scoring30 = comparisons.firstWhere(
        (c) => c.record.id == 'scoring-streak-30',
      );
      expect(scoring30.broken, isFalse);
      expect(scoring30.remaining, 31); // 65 - 34
    });

    test('getBrokenRecords filters to broken comparisons only', () {
      final broken = getBrokenRecords(
        List.generate(34, (i) => _game(won: true, date: '2026-01-$i')),
      );
      expect(broken, isNotEmpty);
      expect(broken.every((c) => c.broken), isTrue);
      expect(broken.any((c) => c.record.id == 'win-streak-33'), isTrue);
    });

    test('no games means nothing is broken', () {
      expect(getBrokenRecords([]), isEmpty);
    });

    test('every record metric maps to an achievement value', () {
      final comparisons = compareToNBARecords(
        getRecordAchievements([_game(points: 12)]),
      );
      expect(comparisons.length, nbaRecords.length);
      for (final comparison in comparisons) {
        expect(
          comparison.remaining,
          comparison.record.value - comparison.playerValue,
        );
      }
    });
  });
}
