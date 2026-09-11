import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/models/career_highs.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/models/playoff_series.dart';
import 'package:nba_fantasy_stats_react_app/models/season_awards.dart';
import 'package:nba_fantasy_stats_react_app/models/season_stats.dart';
import 'package:nba_fantasy_stats_react_app/models/stats_summary.dart';
import 'package:nba_fantasy_stats_react_app/models/team.dart';
import 'package:nba_fantasy_stats_react_app/models/user.dart';

GameStats _sampleGame({bool withSeries = false}) => GameStats(
      id: 'g1',
      date: '2026-03-15',
      team: 'MyTeam',
      opponent: 'Rivals',
      gameNumber: 42,
      gameType: GameType.playoffs,
      absenceType: AbsenceType.notCalledUp,
      isAbsent: false,
      points: 27,
      assists: 8,
      rebounds: 11,
      blocks: 2,
      steals: 3,
      minutes: 36,
      won: true,
      isDoubleDouble: true,
      isTripleDouble: false,
      isBuzzerBeater: true,
      playoffSeries:
          withSeries ? const PlayoffSeries(round: 1, opponent: 'Rivals', gamesWon: 4, gamesLost: 2, isComplete: true) : null,
      season: '2025-2026',
    );

void main() {
  group('GameStats JSON round-trip', () {
    test('preserves all fields', () {
      final game = _sampleGame(withSeries: true);
      final decoded = GameStats.fromJson(
          jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>);
      expect(decoded, game);
    });

    test('omits playoffSeries when null, like JSON.stringify', () {
      final json = _sampleGame().toJson();
      expect(json.containsKey('playoffSeries'), isFalse);
    });

    test('parses snake_case absence values from React storage', () {
      final decoded = GameStats.fromJson({
        ..._sampleGame().toJson(),
        'absenceType': 'lower_division',
      });
      expect(decoded.absenceType, AbsenceType.lowerDivision);
    });
  });

  group('StatisticalMilestones JSON round-trip', () {
    test('preserves threshold keys and elite lines', () {
      const milestones = StatisticalMilestones(
        points: {'10+': 5, '20+': 2, '30+': 1},
        assists: {'5+': 4},
        rebounds: {'5+': 6, '10+': 2},
        blocks: {'2+': 3},
        steals: {'2+': 1},
        eliteLines: EliteLines(
          quadrupleDoubles: 1,
          quintupleDoubles: 0,
          doubleQuintupleDoubles: 0,
          games: [
            EliteLineGame(
              tier: 'quadruple',
              date: '2026-02-01',
              points: 12,
              assists: 10,
              rebounds: 14,
              blocks: 11,
              steals: 10,
            ),
          ],
        ),
      );
      final decoded = StatisticalMilestones.fromJson(
          jsonDecode(jsonEncode(milestones.toJson())) as Map<String, dynamic>);
      expect(decoded, milestones);
      expect(decoded.points['20+'], 2);
    });
  });

  group('SeasonStats JSON round-trip', () {
    test('preserves nested games, series, and milestones', () {
      final season = SeasonStats(
        seasonYear: '2025-2026',
        gamesPlayed: 10,
        playerGamesPlayed: 9,
        gamesMissed: 1,
        regularSeasonGames: [_sampleGame()],
        playoffGames: [_sampleGame(withSeries: true)],
        wins: 7,
        losses: 3,
        teamWins: 7,
        teamLosses: 3,
        playerWins: 6,
        playerLosses: 3,
        missedWins: 1,
        missedLosses: 0,
        playoffWins: 2,
        playoffLosses: 1,
        madePlayoffs: true,
        playoffSeries: const [
          PlayoffSeries(round: 1, opponent: 'Rivals', gamesWon: 4, gamesLost: 2, isComplete: true),
        ],
        currentStreak: 3,
        longestWinStreak: 5,
        longestLossStreak: 2,
        doubleDoubles: 4,
        tripleDoubles: 1,
        careerDoubleDoubles: 20,
        careerTripleDoubles: 2,
        buzzerBeaters: 1,
        regularBuzzerBeaters: 0,
        playoffBuzzerBeaters: 1,
        careerBuzzerBeaters: 3,
        statisticalMilestones: const StatisticalMilestones(
          points: {'10+': 9},
          assists: {'5+': 5},
          rebounds: {'5+': 7},
          blocks: {'2+': 2},
          steals: {'2+': 4},
          eliteLines: EliteLines(
            quadrupleDoubles: 0,
            quintupleDoubles: 0,
            doubleQuintupleDoubles: 0,
            games: [],
          ),
        ),
        seasonAwards: const SeasonAwards(
          mvp: AwardWinner(player: 'Star', team: 'MyTeam'),
          champion: Champion(team: 'MyTeam', record: '16-5'),
          scoringChampion: ScoringChampion(player: 'Star', team: 'MyTeam', ppg: 31.2),
          defensivePlayerOfYear: AwardWinner(player: 'Wall', team: 'Rivals'),
          winningestTeam: WinningestTeam(team: 'MyTeam', record: '60-22', wins: 60),
        ),
      );

      final decoded = SeasonStats.fromJson(
          jsonDecode(jsonEncode(season.toJson())) as Map<String, dynamic>);
      expect(decoded.seasonYear, season.seasonYear);
      expect(decoded.regularSeasonGames.first, season.regularSeasonGames.first);
      expect(decoded.playoffGames.first, season.playoffGames.first);
      expect(decoded.playoffSeries.first, season.playoffSeries.first);
      expect(decoded.seasonAwards, season.seasonAwards);
      expect(decoded.statisticalMilestones.points['10+'], 9);
    });

    test('omits seasonAwards when null', () {
      final json = SeasonStats(
        seasonYear: '2025-2026',
        gamesPlayed: 0,
        playerGamesPlayed: 0,
        gamesMissed: 0,
        regularSeasonGames: const [],
        playoffGames: const [],
        wins: 0,
        losses: 0,
        teamWins: 0,
        teamLosses: 0,
        playerWins: 0,
        playerLosses: 0,
        missedWins: 0,
        missedLosses: 0,
        playoffWins: 0,
        playoffLosses: 0,
        madePlayoffs: false,
        playoffSeries: const [],
        currentStreak: 0,
        longestWinStreak: 0,
        longestLossStreak: 0,
        doubleDoubles: 0,
        tripleDoubles: 0,
        careerDoubleDoubles: 0,
        careerTripleDoubles: 0,
        buzzerBeaters: 0,
        regularBuzzerBeaters: 0,
        playoffBuzzerBeaters: 0,
        careerBuzzerBeaters: 0,
        statisticalMilestones: const StatisticalMilestones(
          points: {},
          assists: {},
          rebounds: {},
          blocks: {},
          steals: {},
          eliteLines: EliteLines(
            quadrupleDoubles: 0,
            quintupleDoubles: 0,
            doubleQuintupleDoubles: 0,
            games: [],
          ),
        ),
      ).toJson();
      expect(json.containsKey('seasonAwards'), isFalse);
    });
  });

  group('Simple models JSON round-trip', () {
    test('User preserves credentials', () {
      const user = User(username: 'manuel', hashedPassword: '\$2b\$12\$hash');
      final decoded =
          User.fromJson(jsonDecode(jsonEncode(user.toJson())) as Map<String, dynamic>);
      expect(decoded, user);
    });

    test('Team preserves identity', () {
      const team = Team(
          id: 't1', name: 'Lakers', city: 'Los Angeles', conference: 'Western', division: 'Pacific');
      final decoded =
          Team.fromJson(jsonDecode(jsonEncode(team.toJson())) as Map<String, dynamic>);
      expect(decoded, team);
    });

    test('CareerHighs preserves values', () {
      const highs = CareerHighs(
          points: 55,
          assists: 18,
          rebounds: 22,
          blocks: 7,
          steals: 6,
          minutes: 46,
          doubleDoubles: 30,
          tripleDoubles: 3);
      final decoded = CareerHighs.fromJson(
          jsonDecode(jsonEncode(highs.toJson())) as Map<String, dynamic>);
      expect(decoded, highs);
    });

    test('StatsSummary preserves averages and percentages', () {
      final summary = StatsSummary(
        wins: 40,
        losses: 20,
        teamWins: 45,
        teamLosses: 15,
        playerWins: 38,
        playerLosses: 18,
        missedWins: 7,
        missedLosses: 2,
        gamesPlayed: 60,
        gamesMissed: 9,
        playoffWins: 8,
        playoffLosses: 5,
        playerWinPercentage: 0.679,
        missedWinPercentage: 0.778,
        currentStreak: 4,
        longestWinStreak: 9,
        longestLossStreak: 3,
        winPercentage: 0.667,
        playoffWinPercentage: 0.615,
        buzzerBeaters: 2,
        regularBuzzerBeaters: 1,
        playoffBuzzerBeaters: 1,
        averages: const StatAverages(
            points: 24.3, assists: 7.1, rebounds: 9.8, blocks: 1.4, steals: 1.9, minutes: 35.2),
        seasonAverages: const StatAverages(
            points: 25.1, assists: 7.4, rebounds: 10.0, blocks: 1.5, steals: 2.0, minutes: 35.8),
        playoffAverages: const StatAverages(
            points: 27.7, assists: 8.0, rebounds: 11.1, blocks: 1.8, steals: 2.2, minutes: 38.0),
      );
      final decoded = StatsSummary.fromJson(
          jsonDecode(jsonEncode(summary.toJson())) as Map<String, dynamic>);
      expect(decoded, summary);
    });
  });
}
