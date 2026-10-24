import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/schedule_item.dart';

/// ---------------------------------------------------------------------------
/// ScheduleNotifier
/// ─ 学習スケジュール一覧を SharedPreferences 経由で管理する
/// ---------------------------------------------------------------------------
class ScheduleNotifier extends Notifier<List<ScheduleItem>> {
  static const _storageKey = 'schedule_items';

  @override
  List<ScheduleItem> build() {
    _loadScheduleItems();
    return const [];
  }

  Future<void> _loadScheduleItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_storageKey) ?? const [];
    final items = <ScheduleItem>[];
    for (final e in data) {
      try {
        items.add(ScheduleItem.fromJson(jsonDecode(e) as Map<String, dynamic>));
      } catch (error) {
        // 壊れたレコードは読み飛ばす（1件の破損で全件が消えるのを防ぐ）
        debugPrint('ScheduleItem の復元に失敗しました: $error');
      }
    }
    state = items;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = state.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_storageKey, data);
  }

  Future<void> addSchedule(ScheduleItem item) async {
    state = [...state, item];
    await _save();
  }

  Future<void> updateSchedule(ScheduleItem item) async {
    state = state.map((e) => e.id == item.id ? item : e).toList();
    await _save();
  }

  Future<void> removeSchedule(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }
}
