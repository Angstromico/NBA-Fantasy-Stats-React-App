/// Regular season length used for qualification rules across the app
/// (from `src/data/nbaData.ts`).
const regularSeasonGameCount = 82;

/// Number of regular-season games in an NBA season.
int get regularSeasonGames => regularSeasonGameCount;

/// League rate qualifier for season averages: a season must clear ~70% of
/// an 82-game season before its per-game averages can be ranked against
/// NBA seasons (`SEASON_AVG_MIN_GAMES` in leaderboardCalculations.ts).
int get seasonAvgMinGames => (regularSeasonGameCount * 0.7).ceil();
