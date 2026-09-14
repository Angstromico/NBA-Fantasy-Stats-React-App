import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/data/nba_leaderboards.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/utils/leaderboard_calculations.dart';

GameStats _game({
  int points = 0,
  int assists = 0,
  int rebounds = 0,
  int blocks = 0,
  int steals = 0,
  bool won = false,
  bool isAbsent = false,
  bool isTripleDouble = false,
  GameType gameType = GameType.regular,
  String season = '2025-26',
  String team = 'MyTeam',
  String date = '2026-01-15',
  int gameNumber = 1,
}) => GameStats(
  id: '${date}_${gameNumber}_${points}_$assists$season$team',
  date: date,
  team: team,
  opponent: 'Rivals',
  gameNumber: gameNumber,
  gameType: gameType,
  absenceType: isAbsent ? AbsenceType.rest : AbsenceType.none,
  isAbsent: isAbsent,
  points: points,
  assists: assists,
  rebounds: rebounds,
  blocks: blocks,
  steals: steals,
  minutes: 0,
  won: won,
  isDoubleDouble: false,
  isTripleDouble: isTripleDouble,
  isBuzzerBeater: false,
  season: season,
);

LeaderboardDef _board(String id) =>
    leaderboards.firstWhere((board) => board.id == id);

void main() {
  group('cutoffs and ranking', () {
    test('returns the 20th-best entry value as the cutoff', () {
      expect(getBoardCutoffValue(_board('sg-points')), 62);
      expect(getBoardCutoffValue(_board('sg-assists')), 23);
    });

    test('returns 0 for a board with fewer than 20 entries', () {
      const tiny = LeaderboardDef(
        id: 'tiny',
        group: LeaderboardGroup.career,
        title: 'Tiny',
        detail: 'd',
        unit: 'u',
        format: 'int',
        entries: [
          LeaderboardEntry(name: 'A', value: 5, context: 'c', sortKey: 'a'),
          LeaderboardEntry(name: 'B', value: 3, context: 'c', sortKey: 'b'),
        ],
      );
      expect(getBoardCutoffValue(tiny), 0);
    });

    test('rankAgainstEntries counts entries ranked above the mark', () {
      // 16 entries score above 62 and the three 62s with earlier dates
      // outrank a 2024 mark (Gervin 1978, Anthony 2014, Curry 2021).
      expect(rankAgainstEntries(_board('sg-points'), 62, '2024-01-22'), 20);
      // 100 outranks everything.
      expect(rankAgainstEntries(_board('sg-points'), 100, '1962-03-02'), 1);
    });

    test('ties on value break by earlier sortKey', () {
      final board = _board('sg-points');
      // 73 belongs to David Thompson (1978) and Luka Dončić (2024); the
      // earlier date ranks first.
      expect(rankAgainstEntries(board, 73, '1978-04-09'), 4);
      expect(rankAgainstEntries(board, 73, '2024-01-26'), 5);
    });
  });

  group('single-game boards', () {
    test('merges player games into the board and flags them', () {
      final view = buildLeaderboardViews([
        _game(points: 64, date: '2026-02-01'),
      ], 'manuel').firstWhere((v) => v.board.id == 'sg-points');

      expect(view.playerPerformances, hasLength(1));
      expect(view.playerPerformances.single.value, 64);
      // 13 performances score above 64 (100, 83, 81, two 73s, four 71s,
      // two 70s, 69, 68).
      expect(view.playerPerformances.single.rank, 14);
      expect(view.rows.any((row) => row.isPlayer && row.rank == 14), isTrue);
      expect(view.mark?.eligible, isTrue);
      expect(view.mark?.rank, 14);
    });

    test('excludes absent and playoff games', () {
      final view = buildLeaderboardViews([
        _game(points: 99, isAbsent: true),
        _game(points: 99, gameType: GameType.playoffs),
      ], 'manuel').firstWhere((v) => v.board.id == 'sg-points');

      expect(view.playerPerformances, isEmpty);
      expect(view.rows.every((row) => !row.isPlayer), isTrue);
    });

    test('sorts rows best-first with the player row merged in place', () {
      final view = buildLeaderboardViews([
        _game(points: 64, date: '2026-02-01'),
      ], 'manuel').firstWhere((v) => v.board.id == 'sg-points');

      final ranks = view.rows.map((row) => row.rank).toList();
      expect(ranks, List.generate(ranks.length, (i) => i + 1));
      for (var i = 1; i < view.rows.length; i++) {
        final a = view.rows[i - 1];
        final b = view.rows[i];
        expect(
          a.value >= b.value,
          isTrue,
          reason: '${a.value} should not sort below ${b.value}',
        );
      }
    });
  });

  group('season-average boards', () {
    test('aggregates per season and team with eligibility', () {
      final games = [
        ...List.generate(
          58,
          (i) => _game(
            points: 30,
            season: '2024-25',
            date: '2024-11-${(i % 28) + 1}',
          ),
        ),
        ...List.generate(
          10,
          (i) => _game(
            points: 40,
            season: '2025-26',
            date: '2025-11-${(i % 28) + 1}',
          ),
        ),
      ];

      final view = buildLeaderboardViews(
        games,
        'manuel',
      ).firstWhere((v) => v.board.id == 'season-ppg');

      // 30.0 ppg qualifies (58 games) but sits below the 33.53 top-20
      // cutoff, so it is reported as a mark rather than a board row; the
      // ineligible 40.0 ppg season never reaches the board.
      expect(view.playerPerformances, isEmpty);
      expect(view.mark?.eligible, isTrue);
      expect(view.mark?.value, 30.0);
      expect(view.mark?.context, '2024-25 season');
      expect(view.mark?.rank, 21); // all 20 entries rank above 30.0
    });

    test('rounds averages to two decimals', () {
      final games = List.generate(
        58,
        (i) => _game(points: i % 2 == 0 ? 30 : 31, season: '2025-26'),
      );
      final view = buildLeaderboardViews(
        games,
        'manuel',
      ).firstWhere((v) => v.board.id == 'season-ppg');
      expect(view.mark?.value, 30.5);
    });
  });

  group('career and team boards', () {
    test('counts career triple doubles as a single candidate', () {
      final games = [
        _game(points: 12, assists: 10, rebounds: 11, isTripleDouble: true),
        _game(points: 12, assists: 10, rebounds: 11, isTripleDouble: true),
        _game(points: 20),
      ];
      final view = buildLeaderboardViews(
        games,
        'manuel',
      ).firstWhere((v) => v.board.id == 'career-triple-doubles');

      expect(view.playerPerformances, isEmpty); // 2 < 29 cutoff
      expect(view.mark?.value, 2);
      expect(view.mark?.eligible, isTrue);
      expect(view.mark?.rank, greaterThan(20));
    });

    test('team-season-wins requires a full 82-game season', () {
      final games = [
        ...List.generate(82, (i) => _game(won: true, season: '2024-25')),
        ...List.generate(40, (i) => _game(won: true, season: '2025-26')),
      ];
      final view = buildLeaderboardViews(
        games,
        'manuel',
      ).firstWhere((v) => v.board.id == 'team-season-wins');

      expect(view.playerPerformances, hasLength(1));
      expect(view.playerPerformances.single.value, 82);
      expect(view.playerPerformances.single.rank, 1);
    });
  });

  group('computeTopTwentyEntrances', () {
    test('flags regular-season games that crack a top-20 board', () {
      final entrances = computeTopTwentyEntrances([
        _game(points: 64, date: '2026-02-01'),
        _game(points: 25, date: '2026-02-02'),
      ]);

      expect(entrances.map((e) => e.boardId), contains('sg-points'));
      final points = entrances.firstWhere((e) => e.boardId == 'sg-points');
      expect(points.value, 64);
      expect(points.rank, 14);
      expect(points.adjective, 'point');
    });

    test('ignores absent and playoff games', () {
      expect(
        computeTopTwentyEntrances([
          _game(points: 99, isAbsent: true),
          _game(points: 99, gameType: GameType.playoffs),
        ]),
        isEmpty,
      );
    });

    test('sorts entrances best-first by value', () {
      final entrances = computeTopTwentyEntrances([
        _game(assists: 25, date: '2026-02-01'),
        _game(points: 64, date: '2026-02-02'),
      ]);
      expect(entrances.first.value, 64);
    });
  });

  group('formatBoardValue', () {
    test('formats decimal boards with two decimals', () {
      expect(formatBoardValue(30.5, _board('season-ppg')), '30.50');
      expect(formatBoardValue(64, _board('sg-points')), '64');
    });
  });

  group('board invariants across all 11 boards', () {
    test('every board yields a view and keeps ranks contiguous', () {
      final views = buildLeaderboardViews([
        _game(points: 64, assists: 25, rebounds: 31, blocks: 12, steals: 10),
      ], 'manuel');
      expect(views, hasLength(leaderboards.length));
      for (final view in views) {
        final ranks = view.rows.map((row) => row.rank).toList();
        expect(
          ranks,
          List.generate(ranks.length, (i) => i + 1),
          reason: 'board ${view.board.id} must keep ranks 1..n',
        );
      }
    });
  });
}
