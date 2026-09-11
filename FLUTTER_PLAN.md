
# NBA Fantasy Stats — Flutter Android Migration Plan

> **Source:** React 18 + TypeScript + Vite web app  
> **Target:** Flutter 3.x — Android (API 24+)  
> **Style:** Glassmorphism, dark mode first, fluid adaptive layouts  
> **Reading audience:** LLM agents or developers picking up any step independently

---

## Quick Map: React → Flutter

| React layer | Flutter equivalent |
|---|---|
| `src/interfaces/` | `lib/models/` (Dart classes) |
| `src/utils/` | `lib/utils/` (pure Dart functions) |
| `src/data/` | `lib/data/` (static Dart maps / JSON assets) |
| `src/components/` | `lib/widgets/` (reusable widgets) |
| Route views (`tracker`, `summary`, `records`) | `lib/screens/` (full-page Dart screens) |
| `localStorage` | `shared_preferences` package |
| CSS variables + dark mode | `ThemeData` + `ColorScheme` tokens |
| `bcryptjs` | `bcrypt` Dart package |

---

## Prerequisites

- Flutter SDK >= 3.19 ([flutter.dev/docs/get-started](https://flutter.dev/docs/get-started))
- Android Studio or VS Code with Flutter + Dart extensions
- Android SDK API 34, with at least one virtual device (Pixel 6 API 34)
- Java 17+

Verify your setup:

```bash
flutter doctor -v
```

All checks must pass before Step 0.

---

## Step 0 — Scaffold the Flutter Project

**Purpose:** Create the Flutter project that will host all subsequent steps.

```bash
flutter create --org com.yourname --platforms android nba_fantasy_stats
cd nba_fantasy_stats
```

Immediately clean the generated boilerplate:

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NbaFantasyApp());
}
```

```dart
// lib/app.dart
import 'package:flutter/material.dart';

class NbaFantasyApp extends StatelessWidget {
  const NbaFantasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NBA Fantasy Stats',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: Text('NBA Fantasy Stats'))),
    );
  }
}
```

**Commit:**
```
chore: scaffold Flutter Android project with clean entry point
```

---

## Step 1 — Project Structure

**Purpose:** Mirror the React `src/` layout in Dart so every developer or LLM instantly recognises where code belongs.

Create these directories inside `lib/`:

```
lib/
├── app.dart
├── main.dart
├── models/
├── utils/
├── data/
├── widgets/
├── screens/
└── theme/
```

```bash
mkdir lib/models lib/utils lib/data lib/widgets lib/screens lib/theme
```

**Commit:**
```
chore: establish Flutter project directory structure matching React src layout
```

---

## Step 2 — Data Models

**Purpose:** Convert every TypeScript type in `src/interfaces/index.ts` to an equivalent Dart class with JSON serialization.

```dart
// lib/models/game_stats.dart
enum AbsenceType { none, rest, injury, personal, suspension, notCalledUp, lowerDivision, lesson }
enum GameType { regular, playoffs }

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
    required this.season,
  });

  factory GameStats.fromJson(Map<String, dynamic> json) => GameStats(
        id: json['id'] as String,
        date: json['date'] as String,
        team: json['team'] as String,
        opponent: json['opponent'] as String,
        gameNumber: json['gameNumber'] as int,
        gameType: GameType.values.byName(json['gameType'] as String),
        absenceType: AbsenceType.values.byName(_camelCase(json['absenceType'] as String)),
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
        season: json['season'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'team': team,
        'opponent': opponent,
        'gameNumber': gameNumber,
        'gameType': gameType.name,
        'absenceType': _snakeCase(absenceType.name),
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

  static String _camelCase(String s) =>
      s.replaceAllMapped(RegExp(r'_([a-z])'), (m) => m[1]!.toUpperCase());
  static String _snakeCase(String s) =>
      s.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
}
```

> Repeat the same pattern for `SeasonStats`, `CareerHighs`, `StatsSummary`, `User`, `Team`, and `PlayoffSeries`. Place each in its own file under `lib/models/`.

**Commit:**
```
feat(models): add Dart data models mirroring TypeScript interfaces
```

---

## Step 3 — Local Persistence Service

**Purpose:** Replace `localStorage` with `SharedPreferences`, keeping the same key-based JSON storage pattern used in `App.tsx`.

```yaml
# pubspec.yaml
dependencies:
  shared_preferences: ^2.2.3
```

```dart
// lib/utils/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _usersKey = 'users';
  static const _gamesKey = 'gameStats';

  static Future<List<dynamic>> readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    return jsonDecode(raw) as List<dynamic>;
  }

  static Future<void> writeJson(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static String get usersKey => _usersKey;
  static String get gamesKey => _gamesKey;
}
```

**Commit:**
```
feat(storage): add SharedPreferences storage service matching localStorage API
```

---

## Step 4 — Authentication Screen

**Purpose:** Replicate `Login.tsx` — username + password form with bcrypt verification, register/login modes.

```yaml
dependencies:
  bcrypt: ^1.1.3
```

```dart
// lib/screens/login_screen.dart
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats/utils/storage_service.dart';
import 'package:nba_fantasy_stats/widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String username) onAuthenticated;
  const LoginScreen({super.key, required this.onAuthenticated});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isRegister = false;
  String? _error;

  Future<void> _submit() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;
    if (username.isEmpty || password.isEmpty) return;

    final users = await StorageService.readList(StorageService.usersKey);

    if (_isRegister) {
      final exists = users.any((u) => (u as Map)['username'] == username);
      if (exists) {
        setState(() => _error = 'Username already taken');
        return;
      }
      final hashed = BCrypt.hashpw(password, BCrypt.gensalt());
      users.add({'username': username, 'hashedPassword': hashed});
      await StorageService.writeJson(StorageService.usersKey, users);
      widget.onAuthenticated(username);
    } else {
      final match = users.cast<Map>().where((u) => u['username'] == username).firstOrNull;
      if (match == null || !BCrypt.checkpw(password, match['hashedPassword'] as String)) {
        setState(() => _error = 'Invalid credentials');
        return;
      }
      widget.onAuthenticated(username);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_isRegister ? 'Create Account' : 'Welcome Back',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                TextField(controller: _userCtrl, decoration: const InputDecoration(labelText: 'Username')),
                const SizedBox(height: 12),
                TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: Colors.redAccent))],
                const SizedBox(height: 24),
                FilledButton(onPressed: _submit, child: Text(_isRegister ? 'Register' : 'Login')),
                TextButton(
                  onPressed: () => setState(() { _isRegister = !_isRegister; _error = null; }),
                  child: Text(_isRegister ? 'Already have an account? Login' : 'No account? Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Commit:**
```
feat(auth): add login/register screen with bcrypt credential verification
```

---

## Step 5 — Navigation Structure

**Purpose:** Replace the `AppView` union type (`tracker | summary | records`) with a `NavigationBar` — the standard Android pattern.

```dart
// lib/screens/main_shell.dart
import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats/screens/tracker_screen.dart';
import 'package:nba_fantasy_stats/screens/summary_screen.dart';
import 'package:nba_fantasy_stats/screens/records_screen.dart';

class MainShell extends StatefulWidget {
  final String username;
  const MainShell({super.key, required this.username});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.sports_basketball), label: 'Tracker'),
    NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Summary'),
    NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Records'),
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TrackerScreen(username: widget.username),
      SummaryScreen(username: widget.username),
      RecordsScreen(username: widget.username),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
```

**Commit:**
```
feat(nav): add bottom NavigationBar shell with tracker, summary, and records tabs
```

---

## Step 6 — Glassmorphism Theme & Dark Mode

**Purpose:** Convert the CSS custom properties from `src/index.css` into Flutter `ThemeData` with full dark mode support.

CSS variable to Flutter token mapping:
- `--bg-dark` -> `colorScheme.surface`
- `--bg-darker` -> `colorScheme.background`
- `--accent-primary` -> `colorScheme.primary`
- `--accent-secondary` -> `colorScheme.secondary`
- `--accent-tertiary` -> `colorScheme.tertiary`
- `--accent-error` -> `colorScheme.error`
- `--text-primary` -> `colorScheme.onSurface`
- `--text-secondary` -> `colorScheme.onSurfaceVariant`
- `--glass-bg` / `backdrop-filter` -> `GlassTheme` extension + `BackdropFilter`

```dart
// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

@immutable
class GlassTheme extends ThemeExtension<GlassTheme> {
  const GlassTheme({required this.glassColor, required this.glassBorder, required this.blurSigma});
  final Color glassColor;
  final Color glassBorder;
  final double blurSigma;

  @override
  GlassTheme copyWith({Color? glassColor, Color? glassBorder, double? blurSigma}) =>
      GlassTheme(glassColor: glassColor ?? this.glassColor, glassBorder: glassBorder ?? this.glassBorder, blurSigma: blurSigma ?? this.blurSigma);

  @override
  GlassTheme lerp(GlassTheme? other, double t) {
    if (other == null) return this;
    return GlassTheme(
      glassColor: Color.lerp(glassColor, other.glassColor, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
    );
  }
}

class AppTheme {
  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.dark,
          primary: const Color(0xFF38BDF8),
          secondary: const Color(0xFF818CF8),
          tertiary: const Color(0xFFF472B6),
          error: const Color(0xFFF87171),
          surface: const Color(0xFF0F172A),
        ),
        fontFamily: 'Inter',
        extensions: const [
          GlassTheme(glassColor: Color(0x33334155), glassBorder: Color(0x1AFFFFFF), blurSigma: 12),
        ],
      );

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          primary: const Color(0xFF0284C7),
          secondary: const Color(0xFF4F46E5),
          tertiary: const Color(0xFFDB2777),
          error: const Color(0xFFDC2626),
          surface: const Color(0xFFF1F5F9),
        ),
        fontFamily: 'Inter',
        extensions: const [
          GlassTheme(glassColor: Color(0xB3FFFFFF), glassBorder: Color(0x1A000000), blurSigma: 12),
        ],
      );
}
```

```dart
// lib/widgets/glass_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats/theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTheme>()!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: glass.blurSigma, sigmaY: glass.blurSigma),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: glass.glassColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: glass.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
```

**Commit:**
```
feat(theme): add glassmorphism ThemeData with dark/light mode matching CSS variable palette
```

---

## Step 7 — Game Tracker Screen

**Purpose:** Replicate `GameForm.tsx` — per-game stat logging with points, assists, rebounds, blocks, steals, game type, absence, and buzzer beater.

```dart
// lib/widgets/stat_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatField extends StatelessWidget {
  const StatField({super.key, required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
```

```dart
// lib/screens/tracker_screen.dart  (excerpt)
import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats/models/game_stats.dart';
import 'package:nba_fantasy_stats/utils/storage_service.dart';
import 'package:nba_fantasy_stats/widgets/glass_card.dart';
import 'package:nba_fantasy_stats/widgets/stat_field.dart';

class TrackerScreen extends StatefulWidget {
  final String username;
  const TrackerScreen({super.key, required this.username});
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
  bool _won = false;
  bool _buzzer = false;

  int _doubleCount(int pts, int ast, int reb, int blk, int stl) =>
      [pts, ast, reb, blk, stl].where((v) => v >= 10).length;

  Future<void> _submitGame() async {
    final pts = int.tryParse(_ptsCtrl.text) ?? 0;
    final ast = int.tryParse(_astCtrl.text) ?? 0;
    final reb = int.tryParse(_rebCtrl.text) ?? 0;
    final blk = int.tryParse(_blkCtrl.text) ?? 0;
    final stl = int.tryParse(_stlCtrl.text) ?? 0;
    final dc = _doubleCount(pts, ast, reb, blk, stl);
    final game = GameStats(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now().toIso8601String().substring(0, 10),
      team: 'MyTeam', opponent: 'Opponent', gameNumber: 1,
      gameType: _gameType, absenceType: AbsenceType.none, isAbsent: false,
      points: pts, assists: ast, rebounds: reb, blocks: blk, steals: stl,
      minutes: int.tryParse(_minCtrl.text) ?? 0,
      won: _won, isDoubleDouble: dc >= 2, isTripleDouble: dc >= 3,
      isBuzzerBeater: _buzzer, season: '2025-2026',
    );
    final existing = await StorageService.readList(StorageService.gamesKey);
    existing.add(game.toJson());
    await StorageService.writeJson(StorageService.gamesKey, existing);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          child: Column(children: [
            StatField(label: 'Points', controller: _ptsCtrl),
            StatField(label: 'Assists', controller: _astCtrl),
            StatField(label: 'Rebounds', controller: _rebCtrl),
            StatField(label: 'Blocks', controller: _blkCtrl),
            StatField(label: 'Steals', controller: _stlCtrl),
            StatField(label: 'Minutes', controller: _minCtrl),
            const SizedBox(height: 16),
            SegmentedButton<GameType>(
              segments: const [
                ButtonSegment(value: GameType.regular, label: Text('Regular')),
                ButtonSegment(value: GameType.playoffs, label: Text('Playoffs')),
              ],
              selected: {_gameType},
              onSelectionChanged: (s) => setState(() => _gameType = s.first),
            ),
            SwitchListTile(title: const Text('Won'), value: _won, onChanged: (v) => setState(() => _won = v)),
            SwitchListTile(title: const Text('Buzzer Beater'), value: _buzzer, onChanged: (v) => setState(() => _buzzer = v)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submitGame, child: const Text('Log Game')),
          ]),
        ),
      ),
    );
  }
}
```

**Commit:**
```
feat(tracker): add game logging screen with stat fields, game type, and absence toggle
```

---

## Step 8 — Stats Calculations (Dart Port)

**Purpose:** Port `src/utils/statsCalculations.ts` to pure Dart — no Flutter dependencies.

```dart
// lib/utils/stats_calculations.dart
import 'package:nba_fantasy_stats/models/game_stats.dart';

double _avg(List<int> values) =>
    values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;

({double pts, double ast, double reb, double blk, double stl, double min}) computeAverages(
    List<GameStats> games) {
  final played = games.where((g) => !g.isAbsent).toList();
  return (
    pts: _avg(played.map((g) => g.points).toList()),
    ast: _avg(played.map((g) => g.assists).toList()),
    reb: _avg(played.map((g) => g.rebounds).toList()),
    blk: _avg(played.map((g) => g.blocks).toList()),
    stl: _avg(played.map((g) => g.steals).toList()),
    min: _avg(played.map((g) => g.minutes).toList()),
  );
}

int computeCurrentStreak(List<GameStats> games) {
  if (games.isEmpty) return 0;
  final last = games.last;
  int streak = 1;
  for (int i = games.length - 2; i >= 0; i--) {
    if (games[i].won == last.won) streak++; else break;
  }
  return last.won ? streak : -streak;
}

int computeLongestWinStreak(List<GameStats> games) {
  int max = 0, cur = 0;
  for (final g in games) { cur = g.won ? cur + 1 : 0; if (cur > max) max = cur; }
  return max;
}

int computeLongestLossStreak(List<GameStats> games) {
  int max = 0, cur = 0;
  for (final g in games) { cur = !g.won ? cur + 1 : 0; if (cur > max) max = cur; }
  return max;
}

Map<String, int> computeMilestones(List<GameStats> games) {
  final p = games.where((g) => !g.isAbsent).toList();
  return {
    'pts10': p.where((g) => g.points >= 10).length,
    'pts20': p.where((g) => g.points >= 20).length,
    'pts30': p.where((g) => g.points >= 30).length,
    'pts40': p.where((g) => g.points >= 40).length,
    'pts50': p.where((g) => g.points >= 50).length,
    'ast5': p.where((g) => g.assists >= 5).length,
    'ast10': p.where((g) => g.assists >= 10).length,
    'reb5': p.where((g) => g.rebounds >= 5).length,
    'reb10': p.where((g) => g.rebounds >= 10).length,
    'blk2': p.where((g) => g.blocks >= 2).length,
    'stl2': p.where((g) => g.steals >= 2).length,
    'doubleDoubles': p.where((g) => g.isDoubleDouble).length,
    'tripleDoubles': p.where((g) => g.isTripleDouble).length,
  };
}
```

**Commit:**
```
feat(utils): port stats calculations to Dart — averages, streaks, milestones
```

---

## Step 9 — Season Summary Screen

**Purpose:** Replicate `StatsSummaryPage.tsx` — season selector, aggregate stats, career highs.

```dart
// lib/screens/summary_screen.dart
import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats/models/game_stats.dart';
import 'package:nba_fantasy_stats/utils/stats_calculations.dart';
import 'package:nba_fantasy_stats/utils/storage_service.dart';
import 'package:nba_fantasy_stats/widgets/glass_card.dart';
import 'package:nba_fantasy_stats/widgets/stat_row.dart';

class SummaryScreen extends StatefulWidget {
  final String username;
  const SummaryScreen({super.key, required this.username});
  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  List<GameStats> _games = [];
  String? _selectedSeason;

  @override
  void initState() { super.initState(); _loadGames(); }

  Future<void> _loadGames() async {
    final raw = await StorageService.readList(StorageService.gamesKey);
    setState(() {
      _games = raw.map((j) => GameStats.fromJson(j as Map<String, dynamic>)).toList();
    });
  }

  List<String> get _seasons => _games.map((g) => g.season).toSet().toList()..sort();
  List<GameStats> get _filtered =>
      _selectedSeason == null ? _games : _games.where((g) => g.season == _selectedSeason).toList();

  @override
  Widget build(BuildContext context) {
    final avgs = computeAverages(_filtered);
    final winStreak = computeLongestWinStreak(_filtered);
    final played = _filtered.where((g) => !g.isAbsent).length;
    final wins = _filtered.where((g) => !g.isAbsent && g.won).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Season Summary')),
      body: RefreshIndicator(
        onRefresh: _loadGames,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_seasons.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedSeason,
                hint: const Text('All Seasons'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Seasons')),
                  ..._seasons.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                ],
                onChanged: (s) => setState(() => _selectedSeason = s),
              ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stats Overview', style: Theme.of(context).textTheme.titleMedium),
                  StatRow(label: 'Games Played', value: played.toString()),
                  StatRow(label: 'Wins', value: '$wins / $played'),
                  StatRow(label: 'PPG', value: avgs.pts.toStringAsFixed(1)),
                  StatRow(label: 'APG', value: avgs.ast.toStringAsFixed(1)),
                  StatRow(label: 'RPG', value: avgs.reb.toStringAsFixed(1)),
                  StatRow(label: 'Best Win Streak', value: winStreak.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

```dart
// lib/widgets/stat_row.dart
import 'package:flutter/material.dart';

class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```

**Commit:**
```
feat(summary): add season summary screen with stat overview and season filter
```

---

## Step 10 — Records & Leaderboards Screen

**Purpose:** Replicate `RecordsDisplay.tsx` and `AllTimeLeaderboards.tsx`. Port `src/utils/leaderboardCalculations.ts` to `lib/utils/leaderboard_calculations.dart`.

```dart
// lib/screens/records_screen.dart
import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats/widgets/glass_card.dart';
import 'package:nba_fantasy_stats/widgets/stat_row.dart';

class RecordsScreen extends StatelessWidget {
  final String username;
  const RecordsScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Records')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All-Time Leaderboards', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const StatRow(label: 'Points Leader', value: '—'),
                const StatRow(label: 'Assists Leader', value: '—'),
                const StatRow(label: 'Rebounds Leader', value: '—'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

> Port each function from `src/utils/leaderboardCalculations.ts` as a standalone Dart function in `lib/utils/leaderboard_calculations.dart`. The logic is identical — only the syntax changes (TypeScript -> Dart).

**Commit:**
```
feat(records): add records and leaderboards screen scaffold with glass card layout
```

---

## Step 11 — Champion Comparison Widget

**Purpose:** Replicate `ComparisonDisplay.tsx`. Use **only** the current season's games — never career totals.

```dart
// lib/widgets/champion_comparison.dart
import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats/models/game_stats.dart';
import 'package:nba_fantasy_stats/widgets/glass_card.dart';
import 'package:nba_fantasy_stats/widgets/stat_row.dart';

class ChampionComparison extends StatelessWidget {
  final List<GameStats> currentSeasonGames;
  final String championTeam;
  final String championRecord;
  const ChampionComparison({
    super.key,
    required this.currentSeasonGames,
    required this.championTeam,
    required this.championRecord,
  });

  @override
  Widget build(BuildContext context) {
    final played = currentSeasonGames.where((g) => !g.isAbsent);
    final wins = played.where((g) => g.won).length;
    final losses = played.where((g) => !g.won).length;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Team Performance vs Champion', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StatRow(label: 'Your Record', value: '$wins-$losses'),
          StatRow(label: '$championTeam (Champion)', value: championRecord),
        ],
      ),
    );
  }
}
```

**Commit:**
```
feat(comparison): add champion comparison widget using current season record only
```

---

## Step 12 — Glassmorphism Confirmation Dialogs

**Purpose:** Replicate `ConfirmationModal.tsx` — danger/warning/info tones for season reset and season change.

```dart
// lib/widgets/confirmation_dialog.dart
import 'package:flutter/material.dart';

enum ConfirmTone { danger, warning, info }

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.tone,
    this.details,
    required this.confirmLabel,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final ConfirmTone tone;
  final String? details;
  final String confirmLabel;
  final VoidCallback onConfirm;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required ConfirmTone tone,
    String? details,
    String confirmLabel = 'Confirm',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmationDialog(
        title: title, message: message, tone: tone, details: details,
        confirmLabel: confirmLabel, onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    return result ?? false;
  }

  Color _toneColor(BuildContext context) => switch (tone) {
        ConfirmTone.danger => Theme.of(context).colorScheme.error,
        ConfirmTone.warning => Colors.amber,
        ConfirmTone.info => Theme.of(context).colorScheme.primary,
      };

  IconData _toneIcon() => switch (tone) {
        ConfirmTone.danger => Icons.warning_rounded,
        ConfirmTone.warning => Icons.info_rounded,
        ConfirmTone.info => Icons.help_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _toneColor(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Icon(_toneIcon(), color: accent, size: 40),
      title: Text(title, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (details != null) ...[const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Text(details!, style: Theme.of(context).textTheme.bodySmall),
            )],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: accent),
          onPressed: () { onConfirm(); Navigator.of(context).pop(true); },
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
```

Usage — season reset:
```dart
final confirmed = await ConfirmationDialog.show(
  context,
  title: 'Reset Season',
  message: 'This will erase all games in the current season.',
  tone: ConfirmTone.danger,
  details: 'This action cannot be undone.',
  confirmLabel: 'Reset',
);
if (confirmed) _resetSeason();
```

**Commit:**
```
feat(ui): add glassmorphism confirmation dialog for season reset and change with tone variants
```

---

## Step 13 — Statistical Milestones Flip Card

**Purpose:** Replicate the unified flip card in `StatsDisplay.tsx` — tap flips between current season and career milestones with a 3D rotation animation.

```dart
// lib/widgets/milestones_flip_card.dart
import 'dart:math' show pi;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats/widgets/glass_card.dart';

class MilestonesFlipCard extends StatefulWidget {
  const MilestonesFlipCard({
    super.key,
    required this.currentMilestones,
    required this.careerMilestones,
  });
  final Map<String, int> currentMilestones;
  final Map<String, int> careerMilestones;

  @override
  State<MilestonesFlipCard> createState() => _MilestonesFlipCardState();
}

class _MilestonesFlipCardState extends State<MilestonesFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rotation;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _rotation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _flip() {
    setState(() => _flipped = !_flipped);
    _flipped ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (_, __) {
          final angle = _rotation.value * pi;
          final showBack = angle > pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _MilestoneFace(
                      title: 'Career Milestones',
                      milestones: widget.careerMilestones,
                      badge: 'Tap for Current Season',
                    ),
                  )
                : _MilestoneFace(
                    title: 'Current Season',
                    milestones: widget.currentMilestones,
                    badge: 'Tap for Career',
                  ),
          );
        },
      ),
    );
  }
}

class _MilestoneFace extends StatelessWidget {
  const _MilestoneFace({required this.title, required this.milestones, required this.badge});
  final String title;
  final Map<String, int> milestones;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Chip(label: Text(badge, style: const TextStyle(fontSize: 11))),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: milestones.entries
                .where((e) => e.value > 0)
                .map((e) => Chip(
                      label: Text('${e.key}: ${e.value}',
                          style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
```

**Commit:**
```
feat(milestones): add 3D flip card toggling current season and career milestone stats
```

---

## Step 14 — Player Top Stats Section

**Purpose:** Port `PlayerTopStatsSection.tsx` and `playerTopStatsCalculations.ts` — top games per stat, threshold streaks, win/loss/absence streaks.

```dart
// lib/utils/player_top_stats.dart
import 'package:nba_fantasy_stats/models/game_stats.dart';

typedef TopGame = ({GameStats game, int value});

List<TopGame> topGamesByPoints(List<GameStats> games, {int take = 5}) {
  final played = games.where((g) => !g.isAbsent).toList()
    ..sort((a, b) => b.points.compareTo(a.points));
  return played.take(take).map((g) => (game: g, value: g.points)).toList();
}

List<TopGame> topGamesByAssists(List<GameStats> games, {int take = 5}) {
  final played = games.where((g) => !g.isAbsent).toList()
    ..sort((a, b) => b.assists.compareTo(a.assists));
  return played.take(take).map((g) => (game: g, value: g.assists)).toList();
}

int longestThresholdStreak(List<GameStats> games, int Function(GameStats) stat, int threshold) {
  int max = 0, cur = 0;
  for (final g in games) {
    if (!g.isAbsent && stat(g) >= threshold) { cur++; if (cur > max) max = cur; } else { cur = 0; }
  }
  return max;
}
```

```dart
// lib/widgets/player_top_stats_section.dart
import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats/models/game_stats.dart';
import 'package:nba_fantasy_stats/utils/player_top_stats.dart';
import 'package:nba_fantasy_stats/widgets/glass_card.dart';

class PlayerTopStatsSection extends StatefulWidget {
  final List<GameStats> games;
  const PlayerTopStatsSection({super.key, required this.games});
  @override
  State<PlayerTopStatsSection> createState() => _PlayerTopStatsSectionState();
}

class _PlayerTopStatsSectionState extends State<PlayerTopStatsSection> {
  String _scope = 'All';

  List<GameStats> get _scoped => switch (_scope) {
        'Regular' => widget.games.where((g) => g.gameType == GameType.regular).toList(),
        'Playoffs' => widget.games.where((g) => g.gameType == GameType.playoffs).toList(),
        _ => widget.games,
      };

  @override
  Widget build(BuildContext context) {
    final top5 = topGamesByPoints(_scoped);
    final streak10 = longestThresholdStreak(_scoped, (g) => g.points, 10);
    final streak20 = longestThresholdStreak(_scoped, (g) => g.points, 20);

    return Column(
      children: [
        SegmentedButton<String>(
          segments: ['All', 'Regular', 'Playoffs']
              .map((s) => ButtonSegment(value: s, label: Text(s)))
              .toList(),
          selected: {_scope},
          onSelectionChanged: (s) => setState(() => _scope = s.first),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top Scoring Games', style: Theme.of(context).textTheme.titleSmall),
              ...top5.map((t) => ListTile(
                    dense: true,
                    leading: Text('${t.value} PTS',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                    title: Text('vs ${t.game.opponent}'),
                    subtitle: Text(t.game.date),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Points Streaks', style: Theme.of(context).textTheme.titleSmall),
              ListTile(dense: true, title: const Text('10+ PTS streak'), trailing: Text('$streak10 games')),
              ListTile(dense: true, title: const Text('20+ PTS streak'), trailing: Text('$streak20 games')),
            ],
          ),
        ),
      ],
    );
  }
}
```

**Commit:**
```
feat(summary): add player top stats section with top games, threshold streaks, and scope filter
```

---

## Step 15 — Build & Release APK

**Purpose:** Produce a signed release APK for sideloading or Play Store upload.

### 15.1 — Generate a Signing Key

```bash
keytool -genkey -v \
  -keystore android/app/nba_fantasy.jks \
  -alias nba_fantasy \
  -keyalg RSA -keysize 2048 \
  -validity 10000
```

### 15.2 — Configure Gradle Signing

```properties
# android/key.properties  — DO NOT commit; add to .gitignore
storePassword=<your_store_password>
keyPassword=<your_key_password>
keyAlias=nba_fantasy
storeFile=nba_fantasy.jks
```

```groovy
// android/app/build.gradle — inside android { ... }
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
    }
}
```

### 15.3 — Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 15.4 — Build App Bundle (Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### 15.5 — Quality Checks Before Release

```bash
flutter analyze          # static analysis (equivalent to npm run lint)
flutter test             # unit tests
dart format --set-exit-if-changed lib/
```

**Commit:**
```
chore(release): configure APK signing and add release build instructions
```

---

## Supporting Files

| File | Purpose |
|---|---|
| [`flutter/SKILL.md`](./flutter/SKILL.md) | Engineering standards for the Flutter project, for Antigravity/Gemini agents |
| [`flutter/GEMINI.md`](./flutter/GEMINI.md) | Workspace rules for AI models working on the Flutter codebase |

---

## Full Feature Checklist

| Feature | React component | Flutter target |
|---|---|---|
| Login / Register | `Login.tsx` | `LoginScreen` |
| Game Tracker | `GameForm.tsx` | `TrackerScreen` |
| Stats Overview | `StatsDisplay.tsx` | `SummaryScreen` |
| Champion Comparison | `ComparisonDisplay.tsx` | `ChampionComparison` |
| Season Summary | `StatsSummaryPage.tsx` | `SummaryScreen` |
| Player Top Stats | `PlayerTopStatsSection.tsx` | `PlayerTopStatsSection` |
| Records | `RecordsDisplay.tsx` | `RecordsScreen` |
| Leaderboards | `AllTimeLeaderboards.tsx` | `RecordsScreen` + `lib/utils/leaderboard_calculations.dart` |
| Confirmation Modal | `ConfirmationModal.tsx` | `ConfirmationDialog` |
| Milestones Flip Card | `StatsDisplay.tsx` | `MilestonesFlipCard` |
| Dark / Light mode | CSS variables + `body.dark-mode` | `ThemeData` + `ThemeMode` |
| Glassmorphism | CSS `backdrop-filter` | `BackdropFilter` + `GlassCard` |
