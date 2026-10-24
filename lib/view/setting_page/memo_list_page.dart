import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider/all_words_provider.dart';
import '../../utility/load_memo.dart';
import '../../utility/responsive_sizes.dart';
import '../../utility/word.dart';
import '../widget/show_word_dialog.dart';

/// ---------------------------------------------------------------------------
/// MemoListPage
/// ─ メモを書き込んだ単語だけを一覧表示する画面
/// ---------------------------------------------------------------------------
class MemoListPage extends ConsumerStatefulWidget {
  const MemoListPage({super.key});

  @override
  ConsumerState<MemoListPage> createState() => _MemoListPageState();
}

class _MemoListPageState extends ConsumerState<MemoListPage> {
  /// 全単語のうち、メモが記録されているものだけを抽出する
  Future<List<({Word word, String memo})>> _collectMemos(
      List<Word> words) async {
    final result = <({Word word, String memo})>[];
    for (final word in words) {
      final memo = await loadMemo(word);
      if (memo.trim().isNotEmpty) {
        result.add((word: word, memo: memo));
      }
    }
    return result;
  }

  Future<void> _clearMemo(Word word) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('memo_${word.name}');
  }

  Future<bool> _confirmDelete(Word word) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('削除の確認'),
            content: Text('${word.name} のメモを削除してよろしいですか？'),
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
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final allWords = ref.watch(allWordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('メモ一覧'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<({Word word, String memo})>>(
        future: _collectMemos(allWords),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final memos = snapshot.data ?? const [];
          if (memos.isEmpty) {
            return Center(
              child: Text('保存されているメモはありません',
                  style: TextStyle(fontSize: context.fontSizeMedium)),
            );
          }
          return ListView.builder(
            itemCount: memos.length,
            itemBuilder: (context, index) {
              final entry = memos[index];
              return Dismissible(
                key: ValueKey(entry.word.name),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: context.paddingMedium),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => _confirmDelete(entry.word),
                onDismissed: (_) async {
                  await _clearMemo(entry.word);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('メモが削除されました')),
                  );
                  setState(() {}); // 再評価して削除を反映
                },
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: context.paddingExtraSmall,
                    horizontal: context.paddingSmall,
                  ),
                  title: Text(
                    entry.word.name,
                    style: TextStyle(
                      fontSize: context.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    entry.memo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fontSizeSmall,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onLongPress: () async {
                    if (!await _confirmDelete(entry.word)) return;
                    await _clearMemo(entry.word);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('メモが削除されました')),
                    );
                    setState(() {});
                  },
                  onTap: () => showWordDialog(context, entry.word),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
