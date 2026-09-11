import 'package:flutter_test/flutter_test.dart';
import 'package:nba_fantasy_stats_react_app/models/user.dart';
import 'package:nba_fantasy_stats_react_app/utils/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // In-memory mock backing store for SharedPreferences.
    SharedPreferences.setMockInitialValues({});
    // Re-seed the test seam each test so state never leaks between tests.
    StorageService.setInstance(await SharedPreferences.getInstance());
  });

  group('StorageService.readList / writeJson', () {
    test('returns empty list for missing key', () async {
      expect(await StorageService.readList(StorageService.usersKey), isEmpty);
    });

    test('round-trips a list of JSON objects', () async {
      const users = [
        {'username': 'manuel', 'hashedPassword': 'hash1'},
        {'username': 'guest', 'hashedPassword': 'hash2'},
      ];
      await StorageService.writeJson(StorageService.usersKey, users);

      final loaded = await StorageService.readList(StorageService.usersKey);
      expect(loaded, users);
      expect((loaded.first as Map)['username'], 'manuel');
    });

    test('returns empty list for corrupt payload instead of throwing', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageService.gamesKey, '{not-valid-json');

      expect(await StorageService.readList(StorageService.gamesKey), isEmpty);
    });
  });

  group('StorageService.readString / writeString', () {
    test('returns null for missing key', () async {
      expect(
          await StorageService.readString(StorageService.currentUserKey), isNull);
    });

    test('round-trips a plain string', () async {
      await StorageService.writeString(StorageService.currentUserKey, 'manuel');
      expect(
          await StorageService.readString(StorageService.currentUserKey), 'manuel');
    });
  });

  group('StorageService.remove', () {
    test('deletes an existing key', () async {
      await StorageService.writeString(StorageService.currentUserKey, 'manuel');
      await StorageService.remove(StorageService.currentUserKey);

      expect(
          await StorageService.readString(StorageService.currentUserKey), isNull);
    });

    test('is a no-op for missing keys', () async {
      await StorageService.remove(StorageService.currentUserKey);
      expect(
          await StorageService.readString(StorageService.currentUserKey), isNull);
    });
  });

  group('StorageService key parity with React App.tsx', () {
    test('exposes all six localStorage keys', () {
      expect(StorageService.usersKey, 'users');
      expect(StorageService.gamesKey, 'gameStats');
      expect(StorageService.currentUserKey, 'currentUser');
      expect(StorageService.selectedTeamKey, 'selectedTeam');
      expect(StorageService.selectedSeasonKey, 'selectedSeason');
      expect(StorageService.darkModeKey, 'darkMode');
    });
  });

  group('StorageService model integration', () {
    test('stores and restores User objects via toJson/fromJson', () async {
      const users = [
        User(username: 'manuel', hashedPassword: r'$2b$12$abc'),
        User(username: 'guest', hashedPassword: r'$2b$12$def'),
      ];
      await StorageService.writeJson(
          StorageService.usersKey, users.map((u) => u.toJson()).toList());

      final loaded = await StorageService.readList(StorageService.usersKey);
      final restored =
          loaded.map((j) => User.fromJson(j as Map<String, dynamic>)).toList();

      expect(restored, users);
    });
  });
}
