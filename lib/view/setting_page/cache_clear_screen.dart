import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utility/responsive_sizes.dart';

/// ---------------------------------------------------------------------------
/// CacheClearScreen
/// ─ 端末に保存した学習データを、項目ごとに選んで削除する画面。
///   削除後は状態を確実に初期化するためアプリを再起動する。
/// ---------------------------------------------------------------------------
class CacheClearScreen extends StatefulWidget {
  const CacheClearScreen({super.key});

  @override
  State<CacheClearScreen> createState() => _CacheClearScreenState();
}

class _CacheClearScreenState extends State<CacheClearScreen> {
  // キャッシュ削除対象のキーと初期選択状態。
  // 'memo_list' は "memo_" で始まるキーをすべて、
  // 'schedule_list' は "schedule_items" キーを削除する。
  final Map<String, bool> _selected = {
    'search_history': false,
    'mistake_counts': false,
    'question_mistake_counts': false,
    'saved_categories': false,
    'saved_items': false,
    'checked_questions': false,
    'checked_exam_questions': false,
    'custom_words': false,
    'memo_list': false,
    'schedule_list': false,
    'exam_quiz_filters': false,
    'word_quiz_filters': false,
  };

  // 各キーの表示用ラベル
  final Map<String, String> _labels = {
    'search_history': '検索履歴',
    'mistake_counts': '単語テストのミス回数',
    'question_mistake_counts': '実践問題のミス回数',
    'saved_categories': '単語マイリスト',
    'saved_items': '保存単語一覧',
    'checked_questions': '単語チェック問題',
    'checked_exam_questions': 'あとで解き直す問題',
    'custom_words': '自分で追加した単語',
    'memo_list': 'メモ一覧',
    'schedule_list': 'スケジュール',
    'exam_quiz_filters': '実践問題の出題範囲設定',
    'word_quiz_filters': '単語テストの出題範囲設定',
  };

  bool _allSelected = false;

  void _toggleAll(bool? val) {
    setState(() {
      _allSelected = val ?? false;
      _selected.updateAll((key, value) => _allSelected);
    });
  }

  void _toggleItem(String key, bool? val) {
    setState(() {
      _selected[key] = val ?? false;
      // すべてが true なら _allSelected を true、1つでも false があれば false に
      _allSelected = !_selected.values.contains(false);
    });
  }

  /// 選択されたキーを SharedPreferences から削除する
  Future<void> _removeSelectedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _selected.entries) {
      if (!entry.value) continue;
      switch (entry.key) {
        case 'memo_list':
          // メモは "memo_<単語名>" というキーで個別に保存されている
          for (final k in prefs.getKeys().toList()) {
            if (k.startsWith('memo_')) {
              await prefs.remove(k);
            }
          }
        case 'schedule_list':
          await prefs.remove('schedule_items');
        default:
          await prefs.remove(entry.key);
      }
    }
  }

  /// 削除確認ダイアログ後、選択対象のキャッシュキーを削除して再起動
  Future<void> _clearCache() async {
    if (!_selected.values.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除する項目を選択してください')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('確認'),
        content: const Text('削除してよろしいですか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // データ削除はユーザーが完了させざるを得ない操作のため、広告は挟まない。
    await _removeSelectedKeys();
    if (!mounted) return;
    await _showRestartDialog();
  }

  /// 完了ダイアログを出して、少し待ってからアプリを再起動する
  Future<void> _showRestartDialog() async {
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                color: Theme.of(dialogContext).colorScheme.primary, size: 64),
            const SizedBox(height: 16),
            Text('キャッシュがクリアされました。',
                style: TextStyle(fontSize: dialogContext.fontSizeMedium)),
            Text('再起動します。',
                style: TextStyle(fontSize: dialogContext.fontSizeMedium)),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    ));

    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Phoenix.rebirth(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('キャッシュクリア')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CheckboxListTile(
              title: Text('すべて削除',
                  style: TextStyle(fontSize: context.fontSizeMedium)),
              value: _allSelected,
              onChanged: _toggleAll,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ..._selected.keys.map((key) {
              return CheckboxListTile(
                title: Text(
                  _labels[key] ?? key,
                  style: TextStyle(fontSize: context.fontSizeMedium),
                ),
                value: _selected[key],
                onChanged: (val) => _toggleItem(key, val),
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _clearCache,
                child: const Text('削除'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
