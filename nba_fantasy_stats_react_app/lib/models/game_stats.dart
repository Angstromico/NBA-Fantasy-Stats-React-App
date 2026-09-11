import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/playoff_series.dart';

/// Single game record — mirrors `GameStats` in `src/interfaces/index.ts`.
class GameStats {
  final String id;
  final String date;
  final String team;
  final String opponent;
  final int gameNumber;
  final GameType gameType;
  final AbsenceType absenceType;
  final bool isAbsent;
  final int points;
  final int assists;
  final int rebounds;
  final int blocks;
  final int steals;
  final int minutes;
  final bool won;
  final bool isDoubleDouble;
  final bool isTripleDouble;
  final bool isBuzzerBeater;
  final PlayoffSeries? playoffSeries;
  final String season;

  const GameStats({
    required this.id,
    required this.date,
    required this.team,
    required this.opponent,
    required this.gameNumber,
    required this.gameType,
    required this.absenceType,
    required this.isAbsent,
    required this.points,
    required this.assists,
    required this.rebounds,
    required this.blocks,
    required this.steals,
    required this.minutes,
    required this.won,
    required this.isDoubleDouble,
    required this.isTripleDouble,
    required this.isBuzzerBeater,
    this.playoffSeries,
    required this.season,
  });

  factory GameStats.fromJson(Map<String, dynamic> json) => GameStats(
        id: json['id'] as String,
        date: json['date'] as String,
        team: json['team'] as String,
        opponent: json['opponent'] as String,
        gameNumber: json['gameNumber'] as int,
        gameType: GameType.fromWire(json['gameType'] as String),
        absenceType: AbsenceType.fromWire(json['absenceType'] as String),
        isAbsent: json['isAbsent'] as bool,
        points: json['points'] as int,
        assists: json['assists'] as int,
        rebounds: json['rebounds'] as int,
        blocks: json['blocks'] as int,
        steals: json['steals'] as int,
        minutes: json['minutes'] as int,
        won: json['won'] as bool,
        isDoubleDouble: json['isDoubleDouble'] as bool,
        isTripleDouble: json['isTripleDouble'] as bool,
        isBuzzerBeater: json['isBuzzerBeater'] as bool,
        playoffSeries: json['playoffSeries'] == null
            ? null
            : PlayoffSeries.fromJson(
                json['playoffSeries'] as Map<String, dynamic>),
        season: json['season'] as String,
      );

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
        'id': id,
        'date': date,
        'team': team,
        'opponent': opponent,
        'gameNumber': gameNumber,
        'gameType': gameType.wireName,
        'absenceType': absenceType.wireName,
        'isAbsent': isAbsent,
        'points': points,
        'assists': assists,
        'rebounds': rebounds,
        'blocks': blocks,
        'steals': steals,
        'minutes': minutes,
        'won': won,
        'isDoubleDouble': isDoubleDouble,
        'isTripleDouble': isTripleDouble,
        'isBuzzerBeater': isBuzzerBeater,
        'season': season,
      };
    // Optional fields are omitted when null, matching JSON.stringify in the
    // React app (undefined properties are dropped, not written as null).
    if (playoffSeries != null) {
      json['playoffSeries'] = playoffSeries!.toJson();
    }
    return json;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameStats &&
          id == other.id &&
          date == other.date &&
          team == other.team &&
          opponent == other.opponent &&
          gameNumber == other.gameNumber &&
          gameType == other.gameType &&
          absenceType == other.absenceType &&
          isAbsent == other.isAbsent &&
          points == other.points &&
          assists == other.assists &&
          rebounds == other.rebounds &&
          blocks == other.blocks &&
          steals == other.steals &&
          minutes == other.minutes &&
          won == other.won &&
          isDoubleDouble == other.isDoubleDouble &&
          isTripleDouble == other.isTripleDouble &&
          isBuzzerBeater == other.isBuzzerBeater &&
          playoffSeries == other.playoffSeries &&
          season == other.season;

  @override
  int get hashCode => Object.hash(
        id,
        date,
        team,
        opponent,
        gameNumber,
        gameType,
        absenceType,
        isAbsent,
        points,
        assists,
        rebounds,
        blocks,
        steals,
        minutes,
        won,
        isDoubleDouble,
        isTripleDouble,
        isBuzzerBeater,
        playoffSeries,
        season,
      );
}
