/// Pure Dart port of `src/data/nbaData.ts` — teams, season awards, and
/// generated team schedules (regular season + playoffs). Mirrors the TS
/// file's structure and algorithms 1:1 so game dates/opponents match the
/// React app for the same team/season/gameNumber.
library;

import 'package:nba_fantasy_stats_react_app/models/season_awards.dart';
import 'package:nba_fantasy_stats_react_app/models/team.dart';

/// `.NBATeam` in nbaData.ts — the [Team] model already exists in
/// `models/team.dart`; this file uses it.

const regularSeasonGameCount = 82;
const playoffSeriesWinCount = 4;

/// One scheduled game — `interface Game` in nbaData.ts.
class ScheduledGame {
  const ScheduledGame({
    required this.date,
    required this.opponent,
    required this.isHome,
    required this.isPlayoff,
    this.playoffRound,
  });

  final String date;
  final String opponent;
  final bool isHome;
  final bool isPlayoff;
  final int? playoffRound;
}

/// `interface TeamSchedule` — schedule bundle for one team/season.
class TeamSchedule {
  const TeamSchedule({
    required this.teamId,
    required this.season,
    required this.games,
  });

  final String teamId;
  final String season;
  final List<ScheduledGame> games;
}

/// `interface SeasonData` — awards + schedules for one season.
class SeasonData {
  SeasonData({
    required this.season,
    required this.awards,
    this.schedules = const [],
  });

  final String season;
  final SeasonAwards awards;

  /// Mutable like the TS object — `generateAllSchedules` fills it in.
  List<TeamSchedule> schedules;
}

/// NBA teams — `NBA_TEAMS` in nbaData.ts.
const nbaTeams = <Team>[
  // Eastern Conference - Atlantic
  Team(
    id: 'bos',
    name: 'Celtics',
    city: 'Boston',
    conference: 'Eastern',
    division: 'Atlantic',
  ),
  Team(
    id: 'nyk',
    name: 'Knicks',
    city: 'New York',
    conference: 'Eastern',
    division: 'Atlantic',
  ),
  Team(
    id: 'bkn',
    name: 'Nets',
    city: 'Brooklyn',
    conference: 'Eastern',
    division: 'Atlantic',
  ),
  Team(
    id: 'phi',
    name: '76ers',
    city: 'Philadelphia',
    conference: 'Eastern',
    division: 'Atlantic',
  ),
  Team(
    id: 'tor',
    name: 'Raptors',
    city: 'Toronto',
    conference: 'Eastern',
    division: 'Atlantic',
  ),
  // Eastern Conference - Central
  Team(
    id: 'cle',
    name: 'Cavaliers',
    city: 'Cleveland',
    conference: 'Eastern',
    division: 'Central',
  ),
  Team(
    id: 'chi',
    name: 'Bulls',
    city: 'Chicago',
    conference: 'Eastern',
    division: 'Central',
  ),
  Team(
    id: 'ind',
    name: 'Pacers',
    city: 'Indiana',
    conference: 'Eastern',
    division: 'Central',
  ),
  Team(
    id: 'det',
    name: 'Pistons',
    city: 'Detroit',
    conference: 'Eastern',
    division: 'Central',
  ),
  Team(
    id: 'mil',
    name: 'Bucks',
    city: 'Milwaukee',
    conference: 'Eastern',
    division: 'Central',
  ),
  // Eastern Conference - Southeast
  Team(
    id: 'mia',
    name: 'Heat',
    city: 'Miami',
    conference: 'Eastern',
    division: 'Southeast',
  ),
  Team(
    id: 'atl',
    name: 'Hawks',
    city: 'Atlanta',
    conference: 'Eastern',
    division: 'Southeast',
  ),
  Team(
    id: 'cha',
    name: 'Hornets',
    city: 'Charlotte',
    conference: 'Eastern',
    division: 'Southeast',
  ),
  Team(
    id: 'was',
    name: 'Wizards',
    city: 'Washington',
    conference: 'Eastern',
    division: 'Southeast',
  ),
  Team(
    id: 'orl',
    name: 'Magic',
    city: 'Orlando',
    conference: 'Eastern',
    division: 'Southeast',
  ),
  // Western Conference - Northwest
  Team(
    id: 'okc',
    name: 'Thunder',
    city: 'Oklahoma City',
    conference: 'Western',
    division: 'Northwest',
  ),
  Team(
    id: 'den',
    name: 'Nuggets',
    city: 'Denver',
    conference: 'Western',
    division: 'Northwest',
  ),
  Team(
    id: 'por',
    name: 'Trail Blazers',
    city: 'Portland',
    conference: 'Western',
    division: 'Northwest',
  ),
  Team(
    id: 'min',
    name: 'Timberwolves',
    city: 'Minnesota',
    conference: 'Western',
    division: 'Northwest',
  ),
  Team(
    id: 'utah',
    name: 'Jazz',
    city: 'Utah',
    conference: 'Western',
    division: 'Northwest',
  ),
  // Western Conference - Pacific
  Team(
    id: 'gsw',
    name: 'Warriors',
    city: 'Golden State',
    conference: 'Western',
    division: 'Pacific',
  ),
  Team(
    id: 'lal',
    name: 'Lakers',
    city: 'LA',
    conference: 'Western',
    division: 'Pacific',
  ),
  Team(
    id: 'lac',
    name: 'Clippers',
    city: 'LA',
    conference: 'Western',
    division: 'Pacific',
  ),
  Team(
    id: 'phx',
    name: 'Suns',
    city: 'Phoenix',
    conference: 'Western',
    division: 'Pacific',
  ),
  Team(
    id: 'sac',
    name: 'Kings',
    city: 'Sacramento',
    conference: 'Western',
    division: 'Pacific',
  ),
  // Western Conference - Southwest
  Team(
    id: 'sas',
    name: 'Spurs',
    city: 'San Antonio',
    conference: 'Western',
    division: 'Southwest',
  ),
  Team(
    id: 'hou',
    name: 'Rockets',
    city: 'Houston',
    conference: 'Western',
    division: 'Southwest',
  ),
  Team(
    id: 'dal',
    name: 'Mavericks',
    city: 'Dallas',
    conference: 'Western',
    division: 'Southwest',
  ),
  Team(
    id: 'mem',
    name: 'Grizzlies',
    city: 'Memphis',
    conference: 'Western',
    division: 'Southwest',
  ),
  Team(
    id: 'nop',
    name: 'Pelicans',
    city: 'New Orleans',
    conference: 'Western',
    division: 'Southwest',
  ),
];

/// Finds a team by its full `City Name` label (the React app's
/// `` `${team.city} ${team.name}` `` keying).
Team? teamByLabel(String label) =>
    nbaTeams.where((t) => '${t.city} ${t.name}' == label).firstOrNull;

String teamLabel(Team team) => '${team.city} ${team.name}';

/// Generates late-October → mid-April dates, every 2 days
/// (`generateSeasonDates`).
List<String> _generateSeasonDates(int seasonStartYear) {
  final dates = <String>[];
  var current = DateTime(seasonStartYear, 10, 25);
  final end = DateTime(seasonStartYear + 1, 4, 15);

  while (!current.isAfter(end)) {
    dates.add(current.toIso8601String().substring(0, 10));
    current = current.add(const Duration(days: 2));
  }
  return dates;
}

/// Generates a team's regular-season schedule
/// (`generateTeamSchedule`): division opponents ×4, conference opponents
/// ×3-4 (seeded), other conference ×2, sorted by date, truncated to 82.
List<ScheduledGame> _generateTeamSchedule(
  String teamId,
  String season,
  List<Team> allTeams,
) {
  final team = allTeams.firstWhere((t) => t.id == teamId);
  final conferenceTeams = allTeams
      .where((t) => t.conference == team.conference && t.id != teamId)
      .toList();
  final otherConferenceTeams = allTeams
      .where((t) => t.conference != team.conference)
      .toList();
  final divisionTeams = allTeams
      .where((t) => t.division == team.division && t.id != teamId)
      .toList();

  final games = <ScheduledGame>[];
  final dates = _generateSeasonDates(int.parse(season.split('-').first));

  void addGames(List<Team> opponents, int Function(Team) timesFor) {
    for (final opp in opponents) {
      final times = timesFor(opp);
      for (var i = 0; i < times; i++) {
        if (dates.isNotEmpty) {
          games.add(
            ScheduledGame(
              date: dates.removeAt(0),
              opponent: teamLabel(opp),
              isHome: i.isEven,
              isPlayoff: false,
            ),
          );
        }
      }
    }
  }

  // Division games (4 times each).
  addGames(divisionTeams, (_) => 4);
  // Conference games (3-4 times each, seeded by chars like the TS code).
  addGames(conferenceTeams, (opp) {
    final scheduleSeed = teamId.codeUnitAt(0) + opp.id.codeUnitAt(0);
    return scheduleSeed % 2 == 0 ? 4 : 3;
  });
  // Other conference games (2 times each).
  addGames(otherConferenceTeams, (_) => 2);

  games.sort((a, b) => a.date.compareTo(b.date));
  return games.take(82).toList();
}

String _finalsOpponent(String conference, Team team, SeasonAwards awards) {
  // `getFinalsOpponent` in nbaData.ts — placeholder cross-conference label,
  // except the real champion matchup for the champion team itself.
  if (awards.champion.team == teamLabel(team)) {
    return conference == 'Eastern'
        ? 'Western Conference Champion'
        : 'Eastern Conference Champion';
  }
  return awards.champion.team;
}

/// Generates the 21-game playoff window (3 rounds × best-of-7)
/// (`generatePlayoffSchedule`).
List<ScheduledGame> _generatePlayoffSchedule(
  String teamId,
  String season,
  SeasonAwards awards,
  List<Team> allTeams,
) {
  final games = <ScheduledGame>[];
  final team = allTeams.firstWhere((t) => t.id == teamId);
  final playoffYear = int.parse(season.split('-').first) + 1;

  String pad(int n) => n.toString().padLeft(2, '0');

  // First round (best of 7): April 20–30 then rolling into May 2,
  // matching the TS date literals exactly.
  final firstRoundDates = List.generate(7, (i) {
    final day = 20 + i * 2;
    return day > 30
        ? '$playoffYear-05-${pad(day - 30)}'
        : '$playoffYear-04-${pad(day)}';
  });
  for (var i = 0; i < firstRoundDates.length; i++) {
    games.add(
      ScheduledGame(
        date: firstRoundDates[i],
        opponent: 'Playoffs Round 1 Opponent',
        isHome: i.isEven,
        isPlayoff: true,
        playoffRound: 1,
      ),
    );
  }

  // Conference Finals.
  final confFinalsDates = List.generate(
    7,
    (i) => '$playoffYear-05-${pad(8 + i * 2)}',
  );
  for (var i = 0; i < confFinalsDates.length; i++) {
    games.add(
      ScheduledGame(
        date: confFinalsDates[i],
        opponent: 'Conference Finals Opponent',
        isHome: i.isEven,
        isPlayoff: true,
        playoffRound: 2,
      ),
    );
  }

  // NBA Finals.
  final finalsDates = List.generate(7, (i) {
    final day = 25 + i * 2;
    final month = day > 31 ? 6 : 5;
    final monthDay = day > 31 ? day - 31 : day;
    return '$playoffYear-$month-${pad(monthDay)}';
  });
  for (var i = 0; i < finalsDates.length; i++) {
    games.add(
      ScheduledGame(
        date: finalsDates[i],
        opponent: _finalsOpponent(team.conference, team, awards),
        isHome: i.isEven,
        isPlayoff: true,
        playoffRound: 3,
      ),
    );
  }

  return games;
}

/// Season data with awards (2008–2025) — `SEASONS_DATA` in nbaData.ts.
final seasonsData = <SeasonData>[
  _season(
    '2008-2009',
    mvp: ('LeBron James', 'Cleveland Cavaliers'),
    champion: ('Los Angeles Lakers', '65-17'),
    scoring: ('Dwyane Wade', 'Miami Heat', 30.2),
    defensivePlayer: ('Dwight Howard', 'Orlando Magic'),
    best: ('Cleveland Cavaliers', '66-16', 66),
  ),
  _season(
    '2009-2010',
    mvp: ('LeBron James', 'Cleveland Cavaliers'),
    champion: ('Los Angeles Lakers', '57-25'),
    scoring: ('Kevin Durant', 'Oklahoma City Thunder', 30.1),
    defensivePlayer: ('Dwight Howard', 'Orlando Magic'),
    best: ('Cleveland Cavaliers', '61-21', 61),
  ),
  _season(
    '2010-2011',
    mvp: ('Derrick Rose', 'Chicago Bulls'),
    champion: ('Dallas Mavericks', '57-25'),
    scoring: ('Kevin Durant', 'Oklahoma City Thunder', 27.7),
    defensivePlayer: ('Tyson Chandler', 'New York Knicks'),
    best: ('San Antonio Spurs', '61-21', 61),
  ),
  _season(
    '2011-2012',
    mvp: ('LeBron James', 'Miami Heat'),
    champion: ('Miami Heat', '46-20'),
    scoring: ('Kevin Durant', 'Oklahoma City Thunder', 28.0),
    defensivePlayer: ('Tyson Chandler', 'New York Knicks'),
    best: ('San Antonio Spurs', '50-16', 50),
  ),
  _season(
    '2012-2013',
    mvp: ('LeBron James', 'Miami Heat'),
    champion: ('Miami Heat', '66-16'),
    scoring: ('Carmelo Anthony', 'New York Knicks', 28.7),
    defensivePlayer: ('Marc Gasol', 'Memphis Grizzlies'),
    best: ('Miami Heat', '66-16', 66),
  ),
  _season(
    '2013-2014',
    mvp: ('Kevin Durant', 'Oklahoma City Thunder'),
    champion: ('San Antonio Spurs', '62-20'),
    scoring: ('Kevin Durant', 'Oklahoma City Thunder', 32.0),
    defensivePlayer: ('Joakim Noah', 'Chicago Bulls'),
    best: ('San Antonio Spurs', '62-20', 62),
  ),
  _season(
    '2014-2015',
    mvp: ('Stephen Curry', 'Golden State Warriors'),
    champion: ('Golden State Warriors', '67-15'),
    scoring: ('Russell Westbrook', 'Oklahoma City Thunder', 28.1),
    defensivePlayer: ('Kawhi Leonard', 'San Antonio Spurs'),
    best: ('Golden State Warriors', '67-15', 67),
  ),
  _season(
    '2015-2016',
    mvp: ('Stephen Curry', 'Golden State Warriors'),
    champion: ('Cleveland Cavaliers', '57-25'),
    scoring: ('Stephen Curry', 'Golden State Warriors', 30.1),
    defensivePlayer: ('Kawhi Leonard', 'San Antonio Spurs'),
    best: ('Golden State Warriors', '73-9', 73),
  ),
  _season(
    '2016-2017',
    mvp: ('Russell Westbrook', 'Oklahoma City Thunder'),
    champion: ('Golden State Warriors', '67-15'),
    scoring: ('Russell Westbrook', 'Oklahoma City Thunder', 31.6),
    defensivePlayer: ('Draymond Green', 'Golden State Warriors'),
    best: ('Golden State Warriors', '67-15', 67),
  ),
  _season(
    '2017-2018',
    mvp: ('James Harden', 'Houston Rockets'),
    champion: ('Golden State Warriors', '58-24'),
    scoring: ('James Harden', 'Houston Rockets', 30.4),
    defensivePlayer: ('Rudy Gobert', 'Utah Jazz'),
    best: ('Houston Rockets', '65-17', 65),
  ),
  _season(
    '2018-2019',
    mvp: ('Giannis Antetokounmpo', 'Milwaukee Bucks'),
    champion: ('Toronto Raptors', '58-24'),
    scoring: ('James Harden', 'Houston Rockets', 36.1),
    defensivePlayer: ('Rudy Gobert', 'Utah Jazz'),
    best: ('Milwaukee Bucks', '60-22', 60),
  ),
  _season(
    '2019-2020',
    mvp: ('Giannis Antetokounmpo', 'Milwaukee Bucks'),
    champion: ('Los Angeles Lakers', '52-19'),
    scoring: ('James Harden', 'Houston Rockets', 34.3),
    defensivePlayer: ('Giannis Antetokounmpo', 'Milwaukee Bucks'),
    best: ('Milwaukee Bucks', '56-17', 56),
  ),
  _season(
    '2020-2021',
    mvp: ('Nikola Jokić', 'Denver Nuggets'),
    champion: ('Milwaukee Bucks', '46-26'),
    scoring: ('Stephen Curry', 'Golden State Warriors', 32.0),
    defensivePlayer: ('Rudy Gobert', 'Utah Jazz'),
    best: ('Utah Jazz', '52-20', 52),
  ),
  _season(
    '2021-2022',
    mvp: ('Nikola Jokić', 'Denver Nuggets'),
    champion: ('Golden State Warriors', '53-29'),
    scoring: ('Joel Embiid', 'Philadelphia 76ers', 30.6),
    defensivePlayer: ('Marcus Smart', 'Boston Celtics'),
    best: ('Phoenix Suns', '64-18', 64),
  ),
  _season(
    '2022-2023',
    mvp: ('Joel Embiid', 'Philadelphia 76ers'),
    champion: ('Denver Nuggets', '53-29'),
    scoring: ('Joel Embiid', 'Philadelphia 76ers', 33.4),
    defensivePlayer: ('Jaren Jackson Jr.', 'Memphis Grizzlies'),
    best: ('Milwaukee Bucks', '58-24', 58),
  ),
  _season(
    '2023-2024',
    mvp: ('Nikola Jokić', 'Denver Nuggets'),
    champion: ('Boston Celtics', '64-18'),
    scoring: ('Luka Dončić', 'Dallas Mavericks', 32.7),
    defensivePlayer: ('Rudy Gobert', 'Minnesota Timberwolves'),
    best: ('Boston Celtics', '64-18', 64),
  ),
  _season(
    '2024-2025',
    mvp: ('Nikola Jokić', 'Denver Nuggets'),
    champion: ('Golden State Warriors', '58-24'),
    scoring: ('Luka Dončić', 'Dallas Mavericks', 31.5),
    defensivePlayer: ('Victor Wembanyama', 'San Antonio Spurs'),
    best: ('Golden State Warriors', '58-24', 58),
  ),
];

SeasonData _season(
  String season, {
  required (String, String) mvp,
  required (String, String) champion,
  required (String, String, double) scoring,
  required (String, String) defensivePlayer,
  required (String, String, int) best,
}) => SeasonData(
  season: season,
  awards: SeasonAwards(
    mvp: AwardWinner(player: mvp.$1, team: mvp.$2),
    champion: Champion(team: champion.$1, record: champion.$2),
    scoringChampion: ScoringChampion(
      player: scoring.$1,
      team: scoring.$2,
      ppg: scoring.$3,
    ),        defensivePlayerOfYear:
            AwardWinner(player: defensivePlayer.$1, team: defensivePlayer.$2),
    winningestTeam: WinningestTeam(
      team: best.$1,
      record: best.$2,
      wins: best.$3,
    ),
  ),
);

/// Generated schedule cache — `allSchedulesCache` + `generateAllSchedules`.
List<SeasonData>? _allSchedulesCache;

List<SeasonData> generateAllSchedules() {
  final cached = _allSchedulesCache;
  if (cached != null) return cached;

  final generated = seasonsData.map((seasonData) {
    seasonData.schedules = nbaTeams
        .map(
          (team) => TeamSchedule(
            teamId: team.id,
            season: seasonData.season,
            games: [
              ..._generateTeamSchedule(team.id, seasonData.season, nbaTeams),
              ..._generatePlayoffSchedule(
                team.id,
                seasonData.season,
                seasonData.awards,
                nbaTeams,
              ),
            ],
          ),
        )
        .toList();
    return seasonData;
  }).toList();

  return _allSchedulesCache = generated;
}

/// Full (regular + playoff) schedule for a team/season.
List<ScheduledGame> getTeamSchedule(String teamId, String season) {
  final allData = generateAllSchedules();
  final seasonData = _seasonData(allData, season);
  final teamSchedule = seasonData?.schedules
      .where((s) => s.teamId == teamId)
      .firstOrNull;
  return teamSchedule?.games ?? const [];
}

List<ScheduledGame> getTeamRegularSeasonSchedule(
  String teamId,
  String season,
) => getTeamSchedule(teamId, season).where((game) => !game.isPlayoff).toList();

List<ScheduledGame> getTeamPlayoffSchedule(String teamId, String season) =>
    getTeamSchedule(teamId, season).where((game) => game.isPlayoff).toList();

/// All season labels, oldest first.
List<String> getAvailableSeasons() => seasonsData.map((s) => s.season).toList();

/// The season after [season], or null at the end of the data
/// (`getNextSeason`).
String? getNextSeason(String season) {
  final seasons = getAvailableSeasons();
  final index = seasons.indexOf(season);
  if (index < 0) return null;
  return index + 1 < seasons.length ? seasons[index + 1] : null;
}

SeasonData? _seasonData(List<SeasonData> data, String season) =>
    data.where((s) => s.season == season).firstOrNull;
