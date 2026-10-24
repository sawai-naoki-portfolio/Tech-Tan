import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utility/word.dart';

/// ---------------------------------------------------------------------------
/// showMemoDialog
/// ─ 単語に対してユーザーがメモを書き込む入力ダイアログを表示する
/// ---------------------------------------------------------------------------
Future<void> showMemoDialog(BuildContext context, Word word) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'memo_${word.name}';
  final initialMemo = prefs.getString(key) ?? '';
  if (!context.mounted) return;

  final controller = TextEditingController(text: initialMemo);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('メモを書く'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'ここにメモを入力してください'),
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                final memo = controller.text.trim();
                // 空にした場合はキーごと削除して不要なデータを残さない
                if (memo.isEmpty) {
                  await prefs.remove(key);
                } else {
                  await prefs.setString(key, memo);
                }
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(memo.isEmpty ? 'メモを削除しました' : 'メモが保存されました'),
                  ),
                );
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  } finally {
    // ダイアログが閉じたら必ず破棄する（単語ごとに開くため積み上がりやすい）
    controller.dispose();
  }
}
