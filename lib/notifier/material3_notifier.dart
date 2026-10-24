import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Material 3 を使うかどうかの設定を保持する
class Material3Notifier extends Notifier<bool> {
  static const _storageKey = 'use_material3';

  @override
  bool build() {
    _loadMaterial3();
    return false;
  }

  Future<void> _loadMaterial3() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_storageKey) ?? false;
  }

  Future<void> setMaterial3(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, value);
  }
}
