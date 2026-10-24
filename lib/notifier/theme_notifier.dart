import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------------------------------------------------------------------------
/// ThemeNotifier
/// ─ ライト / ダーク / システム追従の設定を保持する。
/// ---------------------------------------------------------------------------
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _storageKey = 'theme_mode';

  @override
  ThemeMode build() {
    // 保存値の読み込みは非同期のため、まずは既定値を返してから差し替える
    _loadTheme();
    return ThemeMode.light;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    state = switch (prefs.getString(_storageKey)) {
      'system' => ThemeMode.system,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    final modeStr = switch (mode) {
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
    };
    await prefs.setString(_storageKey, modeStr);
  }

  /// light なら dark に、そうでなければ light に切り替える
  Future<void> toggleTheme() async {
    await setTheme(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}
