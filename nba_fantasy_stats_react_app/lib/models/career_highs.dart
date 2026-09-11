/// Career-best aggregate values — mirrors `CareerHighs` in `src/interfaces/index.ts`.
class CareerHighs {
  final int points;
  final int assists;
  final int rebounds;
  final int blocks;
  final int steals;
  final int minutes;
  final int doubleDoubles;
  final int tripleDoubles;

  const CareerHighs({
    required this.points,
    required this.assists,
    required this.rebounds,
    required this.blocks,
    required this.steals,
    required this.minutes,
    required this.doubleDoubles,
    required this.tripleDoubles,
  });

  factory CareerHighs.fromJson(Map<String, dynamic> json) => CareerHighs(
        points: json['points'] as int,
        assists: json['assists'] as int,
        rebounds: json['rebounds'] as int,
        blocks: json['blocks'] as int,
        steals: json['steals'] as int,
        minutes: json['minutes'] as int,
        doubleDoubles: json['doubleDoubles'] as int,
        tripleDoubles: json['tripleDoubles'] as int,
      );

  Map<String, dynamic> toJson() => {
        'points': points,
        'assists': assists,
        'rebounds': rebounds,
        'blocks': blocks,
        'steals': steals,
        'minutes': minutes,
        'doubleDoubles': doubleDoubles,
        'tripleDoubles': tripleDoubles,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareerHighs &&
          points == other.points &&
          assists == other.assists &&
          rebounds == other.rebounds &&
          blocks == other.blocks &&
          steals == other.steals &&
          minutes == other.minutes &&
          doubleDoubles == other.doubleDoubles &&
          tripleDoubles == other.tripleDoubles;

  @override
  int get hashCode => Object.hash(points, assists, rebounds, blocks, steals,
      minutes, doubleDoubles, tripleDoubles);
}
