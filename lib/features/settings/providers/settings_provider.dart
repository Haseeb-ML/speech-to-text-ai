import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isDarkMode;
  final String language; // "Roman Urdu" or "English"

  SettingsState({
    required this.isDarkMode,
    required this.language,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? language,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
    );
  }
}

class SettingsProvider extends StateNotifier<SettingsState> {
  SettingsProvider() : super(SettingsState(isDarkMode: false, language: 'Roman Urdu')) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    final language = prefs.getString('language') ?? 'Roman Urdu';
    
    state = state.copyWith(isDarkMode: isDarkMode, language: language);
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newTheme = !state.isDarkMode;
    await prefs.setBool('isDarkMode', newTheme);
    state = state.copyWith(isDarkMode: newTheme);
  }

  Future<void> setLanguage(String newLanguage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLanguage);
    state = state.copyWith(language: newLanguage);
  }
}

final settingsProvider = StateNotifierProvider<SettingsProvider, SettingsState>((ref) {
  return SettingsProvider();
});
