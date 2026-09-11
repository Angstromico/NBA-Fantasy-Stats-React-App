import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/utils/stats_calculations.dart';

GameStats _game({
  int points = 0,
  int assists = 0,
  int rebounds = 0,
  int blocks = 0,
  int steals = 0,
  int minutes = 0,
  bool won = false,
  bool isAbsent = false,
  bool isDoubleDouble = false,
  bool isTripleDouble = false,
  bool isBuzzerBeater = false,
  GameType gameType = GameType.regular,
  String season = '2025-26',
  String date = '2026-01-15',
}) =>
    GameStats(
      id: '${points}_${assists}_${rebounds}_${blocks}_${steals}_$won$season$date',
      date: date,
      team: 'MyTeam',
      opponent: 'Rivals',
      gameNumber: 1,
      gameType: gameType,
      absenceType: isAbsent ? AbsenceType.rest : AbsenceType.none,
      isAbsent: isAbsent,
      points: points,
      assists: assists,
      rebounds: rebounds,
      blocks: blocks,
      steals: steals,
      minutes: minutes,
      won: won,
      isDoubleDouble: isDoubleDouble,
      isTripleDouble: isTripleDouble,
      isBuzzerBeater: isBuzzerBeater,
      season: season,
    );

void main() {
  group('calculateAverages', () {
    test('computes per-game averages over played games', () {
      final games = [
        _game(points: 20, assists: 5, rebounds: 8, minutes: 36),
        _game(points: 10, assists: 5, rebounds: 4, minutes: 30),
      ];

      final avgs = calculateAverages(games);

      expect(avgs.points, 15.0);
      expect(avgs.assists, 5.0);
      expect(avgs.rebounds, 6.0);
      expect(avgs.minutes, 33.0);
    });

    test('excludes absent games', () {
      final games = [
        _game(points: 20, minutes: 36),
        _game(isAbsent: true, points: 99),
      ];

      final avgs = calculateAverages(games);

      expect(avgs.points, 20.0);
      expect(avgs.minutes, 36.0);
    });

    test('returns zeros for empty and all-absent input', () {
      expect(calculateAverages([]).points, 0);
      expect(calculateAverages([_game(isAbsent: true)]).points, 0);
    });
  });

  group('calculateStreaks', () {
    test('returns zeros with no games', () {
      final s = calculateStreaks([]);
      expect(s.current, 0);
      expect(s.longestWin, 0);
      expect(s.longestLoss, 0);
    });

    test('positive current streak counts trailing wins', () {
      final s = calculateStreaks([
        _game(won: false),
        _game(won: true),
        _game(won: true),
        _game(won: true),
      ]);
      expect(s.current, 3);
    });

    test('negative current streak counts trailing losses', () {
      final s = calculateStreaks([
        _game(won: true),
        _game(won: true),
        _game(won: false),
        _game(won: false),
      ]);
      expect(s.current, -2);
    });

    test('tracks longest win and loss streaks independently', () {
      final s = calculateStreaks([
        _game(won: true),
        _game(won: true),
        _game(won: true),
        _game(won: false),
        _game(won: false),
        _game(won: true),
      ]);
      expect(s.longestWin, 3);
      expect(s.longestLoss, 2);
      expect(s.current, 1);
    });
  });

  group('calculateCareerHighs', () {
    test('returns max per category plus double/triple counts', () {
      final games = [
        _game(points: 30, assists: 12, rebounds: 4, isDoubleDouble: true),
        _game(points: 22, assists: 2, rebounds: 14, minutes: 45, isDoubleDouble: true, isTripleDouble: true),
      ];

      final highs = calculateCareerHighs(games);

      expect(highs.points, 30);
      expect(highs.assists, 12);
      expect(highs.rebounds, 14);
      expect(highs.minutes, 45);
      expect(highs.doubleDoubles, 2);
      expect(highs.tripleDoubles, 1);
    });

    test('returns zeros with no played games', () {
      final highs = calculateCareerHighs([_game(isAbsent: true)]);
      expect(highs.points, 0);
      expect(highs.doubleDoubles, 0);
    });
  });

  group('calculateStatisticalMilestones', () {
    test('counts cumulative thresholds', () {
      final games = [
        _game(points: 35, assists: 6, rebounds: 6, blocks: 2, steals: 2),
        _game(points: 12),
      ];

      final m = calculateStatisticalMilestones(games);

      expect(m.points['10+'], 2);
      expect(m.points['20+'], 1);
      expect(m.points['30+'], 1);
      expect(m.points['35+'], 1);
      expect(m.points['40+'], 0);
      expect(m.assists['5+'], 1);
      expect(m.blocks['2+'], 1);
      expect(m.steals['2+'], 1);
    });

    test('treats 100+ as >= 100 and 100++ as strictly above', () {
      final m = calculateStatisticalMilestones([
        _game(points: 100),
        _game(points: 101),
        _game(points: 99),
      ]);
      expect(m.points['100+'], 2);
      expect(m.points['100++'], 1);
    });

    test('excludes absent games', () {
      final m = calculateStatisticalMilestones([_game(points: 50, isAbsent: true)]);
      expect(m.points['50+'], 0);
    });

    test('classifies quadruple double at the best tier only', () {
      final m = calculateStatisticalMilestones([
        _game(points: 12, assists: 10, rebounds: 11, blocks: 10, steals: 2),
      ]);
      expect(m.eliteLines.quadrupleDoubles, 1);
      expect(m.eliteLines.quintupleDoubles, 0);
      expect(m.eliteLines.games.single.tier, 'quadruple');
    });

    test('classifies quintuple and double quintuple', () {
      final m = calculateStatisticalMilestones([
        _game(points: 10, assists: 10, rebounds: 10, blocks: 10, steals: 10),
        _game(points: 20, assists: 20, rebounds: 20, blocks: 20, steals: 20),
      ]);
      expect(m.eliteLines.quintupleDoubles, 1);
      expect(m.eliteLines.doubleQuintupleDoubles, 1);
      expect(m.eliteLines.games.map((g) => g.tier),
          ['quintuple', 'doubleQuintuple']);
    });

    test('records game details on elite lines', () {
      final m = calculateStatisticalMilestones([
        _game(
          points: 12, assists: 10, rebounds: 11, blocks: 10, steals: 2,
          date: '2026-02-02',
        ),
      ]);
      final entry = m.eliteLines.games.single;
      expect(entry.date, '2026-02-02');
      expect(entry.points, 12);
      expect(entry.assists, 10);
      expect(entry.rebounds, 11);
      expect(entry.blocks, 10);
      expect(entry.steals, 2);
    });
  });

  group('checkPlayoffQualification', () {
    test('requires 82 games and a non-losing record', () {
      final winning = List.generate(82, (_) => _game(won: true));
      expect(checkPlayoffQualification(winning), isTrue);

      final even = List.generate(82, (_) => _game(won: true))
        ..[81] = _game(won: false);
      expect(checkPlayoffQualification(even), isTrue);

      final short = List.generate(81, (_) => _game(won: true));
      expect(checkPlayoffQualification(short), isFalse);

      final losing = List.generate(82, (i) => _game(won: i < 40));
      expect(checkPlayoffQualification(losing), isFalse);
    });
  });

  group('getSeasonYear', () {
    test('maps October onward to the next year', () {
      expect(getSeasonYear('2025-10-15'), '2025-26');
      expect(getSeasonYear('2025-12-01'), '2025-26');
    });

    test('maps January to June back to the previous year', () {
      expect(getSeasonYear('2026-01-15'), '2025-26');
      expect(getSeasonYear('2026-06-30'), '2025-26');
    });

    test('September belongs to the new season', () {
      expect(getSeasonYear('2025-09-30'), '2025-26');
    });
  });

  group('organizeSeasonStats', () {
    test('groups by season label and aggregates records', () {
      final games = [
        _game(won: true, points: 20, season: '2024-25'),
        _game(won: false, points: 12, season: '2024-25'),
        _game(won: true, points: 30, season: '2025-26'),
      ];

      final seasons = organizeSeasonStats(games);

      // Sorted most recent first.
      expect(seasons.map((s) => s.seasonYear).toList(), ['2025-26', '2024-25']);
      expect(seasons.last.wins, 1);
      expect(seasons.last.losses, 1);
      expect(seasons.last.gamesPlayed, 2);
      expect(seasons.last.careerDoubleDoubles, 0);
    });

    test('derives milestones per season', () {
      final seasons = organizeSeasonStats([
        _game(points: 40, season: '2025-26'),
        _game(points: 12, season: '2025-26'),
      ]);
      expect(seasons.single.statisticalMilestones.points['40+'], 1);
      expect(seasons.single.statisticalMilestones.points['10+'], 2);
    });

    test('returns empty list for no games', () {
      expect(organizeSeasonStats([]), isEmpty);
    });
  });

  group('calculateStatsSummary', () {
    test('computes career-wide summary across game types', () {
      final games = [
        _game(won: true, points: 30, gameType: GameType.regular, isBuzzerBeater: true),
        _game(won: false, points: 10, gameType: GameType.regular),
        _game(won: true, points: 25, gameType: GameType.playoffs),
        _game(isAbsent: true, won: true, gameType: GameType.regular),
      ];

      final s = calculateStatsSummary(games);

      expect(s.wins, 3);
      expect(s.losses, 1);
      expect(s.gamesPlayed, 3);
      expect(s.gamesMissed, 1);
      expect(s.playerWins, 2);
      expect(s.playerLosses, 1);
      expect(s.missedWins, 1);
      expect(s.missedLosses, 0);
      expect(s.playoffWins, 1);
      expect(s.playoffLosses, 0);
      expect(s.buzzerBeaters, 1);
      expect(s.regularBuzzerBeaters, 1);
      expect(s.playoffBuzzerBeaters, 0);
      // Trailing games: playoff win + absent-but-won game = 2-game streak.
      expect(s.currentStreak, 2);
    });

    test('computes win percentages safely with zero divisions', () {
      final s = calculateStatsSummary([]);
      expect(s.winPercentage, 0);
      expect(s.playerWinPercentage, 0);
      expect(s.missedWinPercentage, 0);
      expect(s.playoffWinPercentage, 0);
    });

    test('splits season vs playoff averages', () {
      final games = [
        _game(points: 20, gameType: GameType.regular),
        _game(points: 40, gameType: GameType.playoffs),
      ];

      final s = calculateStatsSummary(games);

      expect(s.seasonAverages.points, 20.0);
      expect(s.playoffAverages.points, 40.0);
      expect(s.averages.points, 30.0);
    });
  });
}
