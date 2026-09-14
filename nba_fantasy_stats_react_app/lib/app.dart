import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/data/nba_data.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/screens/login_screen.dart';
import 'package:nba_fantasy_stats_react_app/screens/main_shell.dart';
import 'package:nba_fantasy_stats_react_app/theme/app_theme.dart';
import 'package:nba_fantasy_stats_react_app/utils/game_progression.dart';
import 'package:nba_fantasy_stats_react_app/utils/leaderboard_calculations.dart';
import 'package:nba_fantasy_stats_react_app/utils/record_calculations.dart';
import 'package:nba_fantasy_stats_react_app/utils/storage_service.dart';
import 'package:nba_fantasy_stats_react_app/widgets/congrats_banner.dart';
import 'package:nba_fantasy_stats_react_app/widgets/confirmation_dialog.dart';

/// Root widget replicating `App.tsx`: login gate, persisted dark mode and
/// team/season selection, game progression after logging games, and the
/// glass header with view switching.
class NbaFantasyApp extends StatefulWidget {
  const NbaFantasyApp({super.key});

  @override
  State<NbaFantasyApp> createState() => _NbaFantasyAppState();
}

class _NbaFantasyAppState extends State<NbaFantasyApp> {
  /// Like the React app's `darkMode` state — dark until the stored flag
  /// says otherwise (`body.dark-mode` default).
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    _restoreDarkMode();
  }

  Future<void> _restoreDarkMode() async {
    final darkRaw = await StorageService.readString(StorageService.darkModeKey);
    if (!mounted) return;
    setState(() => _darkMode = darkRaw != 'false');
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => _darkMode = value);
    await StorageService.writeString(StorageService.darkModeKey, '$value');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NBA Fantasy Stats',
      debugShowCheckedModeBanner: false,
      // Dark mode first — the React app defaults to `body.dark-mode`.
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: AppHomePage(
        darkMode: _darkMode,
        onToggleDarkMode: () => _setDarkMode(!_darkMode),
      ),
    );
  }
}

/// The authenticated-app root: session state, game state, and the glass
/// header. When logged out it renders the login screen alone (the React
/// early return in App.tsx).
class AppHomePage extends StatefulWidget {
  const AppHomePage({
    super.key,
    required this.darkMode,
    required this.onToggleDarkMode,
  });

  final bool darkMode;
  final VoidCallback onToggleDarkMode;

  @override
  State<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends State<AppHomePage> {
  bool _loaded = false;
  String? _currentUser;
  String _selectedTeam = '';
  String _selectedSeason = '';
  List<GameStats> _games = [];

  List<RecordComparison> _recordsCongrats = const [];
  List<TopTwentyEntrance> _topTwentyCongrats = const [];

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  /// The `useEffect(() => { ... }, [])` mount block in App.tsx.
  Future<void> _restoreSession() async {
    final user = await StorageService.readString(StorageService.currentUserKey);
    final team = await StorageService.readString(
      StorageService.selectedTeamKey,
    );
    final season = await StorageService.readString(
      StorageService.selectedSeasonKey,
    );
    final rawGames = await StorageService.readList(StorageService.gamesKey);
    final games = rawGames
        .whereType<Map<String, dynamic>>()
        .map(GameStats.fromJson)
        .toList();

    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _selectedTeam = team ?? '';
      _selectedSeason = season ?? '';
      _games = games;
      _loaded = true;
    });
  }

  Future<void> _saveGames(List<GameStats> games) async {
    _games = games;
    await StorageService.writeJson(
      StorageService.gamesKey,
      games.map((g) => g.toJson()).toList(),
    );
  }

  Future<void> _onAuthenticated(String username) async {
    await StorageService.writeString(StorageService.currentUserKey, username);
    if (!mounted) return;
    setState(() => _currentUser = username);
  }

  Future<void> _logout() async {
    await StorageService.remove(StorageService.currentUserKey);
    if (!mounted) return;
    setState(() => _currentUser = null);
  }

  /// `addGameStats` in App.tsx: filters playoff games against the current
  /// progression, saves, fires congrats banners, and advances the
  /// team/season state.
  Future<void> _addGameStats(List<GameStats> incoming) async {
    final gamesToAdd = filterPlayableGames(_games, incoming);

    if (gamesToAdd.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No playoff games were added because the current playoff run is '
            'already complete.',
          ),
        ),
      );
      return;
    }

    final newStats = [..._games, ...gamesToAdd];

    // Celebrate newly broken NBA records (not ones already achieved before).
    final previouslyBroken = getBrokenRecords(
      _games,
    ).map((c) => c.record.id).toSet();
    final newlyBroken = getBrokenRecords(
      newStats,
    ).where((c) => !previouslyBroken.contains(c.record.id)).toList();

    // Celebrate games cracking an all-time top-20 leaderboard.
    final entrances = computeTopTwentyEntrances(gamesToAdd);

    final lastGame = gamesToAdd.last;
    final nextGame = computeNextGame(newStats, lastGame.team, lastGame.season);

    await _saveGames(newStats);
    if (!mounted) return;
    setState(() {
      _games = newStats;
      _selectedTeam = lastGame.team;
      _selectedSeason = lastGame.season;
      if (newlyBroken.isNotEmpty) _recordsCongrats = newlyBroken;
      if (entrances.isNotEmpty) _topTwentyCongrats = entrances;
    });

    if (nextGame.message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(nextGame.message!)));
    }
  }

  /// `handleTeamChange` in App.tsx.
  Future<void> _handleTeamChange(String team) async {
    await StorageService.writeString(StorageService.selectedTeamKey, team);
    if (!mounted) return;
    setState(() => _selectedTeam = team);
  }

  /// `handleSeasonChange` in App.tsx — warns when switching to a past
  /// season or advancing early past an incomplete season.
  Future<void> _handleSeasonChange(String targetSeason) async {
    if (targetSeason.isEmpty) return;
    if (targetSeason == _selectedSeason) return;

    final seasons = getAvailableSeasons();
    final currentIndex = seasons.indexOf(_selectedSeason);
    final targetIndex = seasons.indexOf(targetSeason);

    // Switching back to a past season.
    if (currentIndex >= 0 && targetIndex >= 0 && targetIndex < currentIndex) {
      final confirmed = await ConfirmationDialog.show(
        context,
        title: 'Switch to Past Season',
        message: 'You are switching back to the $targetSeason season.',
        details:
            'Past seasons are completed and cannot have new games added '
            'unless you reset that season to start over.',
        confirmLabel: 'Switch to $targetSeason',
        cancelLabel: 'Stay on Current Season',
        tone: ConfirmTone.warning,
      );
      if (!confirmed) return;
    }

    // Advancing to a future season with an incomplete current season
    // forfeits the remaining games as absences.
    if (currentIndex >= 0 && targetIndex >= 0 && targetIndex > currentIndex) {
      final teamObj = teamByLabel(_selectedTeam);
      final regularPlayed = teamObj == null
          ? 0
          : _games
                .where(
                  (g) =>
                      g.team == _selectedTeam &&
                      g.season == _selectedSeason &&
                      g.gameType == GameType.regular,
                )
                .length;

      if (regularPlayed < regularSeasonGameCount) {
        final unplayed = regularSeasonGameCount - regularPlayed;
        if (!mounted) return;
        final confirmed = await ConfirmationDialog.show(
          context,
          title: 'Advance Season Early',
          message:
              'The current season ($_selectedSeason) is not finished '
              '($regularPlayed/$regularSeasonGameCount games played).',
          details:
              'Switching to $targetSeason will forfeit the remaining '
              '$unplayed game(s) as missed games (losses by absence).',
          confirmLabel: 'Forfeit & Advance to $targetSeason',
          cancelLabel: 'Stay on Current Season',
          tone: ConfirmTone.warning,
        );
        if (!confirmed) return;

        // Build the forfeited absence games from the schedule
        // (`onConfirm` in App.tsx's `Advance Season Early` modal).
        final schedule = teamObj == null
            ? <ScheduledGame>[]
            : getTeamRegularSeasonSchedule(teamObj.id, _selectedSeason);
        final forfeited = List<GameStats>.generate(unplayed, (i) {
          final index = regularPlayed + i;
          final scheduled = schedule.elementAtOrNull(index);
          return GameStats(
            id: '${DateTime.now().microsecondsSinceEpoch}_ff$i',
            date:
                scheduled?.date ??
                DateTime.now().toIso8601String().substring(0, 10),
            team: _selectedTeam,
            opponent: scheduled?.opponent ?? 'Opponent',
            gameNumber: index + 1,
            gameType: GameType.regular,
            absenceType: AbsenceType.rest,
            isAbsent: true,
            points: 0,
            assists: 0,
            rebounds: 0,
            blocks: 0,
            steals: 0,
            minutes: 0,
            won: false,
            isDoubleDouble: false,
            isTripleDouble: false,
            isBuzzerBeater: false,
            season: _selectedSeason,
          );
        });
        await _addGameStats(forfeited);
      }
    }

    await StorageService.writeString(
      StorageService.selectedSeasonKey,
      targetSeason,
    );
    if (!mounted) return;
    setState(() => _selectedSeason = targetSeason);
  }

  /// `handleResetSeason` in App.tsx — deletes the season's games for the
  /// selected team and restarts from Game 1.
  Future<void> _handleResetSeason(String seasonToReset) async {
    final remaining = _games
        .where(
          (g) =>
              !(g.season == seasonToReset &&
                  (_selectedTeam.isEmpty || g.team == _selectedTeam)),
        )
        .toList();
    await _saveGames(remaining);
    if (!mounted) return;
    setState(() => _games = remaining);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$seasonToReset season for $_selectedTeam has been reset. '
          'Starting fresh from Game 1.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      // The React app renders `<Login … />` alone when logged out.
      return LoginScreen(onAuthenticated: _onAuthenticated);
    }

    final wide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(wide),
            _congratsBanners(),
            Expanded(
              child: MainShell(
                username: _currentUser!,
                selectedTeam: _selectedTeam,
                selectedSeason: _selectedSeason,
                onTeamChange: _handleTeamChange,
                onSeasonChange: _handleSeasonChange,
                onResetSeason: _handleResetSeason,
                onGamesLogged: _addGameStats,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The glass `header` in App.tsx: title, welcome, theme toggle, logout.
  Widget _header(bool wide) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MVP Race NBA', style: theme.textTheme.titleLarge),
                Text(
                  'Welcome, $_currentUser',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleDarkMode,
            icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18),
            label: wide ? const Text('Logout') : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// The `congrats-banner` blocks rendered over the tracker in App.tsx.
  Widget _congratsBanners() {
    if (_recordsCongrats.isEmpty && _topTwentyCongrats.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassBannerCard(
        records: _recordsCongrats,
        entrances: _topTwentyCongrats,
        onDismiss: () => setState(() {
          _recordsCongrats = const [];
          _topTwentyCongrats = const [];
        }),
        textStyle: theme.textTheme.bodyMedium!,
      ),
    );
  }
}
