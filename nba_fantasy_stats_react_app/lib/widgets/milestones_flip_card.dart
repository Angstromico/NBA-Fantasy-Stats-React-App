import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:nba_fantasy_stats_react_app/models/season_stats.dart';
import 'package:nba_fantasy_stats_react_app/widgets/glass_card.dart';

/// Statistical Milestones flip card — replicates the unified flip card in
/// `StatsDisplay.tsx` (Step 13 of FLUTTER_PLAN.md). Tapping flips between the
/// current season and career cumulative milestones with a 3D rotation
/// (`.flip-card-inner { transition: transform 0.75s cubic-bezier(...) }` and
/// `.milestones-flip-card.is-flipped { transform: rotateY(180deg) }`).
///
/// Both faces render the full `MilestoneFace` layout: four milestone columns
/// (points / assists / rebounds / defense), the elite-lines panel, and the
/// flip cue. The React card also flips with keyboard focus (Enter/Space);
/// in Flutter, focus is part of the tap semantics via [MilestonesFlipCard].
class MilestonesFlipCard extends StatefulWidget {
  const MilestonesFlipCard({
    super.key,
    required this.currentMilestones,
    required this.careerMilestones,
  });

  final StatisticalMilestones currentMilestones;
  final StatisticalMilestones careerMilestones;

  @override
  State<MilestonesFlipCard> createState() => _MilestonesFlipCardState();
}

class _MilestonesFlipCardState extends State<MilestonesFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  bool _flipped = false;

  /// `.milestones-flip-card .flip-card-inner` — 0.75s transition.
  static const Duration _flipDuration = Duration(milliseconds: 750);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _flipDuration);
    // The CSS easing `cubic-bezier(0.34, 1.25, 0.64, 1)` overshoots slightly;
    // [Curves.easeOutBack] is the closest Material curve.
    _rotation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() => _flipped = !_flipped);
    if (_flipped) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The React card is a `role='button'` div — expose the same semantics so
    // screen readers announce the flip interaction.
    return Semantics(
      button: true,
      label:
          'Statistical milestones card. Tap to flip between current '
          'season and all seasons totals.',
      child: GestureDetector(
        onTap: _flip,
        child: AnimatedBuilder(
          animation: _rotation,
          builder: (context, child) {
            final angle = _rotation.value * pi;
            // `backface-visibility: hidden` — swap faces at the halfway point
            // so the incoming face is never seen mirrored.
            final showBack = angle > pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateY(angle),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _MilestoneFace(
                        title: 'Statistical Milestones',
                        subtitle: 'All Seasons (Career Cumulative)',
                        milestones: widget.careerMilestones,
                        isBack: true,
                        flipCue:
                            'Click to flip and return to current season 🔄',
                      ),
                    )
                  : _MilestoneFace(
                      title: 'Statistical Milestones',
                      subtitle: 'Current Season (Active)',
                      milestones: widget.currentMilestones,
                      flipCue: 'Click to flip and view all seasons totals 🔄',
                    ),
            );
          },
        ),
      ),
    );
  }
}

/// One face of the flip card — mirrors the `MilestoneFace` component in
/// `StatsDisplay.tsx`.
class _MilestoneFace extends StatelessWidget {
  const _MilestoneFace({
    required this.title,
    required this.subtitle,
    required this.milestones,
    required this.flipCue,
    this.isBack = false,
  });

  final String title;
  final String subtitle;
  final StatisticalMilestones milestones;
  final String flipCue;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // `.milestones-face` uses the glass tokens via [GlassCard]; the back face
    // differentiates itself through the indigo (`secondary`) accent on the
    // badge, cue, and active counts (`.flip-card-face-back` styling).
    final accent = isBack ? colors.secondary : colors.primary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // `.milestones-flip-badge`
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _over(accent, 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _over(accent, 0.3)),
                ),
                child: Text(
                  isBack ? '🔄 Current Season' : '🔄 All Seasons',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // `.milestone-grid` — two columns on phone width, flowing to four
          // on tablets (the CSS grid auto-fits columns of at least 160px).
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 4 : 2;
              return Column(
                children: [
                  for (final group in _chunk(
                    _milestoneColumns(milestones, colors),
                    columns,
                  ))
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final column in group) Expanded(child: column),
                      ],
                    ),
                ],
              );
            },
          ),

          if (milestones.eliteLines.games.isNotEmpty) ...[
            const SizedBox(height: 16),
            _EliteLines(games: milestones.eliteLines.games),
          ],

          const SizedBox(height: 8),
          // `.flip-cue`
          Text(
            flipCue,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  static Color _over(Color base, double opacity) =>
      base.withValues(alpha: opacity);
}

/// The four milestone columns — Points Games / Assists Games / Rebounds
/// Games / Defense Games (Steals + Blocks sub-groups). Points above 70+ with
/// a zero count are hidden, exactly like the React `numThreshold >= 70 &&
/// count === 0` guard.
List<Widget> _milestoneColumns(
  StatisticalMilestones milestones,
  ColorScheme colors,
) {
  return [
    _MilestoneColumn(
      heading: 'Points Games',
      entries: _visibleEntries(milestones.points),
      colors: colors,
    ),
    _MilestoneColumn(
      heading: 'Assists Games',
      entries: _allEntries(milestones.assists),
      colors: colors,
    ),
    _MilestoneColumn(
      heading: 'Rebounds Games',
      entries: _allEntries(milestones.rebounds),
      colors: colors,
    ),
    _MilestoneColumn(
      heading: 'Defense Games',
      entries: const [],
      colors: colors,
      subGroups: [
        _MilestoneSubGroup(
          label: 'Steals',
          entries: _allEntries(milestones.steals),
        ),
        _MilestoneSubGroup(
          label: 'Blocks',
          entries: _allEntries(milestones.blocks),
        ),
      ],
    ),
  ];
}

/// All entries, active ones first classed `.milestone-active` (accent color,
/// bold) and zero counts rendered muted.
List<_MilestoneEntry> _allEntries(Map<String, int> counts) => [
  for (final entry in counts.entries)
    _MilestoneEntry(
      threshold: entry.key,
      count: entry.value,
      active: entry.value > 0,
    ),
];

/// Points entries with the React filter: thresholds ≥ 70 stay visible only
/// when they have counts.
List<_MilestoneEntry> _visibleEntries(Map<String, int> counts) {
  int thresholdValue(String key) =>
      int.tryParse(key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  return [
    for (final entry in counts.entries)
      if (!(thresholdValue(entry.key) >= 70 && entry.value == 0))
        _MilestoneEntry(
          threshold: entry.key,
          count: entry.value,
          active: entry.value > 0,
        ),
  ];
}

class _MilestoneEntry {
  const _MilestoneEntry({
    required this.threshold,
    required this.count,
    required this.active,
  });

  final String threshold;
  final int count;
  final bool active;
}

class _MilestoneSubGroup {
  const _MilestoneSubGroup({required this.label, required this.entries});

  final String label;
  final List<_MilestoneEntry> entries;
}

class _MilestoneColumn extends StatelessWidget {
  const _MilestoneColumn({
    required this.heading,
    required this.entries,
    required this.colors,
    this.subGroups = const [],
  });

  final String heading;
  final List<_MilestoneEntry> entries;
  final List<_MilestoneSubGroup> subGroups;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      entry.threshold,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: entry.active
                            ? colors.primary
                            : colors.onSurfaceVariant,
                        fontWeight: entry.active
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.count}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: entry.active
                          ? colors.primary
                          : colors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          for (final sub in subGroups) ...[
            const SizedBox(height: 6),
            Text(
              sub.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            for (final entry in sub.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        entry.threshold,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: entry.active
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          fontWeight: entry.active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.count}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: entry.active
                            ? colors.primary
                            : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// `.elite-lines` — the gold, glowing panel listing ultra-rare all-around
/// stat lines with per-tier badges.
class _EliteLines extends StatelessWidget {
  const _EliteLines({required this.games});

  final List<EliteLineGame> games;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // `--accent-tertiary`-adjacent gold used by `.elite-lines` borders and
    // the `.elite-line-badge` tones (amber palette from App.css).
    const gold = Color(0xFFFACC15);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold.withValues(alpha: 0.5)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gold.withValues(alpha: 0.12),
            const Color(0xFF4ADE80).withValues(alpha: 0.10),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👑 Ultra-Rare All-Around Lines',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final line in games)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: gold.withValues(alpha: 0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tierBadge(line.tier),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: line.tier == 'quadruple'
                          ? const Color(0xFFB45309)
                          : const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${line.date} · ${line.points} PTS · ${line.assists} AST '
                    '· ${line.rebounds} REB · ${line.blocks} BLK · '
                    '${line.steals} STL',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _tierBadge(String tier) {
    switch (tier) {
      case 'doubleQuintuple':
        return 'DOUBLE QUINTUPLE-DOUBLE';
      case 'quintuple':
        return 'QUINTUPLE-DOUBLE';
      default:
        return 'QUADRUPLE-DOUBLE';
    }
  }
}

/// Splits [items] into consecutive chunks of at most [size].
List<List<T>> _chunk<T>(List<T> items, int size) {
  if (items.isEmpty) return [];
  final chunks = <List<T>>[];
  for (var i = 0; i < items.length; i += size) {
    chunks.add(
      items.sublist(i, i + size > items.length ? items.length : i + size),
    );
  }
  return chunks;
}
