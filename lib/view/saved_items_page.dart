import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/all_words_provider.dart';
import '../provider/checked_questions_provider.dart';
import '../provider/saved_items_provider.dart';
import '../utility/responsive_sizes.dart';
import '../utility/swipe_to_delete_card.dart';
import '../utility/word.dart';
import 'category_page/category_assignment_sheet.dart';
import 'widget/show_word_dialog.dart';
import 'widget/word_card.dart';

/// ---------------------------------------------------------------------------
/// SavedItemsPage
/// ─ 保存した単語を一覧表示する画面。
///   タップで詳細ダイアログ、スワイプで削除、長押しで各種操作を行える。
///   右上のアイコンからドラッグ＆ドロップの並び替えモードに切り替えられる。
/// ---------------------------------------------------------------------------
class SavedItemsPage extends ConsumerStatefulWidget {
  const SavedItemsPage({super.key});

  @override
  ConsumerState<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends ConsumerState<SavedItemsPage> {
  bool _isSorting = false;

  @override
  Widget build(BuildContext context) {
    final savedItems = ref.watch(savedItemsProvider);
    final allWords = ref.watch(allWordsProvider);

    // 名前で引ける索引を1度だけ作る（保存件数×全単語数の走査を避ける）
    final wordsByName = {for (final w in allWords) w.name: w};
    final savedWords =
        savedItems.map((name) => wordsByName[name]).nonNulls.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('保存単語'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSorting ? Icons.check : Icons.sort),
            tooltip: _isSorting ? '並び替えを終了' : '並び替え',
            onPressed: () => setState(() => _isSorting = !_isSorting),
          ),
        ],
      ),
      body: savedWords.isEmpty
          ? const Center(child: Text('保存された単語はありません'))
          : _isSorting
              ? _buildSortingList(savedWords, savedItems, wordsByName)
              : _buildNormalList(savedWords),
    );
  }

  Widget _buildSortingList(
    List<Word> savedWords,
    List<String> savedItems,
    Map<String, Word> wordsByName,
  ) {
    return ReorderableListView.builder(
      itemCount: savedWords.length,
      // onReorderItem は削除位置を考慮した newIndex を渡してくれる
      onReorderItem: (oldIndex, newIndex) async {
        // 表示リストは単語データに存在するものだけに絞り込まれているため、
        // 表示側のインデックスで保存リストを直接操作すると順序がずれる。
        // 表示中の単語名を基準に並べ替え、未収録の単語は末尾に残す。
        final visible = savedWords.map((w) => w.name).toList();
        final moved = visible.removeAt(oldIndex);
        visible.insert(newIndex, moved);
        final hidden =
            savedItems.where((name) => !wordsByName.containsKey(name)).toList();
        await ref
            .read(savedItemsProvider.notifier)
            .reorderItems([...visible, ...hidden]);
      },
      itemBuilder: (context, index) {
        final word = savedWords[index];
        return ListTile(
          key: ValueKey(word.name),
          leading: const Icon(Icons.drag_handle),
          title: Text(word.name),
          subtitle: Text(
            word.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => showWordDialog(context, word),
        );
      },
    );
  }

  Widget _buildNormalList(List<Word> savedWords) {
    return ListView.builder(
      itemCount: savedWords.length,
      itemBuilder: (context, index) {
        final word = savedWords[index];
        return SwipeToDeleteCard(
          keyValue: ValueKey(word.name),
          onConfirm: () async {
            return await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('削除確認'),
                    content: Text('${word.name} を削除してよろしいですか？'),
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
          },
          onDismissed: () async {
            await ref.read(savedItemsProvider.notifier).removeItem(word.name);
          },
          child: GestureDetector(
            onLongPress: () => _showActionSheet(word),
            child: WordCard(
              word: word,
              onTap: () => showWordDialog(context, word),
              margin: EdgeInsets.symmetric(
                vertical: context.paddingExtraSmall,
                horizontal: context.paddingExtraSmall,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showActionSheet(Word word) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('リストに割り当てる'),
              onTap: () {
                Navigator.pop(sheetContext);
                showModalBottomSheet(
                  context: context,
                  builder: (_) => CategoryAssignmentSheet(word: word),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_box),
              title: const Text('単語チェック問題に登録する'),
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                final checked = ref.read(checkedQuestionsProvider);
                if (checked.contains(word.name)) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('既に単語チェック問題に登録されています。')),
                  );
                } else {
                  ref.read(checkedQuestionsProvider.notifier).add(word.name);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('単語チェック問題に登録しました。')),
                  );
                }
                Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('並び替える'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _isSorting = true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('削除'),
              onTap: () async {
                await ref
                    .read(savedItemsProvider.notifier)
                    .removeItem(word.name);
                if (!sheetContext.mounted) return;
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}
