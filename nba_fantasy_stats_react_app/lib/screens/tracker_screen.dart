import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/data/nba_data.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/models/stats_summary.dart';
import 'package:nba_fantasy_stats_react_app/models/team.dart';
import 'package:nba_fantasy_stats_react_app/utils/game_progression.dart';
import 'package:nba_fantasy_stats_react_app/utils/stats_calculations.dart';
import 'package:nba_fantasy_stats_react_app/utils/storage_service.dart';
import 'package:nba_fantasy_stats_react_app/widgets/champion_comparison.dart';
import 'package:nba_fantasy_stats_react_app/widgets/confirmation_dialog.dart';
import 'package:nba_fantasy_stats_react_app/widgets/glass_card.dart';
import 'package:nba_fantasy_stats_react_app/widgets/stat_field.dart';
import 'package:nba_fantasy_stats_react_app/widgets/tracker_stats_section.dart';

/// Game logging screen replicating `GameForm.tsx` plus the tracker view's
/// stats sections (`StatsDisplay` + `ComparisonDisplay` in App.tsx):
/// season/team selection, schedule-driven matchup info, per-game stat
/// entry with auto-derived double/triple doubles, buzzer-beater win lock,
/// absence handling that zeroes stats, bulk-skip mode, and below the form
/// the full stats summary, averages, milestones, and champion comparison.
class TrackerScreen extends StatefulWidget {
  const TrackerScreen({
    super.key,
    required this.username,
    this.selectedTeam = '',
    this.selectedSeason = '',
    this.games,
    this.onTeamChange,
    this.onSeasonChange,
    this.onResetSeason,
    this.onGamesLogged,
  });

  final String username;

  /// Lifted state (App.tsx pattern): the shell owns team/season so the
  /// selection survives tab switches.
  final String selectedTeam;
  final String selectedSeason;

  /// The live games list from the app shell (the React app's `stats`
  /// prop) — used to recompute the next game type/number after every save
  /// and to render the stats sections below the form.
  final List<GameStats>? games;

  final void Function(String team)? onTeamChange;
  final void Function(String season)? onSeasonChange;
  final void Function(String season)? onResetSeason;

  /// Notifies the shell after games are added so it can save and refresh.
  final void Function(List<GameStats> games)? onGamesLogged;

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final _ptsCtrl = TextEditingController();
  final _astCtrl = TextEditingController();
  final _rebCtrl = TextEditingController();
  final _blkCtrl = TextEditingController();
  final _stlCtrl = TextEditingController();
  final _minCtrl = TextEditingController();

  GameType _gameType = GameType.regular;
  AbsenceType _absenceType = AbsenceType.none;
  bool _won = false;
  bool _buzzer = false;
  bool _skipMode = false;
  int _skipCount = 1;
  int _skipWins = 1;
  bool _skipToSeasonEnd = false;
  String _opponent = '';
  String _date = '';
  String? _error;
  int _gamesLogged = 0;
  int _nextGameNumber = 1;

  @override
  void initState() {
    super.initState();
    _loadStoredGames();
  }

  @override
  void didUpdateWidget(TrackerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recompute the matchup whenever the lifted team/season selection
    // changes, or after the shell saves new games (the `useEffect`
    // dependency array in GameForm.tsx).
    if (oldWidget.selectedTeam != widget.selectedTeam ||
        oldWidget.selectedSeason != widget.selectedSeason ||
        !identical(oldWidget.games, widget.games)) {
      _loadStoredGames();
    }
  }

  @override
  void dispose() {
    for (final c in [
      _ptsCtrl,
      _astCtrl,
      _rebCtrl,
      _blkCtrl,
      _stlCtrl,
      _minCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Loads the games (from the shell prop when available, storage
  /// otherwise) and derives the next game type/number for the selected
  /// team + season — `initializeGameProgression`/`setGameProgression` in
  /// App.tsx.
  Future<void> _loadStoredGames() async {
    List<GameStats> games;
    if (widget.games != null) {
      games = widget.games!;
    } else {
      final raw = await StorageService.readList(StorageService.gamesKey);
      games = raw
          .whereType<Map<String, dynamic>>()
          .map(GameStats.fromJson)
          .toList();
    }
    if (!mounted) return;

    var progression = const GameProgression(
      gameType: GameType.regular,
      gameNumber: 1,
    );
    if (_hasSelection) {
      progression = computeNextGame(
        games,
        widget.selectedTeam,
        widget.selectedSeason,
      );
    }

    setState(() {
      _gamesLogged = games.length;
      _gameType = progression.gameType;
      _nextGameNumber = progression.gameNumber;
    });
  }

  int _parse(TextEditingController c) => int.tryParse(c.text) ?? 0;

  bool get _isAbsent => _absenceType != AbsenceType.none;

  bool get _hasSelection =>
      widget.selectedTeam.isNotEmpty && widget.selectedSeason.isNotEmpty;

  Team? get _selectedTeamObj => teamByLabel(widget.selectedTeam);

  List<ScheduledGame> get _schedule {
    final team = _selectedTeamObj;
    if (team == null || widget.selectedSeason.isEmpty) return const [];
    return _gameType == GameType.playoffs
        ? getTeamPlayoffSchedule(team.id, widget.selectedSeason)
        : getTeamRegularSeasonSchedule(team.id, widget.selectedSeason);
  }

  int get _currentGameNumber => _nextGameNumber;

  int get _remainingGames => _schedule.isEmpty
      ? 0
      : (_schedule.length - (_currentGameNumber - 1)).clamp(
          0,
          _schedule.length,
        );

  int get _availableSkipGames {
    final team = _selectedTeamObj;
    if (team == null || widget.selectedSeason.isEmpty) return 0;
    if (_gameType == GameType.playoffs) return _remainingGames;

    var season = widget.selectedSeason;
    var gameNumber = _currentGameNumber;
    var available = 0;
    while (season.isNotEmpty) {
      final seasonSchedule = getTeamRegularSeasonSchedule(team.id, season);
      available += (seasonSchedule.length - (gameNumber - 1)).clamp(
        0,
        seasonSchedule.length,
      );
      final next = getNextSeason(season);
      season = next ?? '';
      gameNumber = 1;
    }
    return available;
  }

  int get _gamesInInterval => (_skipToSeasonEnd ? _remainingGames : _skipCount)
      .clamp(0, _availableSkipGames == 0 ? 1 : _availableSkipGames);

  int get _intervalWins =>
      _skipWins < _gamesInInterval ? _skipWins : _gamesInInterval;

  /// Recomputes date/opponent for the upcoming matchup from the schedule
  /// (the `useEffect` in GameForm.tsx).
  void _refreshMatchup() {
    if (!_hasSelection) {
      _opponent = '';
      _date = '';
      return;
    }
    final index = _currentGameNumber - 1;
    final scheduled = _schedule.elementAtOrNull(index);
    if (scheduled != null) {
      _date = scheduled.date;
      _opponent = scheduled.opponent;
    } else {
      _date = DateTime.now().toIso8601String().substring(0, 10);
      _opponent = '';
    }
  }

  /// Mirrors `updateStats` in GameForm.tsx: buzzer beater locks the win;
  /// absence zeroes all stat categories and clears derived flags.
  void _onAnyChange() {
    setState(() {
      if (_buzzer) _won = true;
      if (_isAbsent) {
        _won = false;
        _buzzer = false;
        for (final c in [
          _ptsCtrl,
          _astCtrl,
          _rebCtrl,
          _blkCtrl,
          _stlCtrl,
          _minCtrl,
        ]) {
          c.text = '';
        }
      }
      _error = null;
    });
  }

  GameStats _buildGame({required String opponent, required String date}) {
    final pts = _parse(_ptsCtrl);
    final ast = _parse(_astCtrl);
    final reb = _parse(_rebCtrl);
    final blk = _parse(_blkCtrl);
    final stl = _parse(_stlCtrl);
    final min = _parse(_minCtrl);
    final dc = [pts, ast, reb, blk, stl].where((v) => v >= 10).length;

    return GameStats(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: date,
      team: widget.selectedTeam,
      opponent: opponent,
      gameNumber: _currentGameNumber,
      gameType: _gameType,
      absenceType: _absenceType,
      isAbsent: _isAbsent,
      points: _isAbsent ? 0 : pts,
      assists: _isAbsent ? 0 : ast,
      rebounds: _isAbsent ? 0 : reb,
      blocks: _isAbsent ? 0 : blk,
      steals: _isAbsent ? 0 : stl,
      minutes: _isAbsent ? 0 : min,
      won: _won,
      isDoubleDouble: !_isAbsent && dc >= 2,
      isTripleDouble: !_isAbsent && dc >= 3,
      isBuzzerBeater: !_isAbsent && _buzzer,
      season: widget.selectedSeason,
    );
  }

  List<bool> _buildRandomOutcomes(int totalGames, int wins) =>
      List<bool>.generate(totalGames, (i) => i < wins)..shuffle();

  /// `buildSkippedRegularSeasonGames` — bulk absences flowing across
  /// season boundaries when the current season runs out of games.
  List<GameStats> _buildSkippedRegularSeasonGames(int totalGames) {
    final skipped = <GameStats>[];
    final outcomes = _buildRandomOutcomes(totalGames, _intervalWins);
    final team = _selectedTeamObj;
    if (team == null) return skipped;

    var season = widget.selectedSeason;
    var gameNumber = _currentGameNumber;

    while (season.isNotEmpty && skipped.length < totalGames) {
      final seasonSchedule = getTeamRegularSeasonSchedule(team.id, season);
      for (
        var index = gameNumber - 1;
        index < seasonSchedule.length && skipped.length < totalGames;
        index++
      ) {
        final scheduled = seasonSchedule[index];
        final intervalIndex = skipped.length;
        skipped.add(
          _buildGame(
            opponent: scheduled.opponent,
            date: scheduled.date,
          ).copyWith(
            id: '${DateTime.now().microsecondsSinceEpoch}_$intervalIndex',
            gameNumber: index + 1,
            gameType: GameType.regular,
            season: season,
            isAbsent: true,
            won: outcomes[intervalIndex],
          ),
        );
      }
      season = getNextSeason(season) ?? '';
      gameNumber = 1;
    }
    return skipped;
  }

  /// `buildSkippedPlayoffGames`.
  List<GameStats> _buildSkippedPlayoffGames(int totalGames) {
    final skipped = <GameStats>[];
    final outcomes = _buildRandomOutcomes(totalGames, _intervalWins);
    final schedule = _schedule;

    for (var i = 0; i < totalGames; i++) {
      final index = (_currentGameNumber - 1) + i;
      final scheduled = schedule.elementAtOrNull(index);
      if (scheduled != null) {
        skipped.add(
          _buildGame(
            opponent: scheduled.opponent,
            date: scheduled.date,
          ).copyWith(
            id: '${DateTime.now().microsecondsSinceEpoch}_$i',
            gameNumber: _currentGameNumber + i,
            gameType: GameType.playoffs,
            isAbsent: true,
            won: outcomes[i],
          ),
        );
      }
    }
    return skipped;
  }

  Future<void> _submitGame() async {
    if (widget.selectedTeam.isEmpty) {
      setState(() => _error = 'Please select a team');
      return;
    }

    List<GameStats> gamesToAdd;
    if (_skipMode) {
      final bulk = _gameType == GameType.regular
          ? _buildSkippedRegularSeasonGames(_gamesInInterval)
          : _buildSkippedPlayoffGames(_gamesInInterval);
      if (bulk.isEmpty) {
        setState(() => _error = 'No games found to skip');
        return;
      }
      gamesToAdd = bulk;
    } else {
      if (_opponent.isEmpty) {
        setState(() => _error = 'No opponent scheduled for this game');
        return;
      }
      gamesToAdd = [_buildGame(opponent: _opponent, date: _date)];
    }

    if (widget.onGamesLogged != null) {
      // Embedded in the app shell: the shell owns persistence, congrats
      // banners, and progression (App.tsx's `addGameStats`).
      widget.onGamesLogged!(gamesToAdd);
    } else {
      // Standalone (or tests): persist directly and advance progression.
      final raw = await StorageService.readList(StorageService.gamesKey);
      final existing = raw
          .whereType<Map<String, dynamic>>()
          .map(GameStats.fromJson)
          .toList();
      final playable = filterPlayableGames(existing, gamesToAdd);
      if (playable.isEmpty) {
        if (!mounted) return;
        setState(
          () => _error =
              'No playoff games were added because the current '
              'playoff run is already complete.',
        );
        return;
      }
      await StorageService.writeJson(StorageService.gamesKey, [
        ...existing,
        ...playable.map((g) => g.toJson()),
      ]);
      final lastGame = playable.last;
      final next = computeNextGame(
        [...existing, ...playable],
        lastGame.team,
        lastGame.season,
      );
      if (!mounted) return;
      _gameType = next.gameType;
      _nextGameNumber = next.gameNumber;
    }

    if (!mounted) return;
    setState(() {
      for (final c in [
        _ptsCtrl,
        _astCtrl,
        _rebCtrl,
        _blkCtrl,
        _stlCtrl,
        _minCtrl,
      ]) {
        c.clear();
      }
      _absenceType = AbsenceType.none;
      _won = false;
      _buzzer = false;
      _error = null;
      _gamesLogged += gamesToAdd.length;
      _refreshMatchup();
    });
  }

  Future<void> _confirmResetSeason() async {
    final season = widget.selectedSeason;
    if (season.isEmpty || widget.onResetSeason == null) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Reset Season',
      message:
          'Are you sure you want to reset the $season season '
          'for ${widget.selectedTeam}?',
      details:
          'This will permanently delete all games and statistics '
          'recorded for this season and start fresh from Game 1.',
      confirmLabel: 'Reset Season',
      cancelLabel: 'Cancel',
      tone: ConfirmTone.danger,
    );
    if (confirmed) widget.onResetSeason!(season);
  }

  @override
  Widget build(BuildContext context) {
    _refreshMatchup();
    final wide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Tracker'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${widget.username} · $_gamesLogged logged',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _formCard(wide),
                // The tracker view renders `StatsDisplay` +
                // `ComparisonDisplay` under the form in App.tsx.
                _statsBelowForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The stats sections rendered under the form.
  Widget _statsBelowForm() {
    final games = widget.games ?? const <GameStats>[];
    if (games.isEmpty) return const SizedBox.shrink();

    final seasons = organizeSeasonStats(games);
    final summary = calculateStatsSummary(games);
    final highs = calculateCareerHighs(games);

    final season = widget.selectedSeason.isNotEmpty
        ? widget.selectedSeason
        : (seasons.isNotEmpty ? seasons.first.seasonYear : '');
    final team = widget.selectedTeam;
    final seasonData = seasonsData.where((s) => s.season == season).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrackerStatsSection(
          stats: games,
          careerHighs: highs,
          statsSummary: summary,
          seasonStats: seasons,
          currentSeason: season,
        ),
        if (team.isNotEmpty && season.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ChampionComparison(
              playerStats: _seasonSummary(summary, games, season, team),
              seasonAwards: seasonData?.awards,
              playerTeam: team,
              season: season,
            ),
          ),
      ],
    );
  }

  /// Builds the current-team-season summary used by the comparison card
  /// (`currentSeasonSummary` in App.tsx).
  StatsSummary _seasonSummary(
    StatsSummary career,
    List<GameStats> games,
    String season,
    String team,
  ) {
    final seasonTeamGames = games
        .where((g) => g.season == season && g.team == team)
        .toList();
    if (seasonTeamGames.isEmpty) return career;
    return calculateStatsSummary(seasonTeamGames);
  }

  Widget _formCard(bool wide) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(wide),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          _selectionRow(),
          if (_hasSelection && !_skipMode) ...[
            const SizedBox(height: 12),
            _matchupCard(),
          ],
          const SizedBox(height: 12),
          _absenceRow(),
          if (!_isAbsent && !_skipMode) ...[
            const SizedBox(height: 12),
            _statFields(wide),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Won'),
              value: _won,
              onChanged: (v) {
                setState(() => _won = v);
                _onAnyChange();
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Buzzer Beater'),
              value: _buzzer,
              onChanged: (v) {
                setState(() => _buzzer = v);
                _onAnyChange();
              },
            ),
          ],
          if (_skipMode) ...[const SizedBox(height: 12), _skipConfig()],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitGame,
            child: Text(
              _skipMode ? 'Log $_gamesInInterval Skipped Game(s)' : 'Log Game',
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(bool wide) {
    final title = Text(
      '${_gameType == GameType.regular ? 'Regular Season' : 'Playoffs'} '
      'Game $_currentGameNumber',
      style: Theme.of(context).textTheme.titleLarge,
    );
    final typeSwitch = SegmentedButton<GameType>(
      segments: const [
        ButtonSegment(value: GameType.regular, label: Text('Regular')),
        ButtonSegment(value: GameType.playoffs, label: Text('Playoffs')),
      ],
      selected: {_gameType},
      onSelectionChanged: (s) => setState(() => _gameType = s.first),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The React header's `game-type-switcher` sits beside the title on
        // wide screens and below it on phones.
        if (wide)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: title),
              typeSwitch,
            ],
          )
        else ...[
          title,
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: typeSwitch),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Bulk Skip Mode'),
          value: _skipMode,
          onChanged: (v) {
            setState(() {
              _skipMode = v;
              if (v && _absenceType == AbsenceType.none) {
                _absenceType = AbsenceType.rest;
              }
              if (!v) {
                _skipToSeasonEnd = false;
              }
              _skipWins = (_gamesInInterval / 2).ceil();
            });
          },
        ),
      ],
    );
  }

  Widget _selectionRow() {
    final seasonDropdown = DropdownButtonFormField<String>(
      key: ValueKey('season_${widget.selectedSeason}'),
      initialValue: widget.selectedSeason.isEmpty
          ? null
          : widget.selectedSeason,
      hint: const Text('Select Season'),
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Season',
        border: const OutlineInputBorder(),
        suffixIcon: widget.selectedSeason.isEmpty
            ? null
            : IconButton(
                tooltip: 'Reset ${widget.selectedSeason} season',
                icon: const Icon(Icons.restart_alt),
                onPressed: _confirmResetSeason,
              ),
      ),
      items: getAvailableSeasons()
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (s) {
        if (s == null) return;
        widget.onSeasonChange?.call(s);
        setState(() => _error = null);
      },
    );
    final teamDropdown = DropdownButtonFormField<String>(
      key: ValueKey('team_${widget.selectedTeam}'),
      initialValue: widget.selectedTeam.isEmpty ? null : widget.selectedTeam,
      hint: const Text('Select Team'),
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Team',
        border: OutlineInputBorder(),
      ),
      items: nbaTeams
          .map(
            (t) => DropdownMenuItem(
              value: teamLabel(t),
              child: Text(teamLabel(t)),
            ),
          )
          .toList(),
      onChanged: (t) {
        if (t == null) return;
        widget.onTeamChange?.call(t);
        setState(() => _error = null);
      },
    );

    // Side-by-side on wide screens, stacked on phones.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return Row(
            children: [
              Expanded(child: seasonDropdown),
              const SizedBox(width: 12),
              Expanded(child: teamDropdown),
            ],
          );
        }
        return Column(
          children: [seasonDropdown, const SizedBox(height: 12), teamDropdown],
        );
      },
    );
  }

  Widget _matchupCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upcoming Matchup', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 24,
            runSpacing: 4,
            children: [
              _matchupItem('Date', _date),
              _matchupItem('Opponent', _opponent.isEmpty ? '-' : _opponent),
              _matchupItem(
                'Format',
                _gameType == GameType.regular ? 'Regular Season' : 'Playoffs',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _matchupItem(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: theme.textTheme.bodySmall),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _absenceRow() {
    return DropdownButtonFormField<AbsenceType>(
      initialValue: _absenceType,
      decoration: const InputDecoration(
        labelText: 'Absence Reason',
        border: OutlineInputBorder(),
      ),
      items: AbsenceType.values
          .map(
            (a) => DropdownMenuItem(
              value: a,
              child: Text(a == AbsenceType.none ? 'Active' : a.label),
            ),
          )
          .toList(),
      onChanged: (a) {
        setState(() {
          _absenceType = a ?? AbsenceType.none;
          if (_absenceType == AbsenceType.none) _skipMode = false;
        });
        _onAnyChange();
      },
    );
  }

  Widget _statFields(bool wide) {
    final fields = [
      StatField(label: 'Points', controller: _ptsCtrl),
      StatField(label: 'Assists', controller: _astCtrl),
      StatField(label: 'Rebounds', controller: _rebCtrl),
      StatField(label: 'Blocks', controller: _blkCtrl),
      StatField(label: 'Steals', controller: _stlCtrl),
      StatField(label: 'Minutes', controller: _minCtrl),
    ];
    if (wide) {
      // Two columns of three on wide screens.
      return Column(
        children: [
          for (var row = 0; row < 2; row++)
            Row(
              children: [
                for (var col = 0; col < 3; col++)
                  Expanded(child: fields[row * 3 + col]),
              ],
            ),
        ],
      );
    }
    return Column(children: fields);
  }

  Widget _skipConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const ValueKey('skip_count'),
                initialValue: '$_skipCount',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of Games',
                  border: const OutlineInputBorder(),
                  helperText: '$_availableSkipGames available',
                ),
                onChanged: (v) {
                  final requested = int.tryParse(v) ?? 1;
                  setState(() {
                    _skipCount = requested.clamp(
                      1,
                      _availableSkipGames == 0 ? 1 : _availableSkipGames,
                    );
                    _skipWins = (_skipCount / 2).ceil();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                key: const ValueKey('skip_wins'),
                initialValue: '$_skipWins',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Wins in interval',
                  border: const OutlineInputBorder(),
                  helperText:
                      '${_intervalWins}W-${_gamesInInterval - _intervalWins}L',
                ),
                onChanged: (v) {
                  setState(() {
                    _skipWins = (int.tryParse(v) ?? 1).clamp(
                      0,
                      _gamesInInterval,
                    );
                  });
                },
              ),
            ),
          ],
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Until Season End'),
          value: _skipToSeasonEnd,
          onChanged: (v) {
            setState(() {
              _skipToSeasonEnd = v ?? false;
              _skipWins = (_gamesInInterval / 2).ceil();
            });
          },
        ),
      ],
    );
  }
}

extension _GameCopy on GameStats {
  /// Shallow copy used by the bulk-skip builders (the spread `...game` in
  /// GameForm.tsx).
  GameStats copyWith({
    String? id,
    int? gameNumber,
    GameType? gameType,
    String? season,
    bool? isAbsent,
    bool? won,
  }) => GameStats(
    id: id ?? this.id,
    date: date,
    team: team,
    opponent: opponent,
    gameNumber: gameNumber ?? this.gameNumber,
    gameType: gameType ?? this.gameType,
    absenceType: isAbsent == true ? AbsenceType.rest : absenceType,
    isAbsent: isAbsent ?? this.isAbsent,
    points: isAbsent == true ? 0 : points,
    assists: isAbsent == true ? 0 : assists,
    rebounds: isAbsent == true ? 0 : rebounds,
    blocks: isAbsent == true ? 0 : blocks,
    steals: isAbsent == true ? 0 : steals,
    minutes: isAbsent == true ? 0 : minutes,
    won: won ?? this.won,
    isDoubleDouble: false,
    isTripleDouble: false,
    isBuzzerBeater: false,
    season: season ?? this.season,
  );
}
