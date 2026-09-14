/// Game-progression engine ported from the inline logic in the React app's
/// `App.tsx`: which game (type + number) comes next for a team/season,
/// including playoff series tracking, season advancement, and the
/// playable-game filter that guards against logging games from finished
/// playoff runs.
library;

import 'package:nba_fantasy_stats_react_app/data/nba_data.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/utils/stats_calculations.dart';

/// `PlayoffProgression` union in App.tsx.
enum ProgressionStatus { notStarted, active, eliminated, complete }

class PlayoffProgression {
  const PlayoffProgression._({
    required this.status,
    this.nextGameNumber = 1,
    this.round = 0,
  });

  const PlayoffProgression.notStarted()
    : this._(status: ProgressionStatus.notStarted);

  const PlayoffProgression.active(int round, int nextGameNumber)
    : this._(
        status: ProgressionStatus.active,
        round: round,
        nextGameNumber: nextGameNumber,
      );

  const PlayoffProgression.eliminated(int round)
    : this._(status: ProgressionStatus.eliminated, round: round);

  const PlayoffProgression.complete()
    : this._(status: ProgressionStatus.complete);

  final ProgressionStatus status;
  final int nextGameNumber;
  final int round;
}

/// Result of [computeNextGame] — the game type/number the tracker should
/// present next, plus an optional progression message for the UI.
class GameProgression {
  const GameProgression({
    required this.gameType,
    required this.gameNumber,
    this.message,
  });

  final GameType gameType;
  final int gameNumber;
  final String? message;
}

/// `getPlayoffRoundForGame` in App.tsx.
int playoffRoundForGame(String team, String season, int gameNumber) {
  final teamObj = teamByLabel(team);
  final schedule = teamObj == null
      ? const <ScheduledGame>[]
      : getTeamPlayoffSchedule(teamObj.id, season);
  final round = schedule.elementAtOrNull(gameNumber - 1)?.playoffRound;
  return round ?? (gameNumber / 7).ceil();
}

/// `getPlayoffProgression` in App.tsx — walks the played playoff games
/// round by round, eliminating/completing on 4 losses/wins per series.
PlayoffProgression getPlayoffProgression(
  List<GameStats> allGames,
  String team,
  String season,
) {
  final teamObj = teamByLabel(team);
  final schedule = teamObj == null
      ? const <ScheduledGame>[]
      : getTeamPlayoffSchedule(teamObj.id, season);
  final playoffGames =
      allGames
          .where(
            (game) =>
                game.team == team &&
                game.season == season &&
                game.gameType == GameType.playoffs,
          )
          .toList()
        ..sort((a, b) => a.gameNumber.compareTo(b.gameNumber));
  final playoffRounds =
      schedule
          .map((game) => game.playoffRound)
          .whereType<int>()
          .toSet()
          .toList()
        ..sort();

  if (playoffGames.isEmpty) {
    return const PlayoffProgression.notStarted();
  }

  for (final round in playoffRounds) {
    final roundStartIndex = schedule.indexWhere(
      (game) => game.playoffRound == round,
    );
    final roundGames = playoffGames
        .where(
          (game) => playoffRoundForGame(team, season, game.gameNumber) == round,
        )
        .toList();
    final wins = roundGames.where((game) => game.won).length;
    final losses = roundGames.length - wins;

    if (losses >= playoffSeriesWinCount) {
      return PlayoffProgression.eliminated(round);
    }

    if (wins >= playoffSeriesWinCount) {
      continue;
    }

    return PlayoffProgression.active(
      round,
      roundStartIndex + roundGames.length + 1,
    );
  }

  return const PlayoffProgression.complete();
}

List<GameStats> _teamSeasonGames(
  List<GameStats> allGames,
  String team,
  String season,
) => allGames.where((g) => g.season == season && g.team == team).toList();

/// `moveToNextSeason` in App.tsx.
GameProgression _moveToNextSeason(
  List<GameStats> allGames,
  String team,
  String season,
  String reason,
) {
  final nextSeason = getNextSeason(season);

  if (nextSeason == null) {
    return GameProgression(
      gameType: GameType.regular,
      gameNumber: regularSeasonGameCount + 1,
      message: '$reason No later season is available in the app data.',
    );
  }

  final nextRegularGames = _teamSeasonGames(
    allGames,
    team,
    nextSeason,
  ).where((g) => g.gameType == GameType.regular).length;

  return GameProgression(
    gameType: GameType.regular,
    gameNumber: nextRegularGames + 1,
    message: '$reason Advanced to $nextSeason.',
  );
}

/// `setGameProgression` in App.tsx — after logging a game (or switching
/// team/season), determines the next game type + number and any
/// progression message.
GameProgression computeNextGame(
  List<GameStats> allGames,
  String team,
  String season,
) {
  final seasonGames = _teamSeasonGames(allGames, team, season);
  final regularSeasonGames = seasonGames
      .where((g) => g.gameType == GameType.regular)
      .toList();

  if (regularSeasonGames.length >= regularSeasonGameCount) {
    if (checkPlayoffQualification(regularSeasonGames)) {
      final progression = getPlayoffProgression(allGames, team, season);

      switch (progression.status) {
        case ProgressionStatus.eliminated:
          return _moveToNextSeason(
            allGames,
            team,
            season,
            '$season playoff run ended in round ${progression.round}.',
          );

        case ProgressionStatus.complete:
          return _moveToNextSeason(
            allGames,
            team,
            season,
            '$season playoff run is complete.',
          );

        case ProgressionStatus.active:
        case ProgressionStatus.notStarted:
          return GameProgression(
            gameType: GameType.playoffs,
            gameNumber: progression.nextGameNumber,
          );
      }
    }

    return _moveToNextSeason(
      allGames,
      team,
      season,
      '$season is complete without playoff qualification.',
    );
  }

  return GameProgression(
    gameType: GameType.regular,
    gameNumber: regularSeasonGames.length + 1,
  );
}

/// `filterPlayableGames` in App.tsx — accepts incoming games only while the
/// corresponding playoff run is still open; blocks non-first-round games
/// before a run has started and anything from an eliminated/complete run.
List<GameStats> filterPlayableGames(
  List<GameStats> existingGames,
  List<GameStats> incomingGames,
) {
  final acceptedGames = <GameStats>[];
  final eliminatedSeasons = <String>{};

  for (final game in incomingGames) {
    if (game.gameType != GameType.playoffs) {
      acceptedGames.add(game);
      continue;
    }

    final seasonKey = '${game.team}:${game.season}';
    if (eliminatedSeasons.contains(seasonKey)) {
      continue;
    }

    final playableGames = [...existingGames, ...acceptedGames];
    final currentProgression = getPlayoffProgression(
      playableGames,
      game.team,
      game.season,
    );

    if (currentProgression.status == ProgressionStatus.eliminated ||
        currentProgression.status == ProgressionStatus.complete) {
      eliminatedSeasons.add(seasonKey);
      continue;
    }

    final gameRound = playoffRoundForGame(
      game.team,
      game.season,
      game.gameNumber,
    );

    if (currentProgression.status == ProgressionStatus.notStarted &&
        gameRound != 1) {
      // A run that has not started only accepts round-1 games.
      continue;
    }

    if (currentProgression.status == ProgressionStatus.active &&
        gameRound != currentProgression.round) {
      continue;
    }

    acceptedGames.add(game);

    final nextProgression = getPlayoffProgression(
      [...existingGames, ...acceptedGames],
      game.team,
      game.season,
    );

    if (nextProgression.status == ProgressionStatus.eliminated) {
      eliminatedSeasons.add(seasonKey);
    }
  }

  return acceptedGames;
}
