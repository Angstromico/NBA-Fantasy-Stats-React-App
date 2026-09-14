/// All-time NBA "top 20" leaderboards used by the app's leaderboard feature.
///
/// Dart port of `src/data/nbaLeaderboards.ts`.
/// Sources: Basketball-Reference.com single-season leaderboards (NBA-only)
/// and career triple-doubles, and Wikipedia NBA single-game leaders lists.
/// Stats reflect the NBA regular season and are current through the 2025-26
/// season. Values are ranked best-first; equal marks are ordered by sortKey
/// (earliest game date or earliest season first).
library;

/// Group of a leaderboard board.
enum LeaderboardGroup {
  singleGame('single-game'),
  singleSeason('single-season'),
  career('career'),
  team('team');

  const LeaderboardGroup(this.wireName);
  final String wireName;

  static LeaderboardGroup fromWire(String value) => values.firstWhere(
    (g) => g.wireName == value,
    orElse: () => LeaderboardGroup.career,
  );
}

/// One row on an all-time leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.value,
    required this.context,
    required this.sortKey,
  });

  /// Player (or team for the wins board).
  final String name;

  /// Ranked stat value.
  final num value;

  /// Human context shown under the name, e.g. date · opponent or season.
  final String context;

  /// Tie-break key used when two marks are equal (date or season string).
  final String sortKey;
}

/// Definition of one leaderboard board.
class LeaderboardDef {
  const LeaderboardDef({
    required this.id,
    required this.group,
    required this.title,
    required this.detail,
    required this.unit,
    required this.format,
    required this.entries,
    this.note,
  });

  final String id;
  final LeaderboardGroup group;

  /// Short stat label, e.g. "Points" or "Points Per Game".
  final String title;

  /// What each row measures.
  final String detail;

  /// Unit suffix shown next to the value, e.g. "pts" or "ppg".
  final String unit;

  /// 'int' or 'dec'.
  final String format;

  final List<LeaderboardEntry> entries;

  /// Optional footnote about era/completeness of the data.
  final String? note;
}

const List<LeaderboardDef> leaderboards = [
  // ---------------------------------------------------------------------------
  // Best single games (each player once, with their career-best game)
  // ---------------------------------------------------------------------------
  LeaderboardDef(
    id: 'sg-points',
    group: LeaderboardGroup.singleGame,
    title: 'Points',
    detail: 'Career-best single-game scoring performances',
    unit: 'pts',
    format: 'int',
    entries: [
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 100,
        context: 'Mar 2, 1962 · Philadelphia Warriors vs New York Knicks',
        sortKey: '1962-03-02',
      ),
      LeaderboardEntry(
        name: 'Bam Adebayo',
        value: 83,
        context: 'Mar 10, 2026 · Miami Heat vs Washington Wizards',
        sortKey: '2026-03-10',
      ),
      LeaderboardEntry(
        name: 'Kobe Bryant',
        value: 81,
        context: 'Jan 22, 2006 · Los Angeles Lakers vs Toronto Raptors',
        sortKey: '2006-01-22',
      ),
      LeaderboardEntry(
        name: 'David Thompson',
        value: 73,
        context: 'Apr 9, 1978 · Denver Nuggets vs Detroit Pistons',
        sortKey: '1978-04-09',
      ),
      LeaderboardEntry(
        name: 'Luka Dončić',
        value: 73,
        context: 'Jan 26, 2024 · Dallas Mavericks vs Atlanta Hawks',
        sortKey: '2024-01-26',
      ),
      LeaderboardEntry(
        name: 'Elgin Baylor',
        value: 71,
        context: 'Nov 15, 1960 · Los Angeles Lakers vs New York Knicks',
        sortKey: '1960-11-15',
      ),
      LeaderboardEntry(
        name: 'David Robinson',
        value: 71,
        context: 'Apr 24, 1994 · San Antonio Spurs vs Los Angeles Clippers',
        sortKey: '1994-04-24',
      ),
      LeaderboardEntry(
        name: 'Donovan Mitchell',
        value: 71,
        context: 'Jan 2, 2023 · Cleveland Cavaliers vs Chicago Bulls',
        sortKey: '2023-01-02',
      ),
      LeaderboardEntry(
        name: 'Damian Lillard',
        value: 71,
        context: 'Feb 26, 2023 · Portland Trail Blazers vs Houston Rockets',
        sortKey: '2023-02-26',
      ),
      LeaderboardEntry(
        name: 'Devin Booker',
        value: 70,
        context: 'Mar 24, 2017 · Phoenix Suns vs Boston Celtics',
        sortKey: '2017-03-24',
      ),
      LeaderboardEntry(
        name: 'Joel Embiid',
        value: 70,
        context: 'Jan 22, 2024 · Philadelphia 76ers vs San Antonio Spurs',
        sortKey: '2024-01-22',
      ),
      LeaderboardEntry(
        name: 'Michael Jordan',
        value: 69,
        context: 'Mar 28, 1990 · Chicago Bulls vs Cleveland Cavaliers',
        sortKey: '1990-03-28',
      ),
      LeaderboardEntry(
        name: 'Pete Maravich',
        value: 68,
        context: 'Feb 25, 1977 · New Orleans Jazz vs New York Knicks',
        sortKey: '1977-02-25',
      ),
      LeaderboardEntry(
        name: 'Joe Fulks',
        value: 63,
        context: 'Feb 10, 1949 · Philadelphia Warriors vs Indianapolis Jets',
        sortKey: '1949-02-10',
      ),
      LeaderboardEntry(
        name: 'Jerry West',
        value: 63,
        context: 'Jan 17, 1962 · Los Angeles Lakers vs New York Knicks',
        sortKey: '1962-01-17',
      ),
      LeaderboardEntry(
        name: 'George Gervin',
        value: 63,
        context: 'Apr 9, 1978 · San Antonio Spurs vs New Orleans Jazz',
        sortKey: '1978-04-09',
      ),
      LeaderboardEntry(
        name: 'Tracy McGrady',
        value: 62,
        context: 'Mar 10, 2004 · Orlando Magic vs Washington Wizards',
        sortKey: '2004-03-10',
      ),
      LeaderboardEntry(
        name: 'Carmelo Anthony',
        value: 62,
        context: 'Jan 24, 2014 · New York Knicks vs Charlotte Bobcats',
        sortKey: '2014-01-24',
      ),
      LeaderboardEntry(
        name: 'Stephen Curry',
        value: 62,
        context:
            'Jan 3, 2021 · Golden State Warriors vs Portland Trail Blazers',
        sortKey: '2021-01-03',
      ),
      LeaderboardEntry(
        name: 'Karl-Anthony Towns',
        value: 62,
        context: 'Jan 22, 2024 · Minnesota Timberwolves vs Charlotte Hornets',
        sortKey: '2024-01-22',
      ),
    ],
    note:
        'Each player appears once, with their career-best regular-season game.',
  ),
  LeaderboardDef(
    id: 'sg-assists',
    group: LeaderboardGroup.singleGame,
    title: 'Assists',
    detail: 'Career-best single-game assist performances',
    unit: 'ast',
    format: 'int',
    entries: [
      LeaderboardEntry(
        name: 'Scott Skiles',
        value: 30,
        context: 'Dec 30, 1990 · Orlando Magic vs Denver Nuggets',
        sortKey: '1990-12-30',
      ),
      LeaderboardEntry(
        name: 'Kevin Porter',
        value: 29,
        context: 'Feb 24, 1978 · New Jersey Nets vs Houston Rockets',
        sortKey: '1978-02-24',
      ),
      LeaderboardEntry(
        name: 'Bob Cousy',
        value: 28,
        context: 'Feb 27, 1959 · Boston Celtics vs Minneapolis Lakers',
        sortKey: '1959-02-27',
      ),
      LeaderboardEntry(
        name: 'Guy Rodgers',
        value: 28,
        context: 'Mar 14, 1963 · San Francisco Warriors vs St. Louis Hawks',
        sortKey: '1963-03-14',
      ),
      LeaderboardEntry(
        name: 'John Stockton',
        value: 28,
        context: 'Jan 15, 1991 · Utah Jazz vs San Antonio Spurs',
        sortKey: '1991-01-15',
      ),
      LeaderboardEntry(
        name: 'Geoff Huston',
        value: 27,
        context: 'Jan 27, 1982 · Cleveland Cavaliers vs Golden State Warriors',
        sortKey: '1982-01-27',
      ),
      LeaderboardEntry(
        name: 'Ernie DiGregorio',
        value: 25,
        context: 'Jan 1, 1974 · Buffalo Braves vs Portland Trail Blazers',
        sortKey: '1974-01-01',
      ),
      LeaderboardEntry(
        name: 'Isiah Thomas',
        value: 25,
        context: 'Feb 13, 1985 · Detroit Pistons vs Dallas Mavericks',
        sortKey: '1985-02-13',
      ),
      LeaderboardEntry(
        name: 'Nate McMillan',
        value: 25,
        context: 'Feb 23, 1987 · Seattle SuperSonics vs Los Angeles Clippers',
        sortKey: '1987-02-23',
      ),
      LeaderboardEntry(
        name: 'Kevin Johnson',
        value: 25,
        context: 'Apr 6, 1994 · Phoenix Suns vs San Antonio Spurs',
        sortKey: '1994-04-06',
      ),
      LeaderboardEntry(
        name: 'Jason Kidd',
        value: 25,
        context: 'Feb 8, 1996 · Dallas Mavericks vs Utah Jazz',
        sortKey: '1996-02-08',
      ),
      LeaderboardEntry(
        name: 'Rajon Rondo',
        value: 25,
        context: 'Dec 27, 2017 · New Orleans Pelicans vs Brooklyn Nets',
        sortKey: '2017-12-27',
      ),
      LeaderboardEntry(
        name: 'John Lucas',
        value: 24,
        context: 'Apr 15, 1984 · San Antonio Spurs vs Denver Nuggets',
        sortKey: '1984-04-15',
      ),
      LeaderboardEntry(
        name: 'Magic Johnson',
        value: 24,
        context: 'Nov 17, 1989 · Los Angeles Lakers vs Denver Nuggets',
        sortKey: '1989-11-17',
      ),
      LeaderboardEntry(
        name: 'Ramon Sessions',
        value: 24,
        context: 'Apr 14, 2008 · Milwaukee Bucks vs Chicago Bulls',
        sortKey: '2008-04-14',
      ),
      LeaderboardEntry(
        name: 'Russell Westbrook',
        value: 24,
        context: 'Jan 10, 2019 · Oklahoma City Thunder vs San Antonio Spurs',
        sortKey: '2019-01-10',
      ),
      LeaderboardEntry(
        name: 'Jerry West',
        value: 23,
        context: 'Feb 1, 1967 · Los Angeles Lakers vs Philadelphia 76ers',
        sortKey: '1967-02-01',
      ),
      LeaderboardEntry(
        name: 'Tiny Archibald',
        value: 23,
        context: 'Feb 5, 1982 · Boston Celtics vs Denver Nuggets',
        sortKey: '1982-02-05',
      ),
      LeaderboardEntry(
        name: 'Fat Lever',
        value: 23,
        context: 'Apr 21, 1989 · Denver Nuggets vs Golden State Warriors',
        sortKey: '1989-04-21',
      ),
      LeaderboardEntry(
        name: 'Mookie Blaylock',
        value: 23,
        context: 'Mar 6, 1993 · Atlanta Hawks vs Utah Jazz',
        sortKey: '1993-03-06',
      ),
    ],
    note:
        'Each player appears once, with their career-best regular-season game.',
  ),
  LeaderboardDef(
    id: 'sg-rebounds',
    group: LeaderboardGroup.singleGame,
    title: 'Rebounds',
    detail: 'Career-best single-game rebounding performances',
    unit: 'reb',
    format: 'int',
    entries: [
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 55,
        context: 'Nov 24, 1960 · Philadelphia Warriors vs Boston Celtics',
        sortKey: '1960-11-24',
      ),
      LeaderboardEntry(
        name: 'Bill Russell',
        value: 51,
        context: 'Feb 5, 1960 · Boston Celtics vs Syracuse Nationals',
        sortKey: '1960-02-05',
      ),
      LeaderboardEntry(
        name: 'Nate Thurmond',
        value: 42,
        context: 'Nov 9, 1965 · San Francisco Warriors vs Detroit Pistons',
        sortKey: '1965-11-09',
      ),
      LeaderboardEntry(
        name: 'Jerry Lucas',
        value: 40,
        context: 'Feb 29, 1964 · Cincinnati Royals vs Philadelphia 76ers',
        sortKey: '1964-02-29',
      ),
      LeaderboardEntry(
        name: 'Neil Johnston',
        value: 39,
        context: 'Dec 4, 1954 · Philadelphia Warriors vs Syracuse Nationals',
        sortKey: '1954-12-04',
      ),
      LeaderboardEntry(
        name: 'Maurice Stokes',
        value: 38,
        context: 'Jan 14, 1956 · Rochester Royals vs Syracuse Nationals',
        sortKey: '1956-01-14',
      ),
      LeaderboardEntry(
        name: 'Moses Malone',
        value: 37,
        context: 'Feb 9, 1979 · Houston Rockets vs New Orleans Jazz',
        sortKey: '1979-02-09',
      ),
      LeaderboardEntry(
        name: 'Charles Oakley',
        value: 35,
        context: 'Apr 22, 1988 · Chicago Bulls vs Cleveland Cavaliers',
        sortKey: '1988-04-22',
      ),
      LeaderboardEntry(
        name: 'Dennis Rodman',
        value: 34,
        context: 'Mar 4, 1992 · Detroit Pistons vs Indiana Pacers',
        sortKey: '1992-03-04',
      ),
      LeaderboardEntry(
        name: 'Rony Seikaly',
        value: 34,
        context: 'Mar 3, 1993 · Miami Heat vs Washington Bullets',
        sortKey: '1993-03-03',
      ),
      LeaderboardEntry(
        name: 'Swen Nater',
        value: 33,
        context: 'Dec 19, 1976 · Milwaukee Bucks vs Atlanta Hawks',
        sortKey: '1976-12-19',
      ),
      LeaderboardEntry(
        name: 'Kevin Willis',
        value: 33,
        context: 'Feb 19, 1992 · Atlanta Hawks vs Washington Bullets',
        sortKey: '1992-02-19',
      ),
      LeaderboardEntry(
        name: 'Charles Barkley',
        value: 33,
        context: 'Nov 2, 1996 · Houston Rockets vs Phoenix Suns',
        sortKey: '1996-11-02',
      ),
      LeaderboardEntry(
        name: 'Robert Parish',
        value: 32,
        context: 'Mar 30, 1979 · Golden State Warriors vs New York Knicks',
        sortKey: '1979-03-30',
      ),
      LeaderboardEntry(
        name: 'Larry Smith',
        value: 31,
        context: 'Mar 28, 1981 · Golden State Warriors vs Denver Nuggets',
        sortKey: '1981-03-28',
      ),
      LeaderboardEntry(
        name: 'Dikembe Mutombo',
        value: 31,
        context: 'Mar 26, 1996 · Denver Nuggets vs Charlotte Hornets',
        sortKey: '1996-03-26',
      ),
      LeaderboardEntry(
        name: 'Kevin Love',
        value: 31,
        context: 'Nov 12, 2010 · Minnesota Timberwolves vs New York Knicks',
        sortKey: '2010-11-12',
      ),
      LeaderboardEntry(
        name: 'Jusuf Nurkić',
        value: 31,
        context: 'Mar 3, 2024 · Phoenix Suns vs Oklahoma City Thunder',
        sortKey: '2024-03-03',
      ),
      LeaderboardEntry(
        name: 'Kareem Abdul-Jabbar',
        value: 30,
        context: 'Feb 3, 1978 · Los Angeles Lakers vs New Jersey Nets',
        sortKey: '1978-02-03',
      ),
      LeaderboardEntry(
        name: 'Michael Cage',
        value: 30,
        context: 'Apr 24, 1988 · Los Angeles Clippers vs Seattle SuperSonics',
        sortKey: '1988-04-24',
      ),
    ],
    note:
        '30+ rebound games are complete from 1976-77 onward; 38+ games are complete for all eras.',
  ),
  LeaderboardDef(
    id: 'sg-blocks',
    group: LeaderboardGroup.singleGame,
    title: 'Blocks',
    detail:
        'Career-best single-game blocked-shot performances (tracked since 1973-74)',
    unit: 'blk',
    format: 'int',
    entries: [
      LeaderboardEntry(
        name: 'Elmore Smith',
        value: 17,
        context: 'Oct 28, 1973 · Los Angeles Lakers vs Portland Trail Blazers',
        sortKey: '1973-10-28',
      ),
      LeaderboardEntry(
        name: 'Manute Bol',
        value: 15,
        context: 'Jan 25, 1986 · Washington Bullets vs Atlanta Hawks',
        sortKey: '1986-01-25',
      ),
      LeaderboardEntry(
        name: "Shaquille O’Neal",
        value: 15,
        context: 'Nov 20, 1993 · Orlando Magic vs New Jersey Nets',
        sortKey: '1993-11-20',
      ),
      LeaderboardEntry(
        name: 'Mark Eaton',
        value: 14,
        context: 'Jan 18, 1985 · Utah Jazz vs Portland Trail Blazers',
        sortKey: '1985-01-18',
      ),
      LeaderboardEntry(
        name: 'George T. Johnson',
        value: 13,
        context: 'Feb 24, 1981 · San Antonio Spurs vs Golden State Warriors',
        sortKey: '1981-02-24',
      ),
      LeaderboardEntry(
        name: 'Darryl Dawkins',
        value: 13,
        context: 'Nov 5, 1983 · New Jersey Nets vs Philadelphia 76ers',
        sortKey: '1983-11-05',
      ),
      LeaderboardEntry(
        name: 'Ralph Sampson',
        value: 13,
        context: 'Dec 9, 1983 · Houston Rockets vs Chicago Bulls',
        sortKey: '1983-12-09',
      ),
      LeaderboardEntry(
        name: 'Shawn Bradley',
        value: 13,
        context: 'Apr 7, 1998 · Dallas Mavericks vs Portland Trail Blazers',
        sortKey: '1998-04-07',
      ),
      LeaderboardEntry(
        name: 'Nate Thurmond',
        value: 12,
        context: 'Oct 18, 1974 · Chicago Bulls vs Atlanta Hawks',
        sortKey: '1974-10-18',
      ),
      LeaderboardEntry(
        name: 'Wayne “Tree” Rollins',
        value: 12,
        context: 'Feb 21, 1979 · Atlanta Hawks vs Portland Trail Blazers',
        sortKey: '1979-02-21',
      ),
      LeaderboardEntry(
        name: 'Hakeem Olajuwon',
        value: 12,
        context: 'Mar 10, 1987 · Houston Rockets vs Seattle SuperSonics',
        sortKey: '1987-03-10',
      ),
      LeaderboardEntry(
        name: 'David Robinson',
        value: 12,
        context: 'Feb 23, 1990 · San Antonio Spurs vs Minnesota Timberwolves',
        sortKey: '1990-02-23',
      ),
      LeaderboardEntry(
        name: 'Dikembe Mutombo',
        value: 12,
        context: 'Apr 18, 1993 · Denver Nuggets vs Los Angeles Clippers',
        sortKey: '1993-04-18',
      ),
      LeaderboardEntry(
        name: 'Vlade Divac',
        value: 12,
        context: 'Feb 12, 1997 · Charlotte Hornets vs New Jersey Nets',
        sortKey: '1997-02-12',
      ),
      LeaderboardEntry(
        name: 'Keon Clark',
        value: 12,
        context: 'Mar 23, 2001 · Toronto Raptors vs Atlanta Hawks',
        sortKey: '2001-03-23',
      ),
      LeaderboardEntry(
        name: 'JaVale McGee',
        value: 12,
        context: 'Mar 15, 2011 · Washington Wizards vs Chicago Bulls',
        sortKey: '2011-03-15',
      ),
      LeaderboardEntry(
        name: 'Hassan Whiteside',
        value: 12,
        context: 'Jan 25, 2015 · Miami Heat vs Chicago Bulls',
        sortKey: '2015-01-25',
      ),
      LeaderboardEntry(
        name: 'Kareem Abdul-Jabbar',
        value: 11,
        context: 'Dec 3, 1975 · Los Angeles Lakers vs Detroit Pistons',
        sortKey: '1975-12-03',
      ),
      LeaderboardEntry(
        name: 'Artis Gilmore',
        value: 11,
        context: 'Dec 20, 1977 · Chicago Bulls vs Atlanta Hawks',
        sortKey: '1977-12-20',
      ),
      LeaderboardEntry(
        name: 'Robert Parish',
        value: 11,
        context: 'Oct 29, 1978 · Golden State Warriors vs Cleveland Cavaliers',
        sortKey: '1978-10-29',
      ),
    ],
    note:
        'Blocked shots were first officially tracked in 1973-74, so pre-1974 totals are excluded.',
  ),
  LeaderboardDef(
    id: 'sg-steals',
    group: LeaderboardGroup.singleGame,
    title: 'Steals',
    detail:
        'Career-best single-game steal performances (tracked since 1973-74)',
    unit: 'stl',
    format: 'int',
    entries: [
      LeaderboardEntry(
        name: 'Larry Kenon',
        value: 11,
        context: 'Dec 26, 1976 · San Antonio Spurs vs Kansas City Kings',
        sortKey: '1976-12-26',
      ),
      LeaderboardEntry(
        name: 'Kendall Gill',
        value: 11,
        context: 'Apr 3, 1999 · New Jersey Nets vs Miami Heat',
        sortKey: '1999-04-03',
      ),
      LeaderboardEntry(
        name: 'Jerry West',
        value: 10,
        context: 'Dec 7, 1973 · Los Angeles Lakers vs Seattle SuperSonics',
        sortKey: '1973-12-07',
      ),
      LeaderboardEntry(
        name: 'Larry Steele',
        value: 10,
        context: 'Nov 16, 1974 · Portland Trail Blazers vs Los Angeles Lakers',
        sortKey: '1974-11-16',
      ),
      LeaderboardEntry(
        name: 'Fred Brown',
        value: 10,
        context: 'Dec 3, 1976 · Seattle SuperSonics vs Philadelphia 76ers',
        sortKey: '1976-12-03',
      ),
      LeaderboardEntry(
        name: 'Gus Williams',
        value: 10,
        context: 'Feb 22, 1978 · Seattle SuperSonics vs New Jersey Nets',
        sortKey: '1978-02-22',
      ),
      LeaderboardEntry(
        name: 'Eddie Jordan',
        value: 10,
        context: 'Mar 23, 1979 · New Jersey Nets vs Philadelphia 76ers',
        sortKey: '1979-03-23',
      ),
      LeaderboardEntry(
        name: 'Johnny Moore',
        value: 10,
        context: 'Mar 6, 1985 · San Antonio Spurs vs Indiana Pacers',
        sortKey: '1985-03-06',
      ),
      LeaderboardEntry(
        name: 'Fat Lever',
        value: 10,
        context: 'Mar 9, 1985 · Denver Nuggets vs Indiana Pacers',
        sortKey: '1985-03-09',
      ),
      LeaderboardEntry(
        name: 'Clyde Drexler',
        value: 10,
        context: 'Jan 10, 1986 · Portland Trail Blazers vs Milwaukee Bucks',
        sortKey: '1986-01-10',
      ),
      LeaderboardEntry(
        name: 'Alvin Robertson',
        value: 10,
        context: 'Feb 18, 1986 · San Antonio Spurs vs Phoenix Suns',
        sortKey: '1986-02-18',
      ),
      LeaderboardEntry(
        name: 'Ron Harper',
        value: 10,
        context: 'Mar 10, 1987 · Cleveland Cavaliers vs Philadelphia 76ers',
        sortKey: '1987-03-10',
      ),
      LeaderboardEntry(
        name: 'Michael Jordan',
        value: 10,
        context: 'Jan 29, 1988 · Chicago Bulls vs New Jersey Nets',
        sortKey: '1988-01-29',
      ),
      LeaderboardEntry(
        name: 'Kevin Johnson',
        value: 10,
        context: 'Dec 9, 1993 · Phoenix Suns vs Washington Bullets',
        sortKey: '1993-12-09',
      ),
      LeaderboardEntry(
        name: 'Mookie Blaylock',
        value: 10,
        context: 'Apr 14, 1998 · Atlanta Hawks vs Philadelphia 76ers',
        sortKey: '1998-04-14',
      ),
      LeaderboardEntry(
        name: 'Michael Finley',
        value: 10,
        context: 'Jan 23, 2001 · Dallas Mavericks vs Philadelphia 76ers',
        sortKey: '2001-01-23',
      ),
      LeaderboardEntry(
        name: 'Brandon Roy',
        value: 10,
        context: 'Jan 24, 2009 · Portland Trail Blazers vs Washington Wizards',
        sortKey: '2009-01-24',
      ),
      LeaderboardEntry(
        name: 'Draymond Green',
        value: 10,
        context: 'Feb 10, 2017 · Golden State Warriors vs Memphis Grizzlies',
        sortKey: '2017-02-10',
      ),
      LeaderboardEntry(
        name: 'Lou Williams',
        value: 10,
        context: 'Jan 20, 2018 · Los Angeles Clippers vs Utah Jazz',
        sortKey: '2018-01-20',
      ),
      LeaderboardEntry(
        name: 'T. J. McConnell',
        value: 10,
        context: 'Mar 3, 2021 · Indiana Pacers vs Cleveland Cavaliers',
        sortKey: '2021-03-03',
      ),
    ],
    note:
        'Steals were first officially tracked in 1973-74, so pre-1974 totals are excluded.',
  ),

  // ---------------------------------------------------------------------------
  // Best single seasons (per-game averages, per Basketball-Reference)
  // ---------------------------------------------------------------------------
  LeaderboardDef(
    id: 'season-ppg',
    group: LeaderboardGroup.singleSeason,
    title: 'Points Per Game',
    detail: 'Highest-scoring individual seasons',
    unit: 'ppg',
    format: 'dec',
    entries: [
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 50.36,
        context: '1961-62',
        sortKey: '1961-62',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 44.83,
        context: '1962-63',
        sortKey: '1962-63',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 38.39,
        context: '1960-61',
        sortKey: '1960-61',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 37.6,
        context: '1959-60',
        sortKey: '1959-60',
      ),
      LeaderboardEntry(
        name: 'Michael Jordan',
        value: 37.09,
        context: '1986-87',
        sortKey: '1986-87',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 36.85,
        context: '1963-64',
        sortKey: '1963-64',
      ),
      LeaderboardEntry(
        name: 'James Harden',
        value: 36.13,
        context: '2018-19',
        sortKey: '2018-19',
      ),
      LeaderboardEntry(
        name: 'Rick Barry',
        value: 35.58,
        context: '1966-67',
        sortKey: '1966-67',
      ),
      LeaderboardEntry(
        name: 'Kobe Bryant',
        value: 35.4,
        context: '2005-06',
        sortKey: '2005-06',
      ),
      LeaderboardEntry(
        name: 'Michael Jordan',
        value: 34.98,
        context: '1987-88',
        sortKey: '1987-88',
      ),
      LeaderboardEntry(
        name: 'Kareem Abdul-Jabbar',
        value: 34.84,
        context: '1971-72',
        sortKey: '1971-72',
      ),
      LeaderboardEntry(
        name: 'Elgin Baylor',
        value: 34.77,
        context: '1960-61',
        sortKey: '1960-61',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 34.71,
        context: '1964-65',
        sortKey: '1964-65',
      ),
      LeaderboardEntry(
        name: 'Bob McAdoo',
        value: 34.52,
        context: '1974-75',
        sortKey: '1974-75',
      ),
      LeaderboardEntry(
        name: 'James Harden',
        value: 34.34,
        context: '2019-20',
        sortKey: '2019-20',
      ),
      LeaderboardEntry(
        name: 'Elgin Baylor',
        value: 33.99,
        context: '1962-63',
        sortKey: '1962-63',
      ),
      LeaderboardEntry(
        name: 'Tiny Archibald',
        value: 33.99,
        context: '1972-73',
        sortKey: '1972-73',
      ),
      LeaderboardEntry(
        name: 'Luka Dončić',
        value: 33.86,
        context: '2023-24',
        sortKey: '2023-24',
      ),
      LeaderboardEntry(
        name: 'Michael Jordan',
        value: 33.57,
        context: '1989-90',
        sortKey: '1989-90',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 33.53,
        context: '1965-66',
        sortKey: '1965-66',
      ),
    ],
    note:
        'NBA-only seasons, per Basketball-Reference. League rate qualifier applied.',
  ),
  LeaderboardDef(
    id: 'season-rpg',
    group: LeaderboardGroup.singleSeason,
    title: 'Rebounds Per Game',
    detail: 'Highest-rebounding individual seasons',
    unit: 'rpg',
    format: 'dec',
    entries: [
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 27.2,
        context: '1960-61',
        sortKey: '1960-61',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 26.96,
        context: '1959-60',
        sortKey: '1959-60',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 25.65,
        context: '1961-62',
        sortKey: '1961-62',
      ),
      LeaderboardEntry(
        name: 'Bill Russell',
        value: 24.74,
        context: '1963-64',
        sortKey: '1963-64',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 24.59,
        context: '1965-66',
        sortKey: '1965-66',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 24.32,
        context: '1962-63',
        sortKey: '1962-63',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 24.16,
        context: '1966-67',
        sortKey: '1966-67',
      ),
      LeaderboardEntry(
        name: 'Bill Russell',
        value: 24.08,
        context: '1964-65',
        sortKey: '1964-65',
      ),
      LeaderboardEntry(
        name: 'Bill Russell',
        value: 24.03,
        context: '1959-60',
        sortKey: '1959-60',
      ),
      LeaderboardEntry(
        name: 'Bill Russell',
        value: 23.95,
        context: '1960-61',
        sortKey: '1960-61',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 23.8,
        context: '1967-68',
        sortKey: '1967-68',
      ),
      LeaderboardEntry(
        name: 'Bill Russell',
        value: 23.63,
        context: '1962-63',
        sortKey: '1962-63',
      ),
      LeaderboardEntry(
        name: 'Bill Russell',
        value: 23.55,
        context: '1961-62',
        sortKey: '1961-62',
      ),
      LeaderboardEntry(
        name: 'Bill Russell',
        value: 23.03,
        context: '1958-59',
        sortKey: '1958-59',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 22.92,
        context: '1964-65',
        sortKey: '1964-65',
      ),
      LeaderboardEntry(
        name: 'Bill Russell',
        value: 22.81,
        context: '1965-66',
        sortKey: '1965-66',
      ),
      LeaderboardEntry(
        name: 'Bill Russell',
        value: 22.67,
        context: '1957-58',
        sortKey: '1957-58',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 22.34,
        context: '1963-64',
        sortKey: '1963-64',
      ),
      LeaderboardEntry(
        name: 'Nate Thurmond',
        value: 21.26,
        context: '1966-67',
        sortKey: '1966-67',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 21.14,
        context: '1968-69',
        sortKey: '1968-69',
      ),
    ],
    note: 'NBA-only seasons, per Basketball-Reference.',
  ),
  LeaderboardDef(
    id: 'season-apg',
    group: LeaderboardGroup.singleSeason,
    title: 'Assists Per Game',
    detail: 'Highest-assist individual seasons',
    unit: 'apg',
    format: 'dec',
    entries: [
      LeaderboardEntry(
        name: 'John Stockton',
        value: 14.54,
        context: '1989-90',
        sortKey: '1989-90',
      ),
      LeaderboardEntry(
        name: 'John Stockton',
        value: 14.2,
        context: '1990-91',
        sortKey: '1990-91',
      ),
      LeaderboardEntry(
        name: 'Isiah Thomas',
        value: 13.86,
        context: '1984-85',
        sortKey: '1984-85',
      ),
      LeaderboardEntry(
        name: 'John Stockton',
        value: 13.76,
        context: '1987-88',
        sortKey: '1987-88',
      ),
      LeaderboardEntry(
        name: 'John Stockton',
        value: 13.73,
        context: '1991-92',
        sortKey: '1991-92',
      ),
      LeaderboardEntry(
        name: 'John Stockton',
        value: 13.63,
        context: '1988-89',
        sortKey: '1988-89',
      ),
      LeaderboardEntry(
        name: 'Kevin Porter',
        value: 13.4,
        context: '1978-79',
        sortKey: '1978-79',
      ),
      LeaderboardEntry(
        name: 'Magic Johnson',
        value: 13.06,
        context: '1983-84',
        sortKey: '1983-84',
      ),
      LeaderboardEntry(
        name: 'Magic Johnson',
        value: 12.83,
        context: '1988-89',
        sortKey: '1988-89',
      ),
      LeaderboardEntry(
        name: 'Magic Johnson',
        value: 12.6,
        context: '1985-86',
        sortKey: '1985-86',
      ),
      LeaderboardEntry(
        name: 'John Stockton',
        value: 12.57,
        context: '1993-94',
        sortKey: '1993-94',
      ),
      LeaderboardEntry(
        name: 'Magic Johnson',
        value: 12.57,
        context: '1984-85',
        sortKey: '1984-85',
      ),
      LeaderboardEntry(
        name: 'Magic Johnson',
        value: 12.52,
        context: '1990-91',
        sortKey: '1990-91',
      ),
      LeaderboardEntry(
        name: 'John Stockton',
        value: 12.33,
        context: '1994-95',
        sortKey: '1994-95',
      ),
      LeaderboardEntry(
        name: 'Kevin Johnson',
        value: 12.23,
        context: '1988-89',
        sortKey: '1988-89',
      ),
      LeaderboardEntry(
        name: 'Magic Johnson',
        value: 12.21,
        context: '1986-87',
        sortKey: '1986-87',
      ),
      LeaderboardEntry(
        name: 'John Stockton',
        value: 12.04,
        context: '1992-93',
        sortKey: '1992-93',
      ),
      LeaderboardEntry(
        name: 'Magic Johnson',
        value: 11.92,
        context: '1987-88',
        sortKey: '1987-88',
      ),
      LeaderboardEntry(
        name: 'Russell Westbrook',
        value: 11.74,
        context: '2020-21',
        sortKey: '2020-21',
      ),
      LeaderboardEntry(
        name: 'Rajon Rondo',
        value: 11.7,
        context: '2011-12',
        sortKey: '2011-12',
      ),
    ],
    note: 'NBA-only seasons, per Basketball-Reference.',
  ),
  LeaderboardDef(
    id: 'season-bpg',
    group: LeaderboardGroup.singleSeason,
    title: 'Blocks Per Game',
    detail: 'Highest-blocking individual seasons (tracked since 1973-74)',
    unit: 'bpg',
    format: 'dec',
    entries: [
      LeaderboardEntry(
        name: 'Mark Eaton',
        value: 5.56,
        context: '1984-85',
        sortKey: '1984-85',
      ),
      LeaderboardEntry(
        name: 'Manute Bol',
        value: 4.96,
        context: '1985-86',
        sortKey: '1985-86',
      ),
      LeaderboardEntry(
        name: 'Elmore Smith',
        value: 4.85,
        context: '1973-74',
        sortKey: '1973-74',
      ),
      LeaderboardEntry(
        name: 'Mark Eaton',
        value: 4.61,
        context: '1985-86',
        sortKey: '1985-86',
      ),
      LeaderboardEntry(
        name: 'Hakeem Olajuwon',
        value: 4.59,
        context: '1989-90',
        sortKey: '1989-90',
      ),
      LeaderboardEntry(
        name: 'Dikembe Mutombo',
        value: 4.49,
        context: '1995-96',
        sortKey: '1995-96',
      ),
      LeaderboardEntry(
        name: 'David Robinson',
        value: 4.49,
        context: '1991-92',
        sortKey: '1991-92',
      ),
      LeaderboardEntry(
        name: 'Hakeem Olajuwon',
        value: 4.34,
        context: '1991-92',
        sortKey: '1991-92',
      ),
      LeaderboardEntry(
        name: 'Manute Bol',
        value: 4.31,
        context: '1988-89',
        sortKey: '1988-89',
      ),
      LeaderboardEntry(
        name: 'Wayne “Tree” Rollins',
        value: 4.29,
        context: '1982-83',
        sortKey: '1982-83',
      ),
      LeaderboardEntry(
        name: 'Mark Eaton',
        value: 4.28,
        context: '1983-84',
        sortKey: '1983-84',
      ),
      LeaderboardEntry(
        name: 'Hakeem Olajuwon',
        value: 4.17,
        context: '1992-93',
        sortKey: '1992-93',
      ),
      LeaderboardEntry(
        name: 'Kareem Abdul-Jabbar',
        value: 4.12,
        context: '1975-76',
        sortKey: '1975-76',
      ),
      LeaderboardEntry(
        name: 'Dikembe Mutombo',
        value: 4.1,
        context: '1993-94',
        sortKey: '1993-94',
      ),
      LeaderboardEntry(
        name: 'Mark Eaton',
        value: 4.06,
        context: '1986-87',
        sortKey: '1986-87',
      ),
      LeaderboardEntry(
        name: 'Patrick Ewing',
        value: 3.99,
        context: '1989-90',
        sortKey: '1989-90',
      ),
      LeaderboardEntry(
        name: 'Kareem Abdul-Jabbar',
        value: 3.95,
        context: '1978-79',
        sortKey: '1978-79',
      ),
      LeaderboardEntry(
        name: 'Hakeem Olajuwon',
        value: 3.95,
        context: '1990-91',
        sortKey: '1990-91',
      ),
      LeaderboardEntry(
        name: 'Dikembe Mutombo',
        value: 3.91,
        context: '1994-95',
        sortKey: '1994-95',
      ),
      LeaderboardEntry(
        name: 'Alonzo Mourning',
        value: 3.91,
        context: '1998-99',
        sortKey: '1998-99',
      ),
    ],
    note:
        'NBA-only seasons, per Basketball-Reference. Blocks tracked since 1973-74.',
  ),
  LeaderboardDef(
    id: 'season-spg',
    group: LeaderboardGroup.singleSeason,
    title: 'Steals Per Game',
    detail: 'Highest-stealing individual seasons (tracked since 1973-74)',
    unit: 'spg',
    format: 'dec',
    entries: [
      LeaderboardEntry(
        name: 'Alvin Robertson',
        value: 3.67,
        context: '1985-86',
        sortKey: '1985-86',
      ),
      LeaderboardEntry(
        name: 'Don Buse',
        value: 3.47,
        context: '1976-77',
        sortKey: '1976-77',
      ),
      LeaderboardEntry(
        name: 'Magic Johnson',
        value: 3.43,
        context: '1980-81',
        sortKey: '1980-81',
      ),
      LeaderboardEntry(
        name: 'Michael Ray Richardson',
        value: 3.23,
        context: '1979-80',
        sortKey: '1979-80',
      ),
      LeaderboardEntry(
        name: 'Alvin Robertson',
        value: 3.21,
        context: '1986-87',
        sortKey: '1986-87',
      ),
      LeaderboardEntry(
        name: 'John Stockton',
        value: 3.21,
        context: '1988-89',
        sortKey: '1988-89',
      ),
      LeaderboardEntry(
        name: 'Slick Watts',
        value: 3.18,
        context: '1975-76',
        sortKey: '1975-76',
      ),
      LeaderboardEntry(
        name: 'Michael Jordan',
        value: 3.16,
        context: '1987-88',
        sortKey: '1987-88',
      ),
      LeaderboardEntry(
        name: 'Alvin Robertson',
        value: 3.04,
        context: '1990-91',
        sortKey: '1990-91',
      ),
      LeaderboardEntry(
        name: 'Alvin Robertson',
        value: 3.03,
        context: '1988-89',
        sortKey: '1988-89',
      ),
      LeaderboardEntry(
        name: 'Dyson Daniels',
        value: 3.01,
        context: '2024-25',
        sortKey: '2024-25',
      ),
      LeaderboardEntry(
        name: 'John Stockton',
        value: 2.98,
        context: '1991-92',
        sortKey: '1991-92',
      ),
      LeaderboardEntry(
        name: 'Michael Ray Richardson',
        value: 2.96,
        context: '1984-85',
        sortKey: '1984-85',
      ),
      LeaderboardEntry(
        name: 'Alvin Robertson',
        value: 2.96,
        context: '1987-88',
        sortKey: '1987-88',
      ),
      LeaderboardEntry(
        name: 'Nate McMillan',
        value: 2.96,
        context: '1993-94',
        sortKey: '1993-94',
      ),
      LeaderboardEntry(
        name: 'John Stockton',
        value: 2.95,
        context: '1987-88',
        sortKey: '1987-88',
      ),
      LeaderboardEntry(
        name: 'Micheal Williams',
        value: 2.95,
        context: '1991-92',
        sortKey: '1991-92',
      ),
      LeaderboardEntry(
        name: 'Michael Ray Richardson',
        value: 2.94,
        context: '1980-81',
        sortKey: '1980-81',
      ),
      LeaderboardEntry(
        name: 'Scottie Pippen',
        value: 2.94,
        context: '1994-95',
        sortKey: '1994-95',
      ),
      LeaderboardEntry(
        name: 'Scottie Pippen',
        value: 2.93,
        context: '1993-94',
        sortKey: '1993-94',
      ),
    ],
    note:
        'NBA-only seasons, per Basketball-Reference. Steals tracked since 1973-74.',
  ),

  // ---------------------------------------------------------------------------
  // Career feats
  // ---------------------------------------------------------------------------
  LeaderboardDef(
    id: 'career-triple-doubles',
    group: LeaderboardGroup.career,
    title: 'Triple-Doubles',
    detail: 'Most career triple-doubles, regular season',
    unit: 'TD',
    format: 'int',
    entries: [
      LeaderboardEntry(
        name: 'Russell Westbrook',
        value: 209,
        context: 'career through 2025-26',
        sortKey: 'westbrook',
      ),
      LeaderboardEntry(
        name: 'Nikola Jokić',
        value: 198,
        context: 'career through 2025-26',
        sortKey: 'jokic',
      ),
      LeaderboardEntry(
        name: 'Oscar Robertson',
        value: 181,
        context: 'career',
        sortKey: 'robertson',
      ),
      LeaderboardEntry(
        name: 'Magic Johnson',
        value: 138,
        context: 'career',
        sortKey: 'johnson',
      ),
      LeaderboardEntry(
        name: 'LeBron James',
        value: 125,
        context: 'career through 2025-26',
        sortKey: 'james',
      ),
      LeaderboardEntry(
        name: 'Jason Kidd',
        value: 107,
        context: 'career',
        sortKey: 'kidd',
      ),
      LeaderboardEntry(
        name: 'Luka Dončić',
        value: 90,
        context: 'career through 2025-26',
        sortKey: 'doncic',
      ),
      LeaderboardEntry(
        name: 'James Harden',
        value: 82,
        context: 'career through 2025-26',
        sortKey: 'harden',
      ),
      LeaderboardEntry(
        name: 'Wilt Chamberlain',
        value: 78,
        context: 'career',
        sortKey: 'chamberlain',
      ),
      LeaderboardEntry(
        name: 'Domantas Sabonis',
        value: 68,
        context: 'career through 2025-26',
        sortKey: 'sabonis',
      ),
      LeaderboardEntry(
        name: 'Larry Bird',
        value: 59,
        context: 'career',
        sortKey: 'bird',
      ),
      LeaderboardEntry(
        name: 'Giannis Antetokounmpo',
        value: 56,
        context: 'career through 2025-26',
        sortKey: 'antetokounmpo',
      ),
      LeaderboardEntry(
        name: 'Fat Lever',
        value: 43,
        context: 'career',
        sortKey: 'lever',
      ),
      LeaderboardEntry(
        name: 'Bob Cousy',
        value: 33,
        context: 'career',
        sortKey: 'cousy',
      ),
      LeaderboardEntry(
        name: 'Draymond Green',
        value: 33,
        context: 'career through 2025-26',
        sortKey: 'green',
      ),
      LeaderboardEntry(
        name: 'Ben Simmons',
        value: 33,
        context: 'career through 2025-26',
        sortKey: 'simmons',
      ),
      LeaderboardEntry(
        name: 'Rajon Rondo',
        value: 32,
        context: 'career',
        sortKey: 'rondo',
      ),
      LeaderboardEntry(
        name: 'Josh Giddey',
        value: 31,
        context: 'career through 2025-26',
        sortKey: 'giddey',
      ),
      LeaderboardEntry(
        name: 'John Havlicek',
        value: 31,
        context: 'career',
        sortKey: 'havlicek',
      ),
      LeaderboardEntry(
        name: 'Grant Hill',
        value: 29,
        context: 'career',
        sortKey: 'hill',
      ),
    ],
    note:
        'Counts per Basketball-Reference, current through the 2025-26 season.',
  ),

  // ---------------------------------------------------------------------------
  // Team feats
  // ---------------------------------------------------------------------------
  LeaderboardDef(
    id: 'team-season-wins',
    group: LeaderboardGroup.team,
    title: 'Most Wins in a Season',
    detail: 'Greatest regular-season team records',
    unit: 'wins',
    format: 'int',
    entries: [
      LeaderboardEntry(
        name: 'Golden State Warriors',
        value: 73,
        context: '2015-16 (73-9)',
        sortKey: '2015-16',
      ),
      LeaderboardEntry(
        name: 'Chicago Bulls',
        value: 72,
        context: '1995-96 (72-10)',
        sortKey: '1995-96',
      ),
      LeaderboardEntry(
        name: 'Los Angeles Lakers',
        value: 69,
        context: '1971-72 (69-13)',
        sortKey: '1971-72',
      ),
      LeaderboardEntry(
        name: 'Chicago Bulls',
        value: 69,
        context: '1996-97 (69-13)',
        sortKey: '1996-97',
      ),
      LeaderboardEntry(
        name: 'Philadelphia 76ers',
        value: 68,
        context: '1966-67 (68-13)',
        sortKey: '1966-67',
      ),
      LeaderboardEntry(
        name: 'Boston Celtics',
        value: 68,
        context: '1972-73 (68-14)',
        sortKey: '1972-73',
      ),
      LeaderboardEntry(
        name: 'Oklahoma City Thunder',
        value: 68,
        context: '2024-25 (68-14)',
        sortKey: '2024-25',
      ),
      LeaderboardEntry(
        name: 'Boston Celtics',
        value: 67,
        context: '1985-86 (67-15)',
        sortKey: '1985-86',
      ),
      LeaderboardEntry(
        name: 'Chicago Bulls',
        value: 67,
        context: '1991-92 (67-15)',
        sortKey: '1991-92',
      ),
      LeaderboardEntry(
        name: 'Los Angeles Lakers',
        value: 67,
        context: '1999-00 (67-15)',
        sortKey: '1999-00',
      ),
      LeaderboardEntry(
        name: 'Dallas Mavericks',
        value: 67,
        context: '2006-07 (67-15)',
        sortKey: '2006-07',
      ),
      LeaderboardEntry(
        name: 'Golden State Warriors',
        value: 67,
        context: '2014-15 (67-15)',
        sortKey: '2014-15',
      ),
      LeaderboardEntry(
        name: 'San Antonio Spurs',
        value: 67,
        context: '2015-16 (67-15)',
        sortKey: '2015-16',
      ),
      LeaderboardEntry(
        name: 'Golden State Warriors',
        value: 67,
        context: '2016-17 (67-15)',
        sortKey: '2016-17',
      ),
      LeaderboardEntry(
        name: 'Milwaukee Bucks',
        value: 66,
        context: '1970-71 (66-16)',
        sortKey: '1970-71',
      ),
      LeaderboardEntry(
        name: 'Boston Celtics',
        value: 66,
        context: '2007-08 (66-16)',
        sortKey: '2007-08',
      ),
      LeaderboardEntry(
        name: 'Cleveland Cavaliers',
        value: 66,
        context: '2008-09 (66-16)',
        sortKey: '2008-09',
      ),
      LeaderboardEntry(
        name: 'Miami Heat',
        value: 66,
        context: '2012-13 (66-16)',
        sortKey: '2012-13',
      ),
      LeaderboardEntry(
        name: 'Philadelphia 76ers',
        value: 65,
        context: '1982-83 (65-17)',
        sortKey: '1982-83',
      ),
      LeaderboardEntry(
        name: 'Los Angeles Lakers',
        value: 65,
        context: '1986-87 (65-17)',
        sortKey: '1986-87',
      ),
    ],
    note: 'Full 82-game seasons only; regular-season wins.',
  ),
];
