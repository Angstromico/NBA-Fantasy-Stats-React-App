import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/models/enums.dart';
import 'package:nba_fantasy_stats_react_app/models/game_stats.dart';
import 'package:nba_fantasy_stats_react_app/utils/storage_service.dart';
import 'package:nba_fantasy_stats_react_app/widgets/glass_card.dart';
import 'package:nba_fantasy_stats_react_app/widgets/stat_field.dart';

/// Game logging screen replicating `GameForm.tsx` (Step 7 of
/// FLUTTER_PLAN.md): per-game stat entry with auto-derived double/triple
/// doubles, buzzer-beater win lock, and absence handling that zeroes stats.
class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key, required this.username});

  final String username;

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
  String? _error;
  int _gamesLogged = 0;

  @override
  void initState() {
    super.initState();
    _loadGameCount();
  }

  @override
  void dispose() {
    for (final c in [_ptsCtrl, _astCtrl, _rebCtrl, _blkCtrl, _stlCtrl, _minCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadGameCount() async {
    final games = await StorageService.readList(StorageService.gamesKey);
    if (mounted) setState(() => _gamesLogged = games.length);
  }

  int _parse(TextEditingController c) => int.tryParse(c.text) ?? 0;

  bool get _isAbsent => _absenceType != AbsenceType.none;

  /// Mirrors `updateStats` in GameForm.tsx: buzzer beater locks the win;
  /// absence zeroes all stat categories and clears derived flags.
  void _onAnyChange() {
    setState(() {
      if (_buzzer) _won = true;
      if (_isAbsent) {
        _won = false;
        _buzzer = false;
        for (final c in [_ptsCtrl, _astCtrl, _rebCtrl, _blkCtrl, _stlCtrl, _minCtrl]) {
          c.text = '';
        }
      }
      _error = null;
    });
  }

  Future<void> _submitGame() async {
    final pts = _parse(_ptsCtrl);
    final ast = _parse(_astCtrl);
    final reb = _parse(_rebCtrl);
    final blk = _parse(_blkCtrl);
    final stl = _parse(_stlCtrl);
    final min = _parse(_minCtrl);
    final dc = [pts, ast, reb, blk, stl].where((v) => v >= 10).length;

    final game = GameStats(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime.now().toIso8601String().substring(0, 10),
      // team/opponent/season selection arrive with the data step
      team: widget.username,
      opponent: 'Free agent',
      gameNumber: _gamesLogged + 1,
      gameType: _gameType,
      absenceType: _absenceType,
      isAbsent: _isAbsent,
      points: pts,
      assists: ast,
      rebounds: reb,
      blocks: blk,
      steals: stl,
      minutes: min,
      won: _won,
      isDoubleDouble: !_isAbsent && dc >= 2,
      isTripleDouble: !_isAbsent && dc >= 3,
      isBuzzerBeater: !_isAbsent && _buzzer,
      season: '2025-2026', // season selection arrives with the data step
    );

    final existing = await StorageService.readList(StorageService.gamesKey);
    existing.add(game.toJson());
    await StorageService.writeJson(StorageService.gamesKey, existing);

    if (!mounted) return;
    setState(() {
      for (final c in [_ptsCtrl, _astCtrl, _rebCtrl, _blkCtrl, _stlCtrl, _minCtrl]) {
        c.clear();
      }
      _absenceType = AbsenceType.none;
      _won = false;
      _buzzer = false;
      _gamesLogged++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Tracker'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('${widget.username} · $_gamesLogged logged',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                onSelectionChanged: (s) =>
                    setState(() => _gameType = s.first),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<AbsenceType>(
                initialValue: _absenceType,
                decoration: const InputDecoration(
                  labelText: 'Absence Reason',
                  border: OutlineInputBorder(),
                ),
                items: AbsenceType.values
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(
                            a == AbsenceType.none ? 'Not absent' : a.label,
                          ),
                        ))
                    .toList(),
                onChanged: (a) {
                  setState(() => _absenceType = a ?? AbsenceType.none);
                  _onAnyChange();
                },
              ),
              SwitchListTile(
                title: const Text('Won'),
                value: _won,
                onChanged: (v) {
                  setState(() => _won = v);
                  _onAnyChange();
                },
              ),
              SwitchListTile(
                title: const Text('Buzzer Beater'),
                value: _buzzer,
                onChanged: (v) {
                  setState(() => _buzzer = v);
                  _onAnyChange();
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitGame,
                child: const Text('Log Game'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
