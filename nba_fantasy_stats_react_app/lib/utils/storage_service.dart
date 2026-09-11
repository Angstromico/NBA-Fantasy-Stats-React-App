import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key-based JSON persistence, mirroring the `localStorage` access pattern
/// used in the React app's `App.tsx` (Step 3 of FLUTTER_PLAN.md).
class StorageService {
  StorageService._();

  /// Users list — `{username, hashedPassword}` objects (bcrypt via the
  /// `bcrypt` package in Step 4).
  static const usersKey = 'users';

  /// Per-game stat records — `GameStats.toJson()` objects.
  static const gamesKey = 'gameStats';

  /// Logged-in username, or absent when logged out.
  static const currentUserKey = 'currentUser';

  /// Preferred team id.
  static const selectedTeamKey = 'selectedTeam';

  /// Selected season label, e.g. `2025-2026`.
  static const selectedSeasonKey = 'selectedSeason';

  /// Dark-mode flag, stored as a JSON boolean.
  static const darkModeKey = 'darkMode';

  static SharedPreferences? _instance;

  /// Test seam: inject a mock/fake `SharedPreferences` instance.
  @visibleForTesting
  static void setInstance(SharedPreferences instance) => _instance = instance;

  static Future<SharedPreferences> _prefs() async =>
      _instance ??= await SharedPreferences.getInstance();

  /// Reads a JSON array from storage; returns an empty list when the key is
  /// missing or the payload is corrupt (mirroring the React app's
  /// try/catch fallback to `[]`).
  static Future<List<dynamic>> readList(String key) async {
    final prefs = await _prefs();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : [];
    } on FormatException {
      return [];
    }
  }

  /// Reads a JSON object from storage; returns null when the key is missing
  /// or the payload is corrupt.
  static Future<Map<String, dynamic>?> readJson(String key) async {
    final prefs = await _prefs();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// Reads a plain string value (e.g. `currentUser`, `selectedTeam`); returns
  /// null when the key is missing.
  static Future<String?> readString(String key) async {
    final prefs = await _prefs();
    return prefs.getString(key);
  }

  /// Serializes [value] as JSON under [key].
  static Future<void> writeJson(String key, Object? value) async {
    final prefs = await _prefs();
    await prefs.setString(key, jsonEncode(value));
  }

  /// Writes a plain string value.
  static Future<void> writeString(String key, String value) async {
    final prefs = await _prefs();
    await prefs.setString(key, value);
  }

  /// Removes [key] from storage.
  static Future<void> remove(String key) async {
    final prefs = await _prefs();
    await prefs.remove(key);
  }
}
