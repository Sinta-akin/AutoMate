import 'package:automate/features/preferences/domain/user_preferences.dart';

/// Storage contract for user preferences.
///
/// When Firebase is ready, add a FirestorePreferencesRepository
/// (read/write users/{uid}) and change the one line in [instance].
abstract class PreferencesRepository {
  static PreferencesRepository instance = InMemoryPreferencesRepository();

  Future<UserPreferences> load();
  Future<void> save(UserPreferences preferences);
}

/// Keeps preferences in memory while the app is open. Lost on app close.
class InMemoryPreferencesRepository implements PreferencesRepository {
  UserPreferences _current = const UserPreferences();

  @override
  Future<UserPreferences> load() async => _current;

  @override
  Future<void> save(UserPreferences preferences) async {
    _current = preferences;
  }
}