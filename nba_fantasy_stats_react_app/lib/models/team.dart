/// NBA team — mirrors `Team` in `src/interfaces/index.ts`.
class Team {
  final String id;
  final String name;
  final String city;
  final String conference; // 'Eastern' | 'Western'
  final String division;

  const Team({
    required this.id,
    required this.name,
    required this.city,
    required this.conference,
    required this.division,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        name: json['name'] as String,
        city: json['city'] as String,
        conference: json['conference'] as String,
        division: json['division'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'conference': conference,
        'division': division,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team &&
          id == other.id &&
          name == other.name &&
          city == other.city &&
          conference == other.conference &&
          division == other.division;

  @override
  int get hashCode => Object.hash(id, name, city, conference, division);
}
