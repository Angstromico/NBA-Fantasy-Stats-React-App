/// Season awards snapshot — mirrors `SeasonAwards` in `src/interfaces/index.ts`.
class SeasonAwards {
  final AwardWinner mvp;
  final Champion champion;
  final ScoringChampion scoringChampion;
  final AwardWinner defensivePlayerOfYear;
  final WinningestTeam winningestTeam;

  const SeasonAwards({
    required this.mvp,
    required this.champion,
    required this.scoringChampion,
    required this.defensivePlayerOfYear,
    required this.winningestTeam,
  });

  factory SeasonAwards.fromJson(Map<String, dynamic> json) => SeasonAwards(
        mvp: AwardWinner.fromJson(json['mvp'] as Map<String, dynamic>),
        champion: Champion.fromJson(json['champion'] as Map<String, dynamic>),
        scoringChampion: ScoringChampion.fromJson(
            json['scoringChampion'] as Map<String, dynamic>),
        defensivePlayerOfYear: AwardWinner.fromJson(
            json['defensivePlayerOfYear'] as Map<String, dynamic>),
        winningestTeam: WinningestTeam.fromJson(
            json['winningestTeam'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'mvp': mvp.toJson(),
        'champion': champion.toJson(),
        'scoringChampion': scoringChampion.toJson(),
        'defensivePlayerOfYear': defensivePlayerOfYear.toJson(),
        'winningestTeam': winningestTeam.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonAwards &&
          mvp == other.mvp &&
          champion == other.champion &&
          scoringChampion == other.scoringChampion &&
          defensivePlayerOfYear == other.defensivePlayerOfYear &&
          winningestTeam == other.winningestTeam;

  @override
  int get hashCode => Object.hash(mvp, champion, scoringChampion,
      defensivePlayerOfYear, winningestTeam);
}

/// `{ player, team }` award block — used by `mvp` and `defensivePlayerOfYear`.
class AwardWinner {
  final String player;
  final String team;

  const AwardWinner({required this.player, required this.team});

  factory AwardWinner.fromJson(Map<String, dynamic> json) => AwardWinner(
        player: json['player'] as String,
        team: json['team'] as String,
      );

  Map<String, dynamic> toJson() => {'player': player, 'team': team};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AwardWinner && player == other.player && team == other.team;

  @override
  int get hashCode => Object.hash(player, team);
}

/// `{ team, record }` block — used by `champion`.
class Champion {
  final String team;
  final String record;

  const Champion({required this.team, required this.record});

  factory Champion.fromJson(Map<String, dynamic> json) => Champion(
        team: json['team'] as String,
        record: json['record'] as String,
      );

  Map<String, dynamic> toJson() => {'team': team, 'record': record};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Champion && team == other.team && record == other.record;

  @override
  int get hashCode => Object.hash(team, record);
}

/// `{ player, team, ppg }` block — used by `scoringChampion`.
class ScoringChampion {
  final String player;
  final String team;
  final double ppg;

  const ScoringChampion({
    required this.player,
    required this.team,
    required this.ppg,
  });

  factory ScoringChampion.fromJson(Map<String, dynamic> json) =>
      ScoringChampion(
        player: json['player'] as String,
        team: json['team'] as String,
        ppg: (json['ppg'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'player': player, 'team': team, 'ppg': ppg};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoringChampion &&
          player == other.player &&
          team == other.team &&
          ppg == other.ppg;

  @override
  int get hashCode => Object.hash(player, team, ppg);
}

/// `{ team, record, wins }` block — used by `winningestTeam`.
class WinningestTeam {
  final String team;
  final String record;
  final int wins;

  const WinningestTeam({
    required this.team,
    required this.record,
    required this.wins,
  });

  factory WinningestTeam.fromJson(Map<String, dynamic> json) => WinningestTeam(
        team: json['team'] as String,
        record: json['record'] as String,
        wins: json['wins'] as int,
      );

  Map<String, dynamic> toJson() =>
      {'team': team, 'record': record, 'wins': wins};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WinningestTeam &&
          team == other.team &&
          record == other.record &&
          wins == other.wins;

  @override
  int get hashCode => Object.hash(team, record, wins);
}
