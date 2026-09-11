/// Category of absence for a game where the player did not take the court.
///
/// Serialized to/from JSON as the snake_case values used by the React app's
/// localStorage data (e.g. `not_called_up`, `lower_division`).
enum AbsenceType {
  none,
  rest,
  injury,
  personal,
  suspension,
  notCalledUp,
  lowerDivision,
  lesson;

  /// JSON value used by the React app (snake_case).
  String get wireName => switch (this) {
        AbsenceType.notCalledUp => 'not_called_up',
        AbsenceType.lowerDivision => 'lower_division',
        _ => name,
      };

  /// Human-readable label, mirroring the React app's
  /// `absenceType.replace(/_/g, ' ')` rendering.
  String get label => wireName.replaceAll('_', ' ');

  /// Parses a wire value, tolerating both snake_case and camelCase input.
  static AbsenceType fromWire(String value) => AbsenceType.values.firstWhere(
        (e) => e.wireName == value || e.name == value,
        orElse: () => AbsenceType.none,
      );
}

/// Whether a game belongs to the regular season or the playoffs.
enum GameType {
  regular,
  playoffs;

  /// JSON value used by the React app.
  String get wireName => name;

  /// Parses a wire value.
  static GameType fromWire(String value) => GameType.values.firstWhere(
        (e) => e.wireName == value || e.name == value,
        orElse: () => GameType.regular,
      );
}
