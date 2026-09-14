import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/data/nba_data.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/utils/game_progression.dart';

GameStats _game({
  required int gameNumber,
  required GameType gameType,
  required bool won,
  bool isAbsent = false,
  String team = 'Boston Celtics',
  String season = '2024-2025',
}) => GameStats(
  id: 'g$gameNumber$gameType$won',
  date: '2025-01-15',
  team: team,
  opponent: 'Rivals',
  gameNumber: gameNumber,
  gameType: gameType,
  absenceType: isAbsent ? AbsenceType.rest : AbsenceType.none,
  isAbsent: isAbsent,
  points: isAbsent ? 0 : 20,
  assists: 0,
  rebounds: 0,
  blocks: 0,
  steals: 0,
  minutes: 30,
  won: won,
  isDoubleDouble: false,
  isTripleDouble: false,
  isBuzzerBeater: false,
  season: season,
);

void main() {
  group('NBA data layer', () {
    test('exposes 30 teams and 17 seasons (2008-2025)', () {
      expect(nbaTeams, hasLength(30));
      expect(getAvailableSeasons(), hasLength(17));
      expect(getAvailableSeasons().first, '2008-2009');
      expect(getAvailableSeasons().last, '2024-2025');
    });

    test('resolves teams by City Name label', () {
      final celtics = teamByLabel('Boston Celtics');
      expect(celtics, isNotNull);
      expect(celtics!.id, 'bos');
      expect(celtics.conference, 'Eastern');
      expect(teamByLabel('Nowhere_Nones'), isNull);
    });

    test('generates an 82-game regular-season schedule', () {
      final schedule = getTeamRegularSeasonSchedule('bos', '2024-2025');
      expect(schedule, hasLength(regularSeasonGameCount));
      expect(schedule.every((g) => !g.isPlayoff), isTrue);
      // Dates are strictly non-decreasing.
      for (var i = 1; i < schedule.length; i++) {
        expect(
          schedule[i].date.compareTo(schedule[i - 1].date),
          greaterThanOrEqualTo(0),
        );
      }
    });

    test('generates a 21-game playoff window in three rounds', () {
      final playoffs = getTeamPlayoffSchedule('bos', '2024-2025');
      expect(playoffs, hasLength(21));
      expect(playoffs.where((g) => g.playoffRound == 1), hasLength(7));
      expect(playoffs.where((g) => g.playoffRound == 2), hasLength(7));
      expect(playoffs.where((g) => g.playoffRound == 3), hasLength(7));
    });

    test('schedules are stable across calls and deterministic', () {
      final a = getTeamSchedule('lal', '2019-2020');
      final b = getTeamSchedule('lal', '2019-2020');
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].date, b[i].date);
        expect(a[i].opponent, b[i].opponent);
      }
    });

    test('getNextSeason walks forward and returns null at the end', () {
      expect(getNextSeason('2008-2009'), '2009-2010');
      expect(getNextSeason('2023-2024'), '2024-2025');
      expect(getNextSeason('2024-2025'), isNull);
      expect(getNextSeason('1900-1901'), isNull);
    });

    test('every season carries complete awards data', () {
      for (final season in seasonsData) {
        expect(season.awards.mvp.player, isNotEmpty);
        expect(season.awards.champion.team, isNotEmpty);
        expect(season.awards.scoringChampion.ppg, greaterThan(0));
        expect(season.awards.winningestTeam.wins, inInclusiveRange(40, 74));
      }
    });
  });

  group('game progression', () {
    test('starts at regular season game 1 with no games', () {
      final next = computeNextGame(const [], 'Boston Celtics', '2024-2025');
      expect(next.gameType, GameType.regular);
      expect(next.gameNumber, 1);
      expect(next.message, isNull);
    });

    test('advances the game number as regular games accumulate', () {
      final games = List.generate(
        10,
        (i) => _game(
          gameNumber: i + 1,
          gameType: GameType.regular,
          won: i % 2 == 0,
        ),
      );
      final next = computeNextGame(games, 'Boston Celtics', '2024-2025');
      expect(next.gameType, GameType.regular);
      expect(next.gameNumber, 11);
    });

    test('moves to the next season when the season ends without playoffs', () {
      // 82 games with a losing record — no playoff qualification.
      final games = List.generate(
        regularSeasonGameCount,
        (i) =>
            _game(gameNumber: i + 1, gameType: GameType.regular, won: i < 40),
      );
      final next = computeNextGame(games, 'Boston Celtics', '2024-2025');
      expect(next.gameType, GameType.regular);
      expect(next.message, contains('complete without playoff qualification'));
    });

    test('enters the playoffs after a qualifying 82-game season', () {
      // 82 games with a winning record → playoffs, game 1.
      final games = List.generate(
        regularSeasonGameCount,
        (i) =>
            _game(gameNumber: i + 1, gameType: GameType.regular, won: i < 50),
      );
      final next = computeNextGame(games, 'Boston Celtics', '2024-2025');
      expect(next.gameType, GameType.playoffs);
      expect(next.gameNumber, 1);
    });

    test('tracks an active playoff series round by round', () {
      final regular = List.generate(
        regularSeasonGameCount,
        (i) =>
            _game(gameNumber: i + 1, gameType: GameType.regular, won: i < 50),
      );
      // Round 1: 2 wins then a loss — series still open.
      final playoffs = [
        _game(gameNumber: 1, gameType: GameType.playoffs, won: true),
        _game(gameNumber: 2, gameType: GameType.playoffs, won: true),
        _game(gameNumber: 3, gameType: GameType.playoffs, won: false),
      ];
      final progression = getPlayoffProgression(
        [...regular, ...playoffs],
        'Boston Celtics',
        '2024-2025',
      );
      expect(progression.status, ProgressionStatus.active);
      expect(progression.round, 1);
      expect(progression.nextGameNumber, 4);

      final next = computeNextGame(
        [...regular, ...playoffs],
        'Boston Celtics',
        '2024-2025',
      );
      expect(next.gameType, GameType.playoffs);
      expect(next.gameNumber, 4);
    });

    test('advances seasons after elimination', () {
      final regular = List.generate(
        regularSeasonGameCount,
        (i) =>
            _game(gameNumber: i + 1, gameType: GameType.regular, won: i < 50),
      );
      // Four losses in round 1 → eliminated.
      final playoffs = List.generate(
        4,
        (i) =>
            _game(gameNumber: i + 1, gameType: GameType.playoffs, won: false),
      );
      // Use a season with a successor in the data.
      GameStats relabel(GameStats g) => GameStats(
        id: g.id,
        date: g.date,
        team: g.team,
        opponent: g.opponent,
        gameNumber: g.gameNumber,
        gameType: g.gameType,
        absenceType: g.absenceType,
        isAbsent: g.isAbsent,
        points: g.points,
        assists: g.assists,
        rebounds: g.rebounds,
        blocks: g.blocks,
        steals: g.steals,
        minutes: g.minutes,
        won: g.won,
        isDoubleDouble: g.isDoubleDouble,
        isTripleDouble: g.isTripleDouble,
        isBuzzerBeater: g.isBuzzerBeater,
        season: '2023-2024',
      );

      final next = computeNextGame(
        [...regular, ...playoffs].map(relabel).toList(),
        'Boston Celtics',
        '2023-2024',
      );
      expect(next.gameType, GameType.regular);
      expect(next.message, contains('ended in round 1'));
      expect(next.message, contains('Advanced to 2024-2025'));
    });    test('filterPlayableGames blocks non-first-round games before the run starts', () {
        // Games 1-7 of the generated playoff schedule are round 1; game 8
        // belongs to round 2 and must be rejected while the run has not started.
        final incoming = [
          _game(gameNumber: 8, gameType: GameType.playoffs, won: true),
        ];
        expect(filterPlayableGames(const [], incoming), isEmpty);
      },
    );

    test('filterPlayableGames accepts open-run games in order', () {
      final incoming = [
        _game(gameNumber: 1, gameType: GameType.playoffs, won: true),
      ];
      expect(filterPlayableGames(const [], incoming), hasLength(1));
    });

    test('filterPlayableGames never blocks regular-season games', () {
      final incoming = [
        _game(gameNumber: 1, gameType: GameType.regular, won: false),
        _game(gameNumber: 2, gameType: GameType.regular, won: true),
      ];
      expect(filterPlayableGames(const [], incoming), hasLength(2));
    });

    test('round for a game falls back to ceil(gameNumber / 7)', () {
      expect(playoffRoundForGame('Boston Celtics', '2024-2025', 1), 1);
      expect(playoffRoundForGame('Boston Celtics', '2024-2025', 7), 1);
      expect(playoffRoundForGame('Boston Celtics', '2024-2025', 8), 2);
    });
  });
}
