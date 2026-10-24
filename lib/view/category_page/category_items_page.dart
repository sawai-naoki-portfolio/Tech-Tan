import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/all_words_provider.dart';
import '../../provider/categories_provider.dart';
import '../../provider/checked_questions_provider.dart';
import '../../utility/category.dart';
import '../../utility/responsive_sizes.dart';
import '../../utility/swipe_to_delete_card.dart';
import '../../utility/word.dart';
import '../widget/show_word_dialog.dart';
import '../widget/word_card.dart';
import 'category_assignment_sheet.dart';

/// ---------------------------------------------------------------------------
/// CategoryItemsPage
/// ─ リスト内に属する単語の一覧ページ。
///   通常リストと並び替え用のリストを切り替えて表示する。
/// ---------------------------------------------------------------------------
class CategoryItemsPage extends ConsumerStatefulWidget {
  final Category category;

  const CategoryItemsPage({super.key, required this.category});

  @override
  ConsumerState<CategoryItemsPage> createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends ConsumerState<CategoryItemsPage> {
  bool _isSorting = false;

  @override
  Widget build(BuildContext context) {
    final allCategories = ref.watch(categoriesProvider);
    final currentCategory = allCategories.firstWhere(
      (cat) => cat.name == widget.category.name,
      orElse: () => widget.category,
    );
    final allWords = ref.watch(allWordsProvider);

    // 単語データの更新などで見つからなくなった名前は、例外にせず読み飛ばす
    final wordsByName = {for (final w in allWords) w.name: w};
    final filtered =
        currentCategory.words.map((name) => wordsByName[name]).nonNulls.toList();

    final categoryName = currentCategory.name;

    return Scaffold(
      appBar: AppBar(
        title: Text('リスト: $categoryName'),
        centerTitle: true,
        actions: [
          if (_isSorting)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => setState(() => _isSorting = false),
            )
        ],
      ),
      body: filtered.isEmpty
          ? const Center(child: Text('このリストに単語はありません'))
          : _isSorting
              ? _buildSortingList(filtered, categoryName)
              : _buildNormalList(filtered, categoryName),
    );
  }

  Widget _buildNormalList(List<Word> words, String categoryName) {
    return ListView.builder(
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return SwipeToDeleteCard(
          keyValue: ValueKey(word.name),
          onConfirm: () async {
            return await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('削除確認'),
                    content: Text('${word.name} をリストから削除してよろしいですか？'),
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
            await ref
                .read(categoriesProvider.notifier)
                .updateWordAssignment(categoryName, word.name, false);
          },
          child: GestureDetector(
            onLongPress: () => _showActionSheet(word, categoryName),
            child: WordCard(
              word: word,
              margin: EdgeInsets.symmetric(
                vertical: context.paddingExtraSmall,
                horizontal: context.paddingExtraSmall,
              ),
              onTap: () => showWordDialog(context, word),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortingList(List<Word> words, String categoryName) {
    return ReorderableListView.builder(
      itemCount: words.length,
      // onReorderItem は削除位置を考慮した newIndex を渡してくれる
      onReorderItem: (oldIndex, newIndex) async {
        await ref
            .read(categoriesProvider.notifier)
            .reorderWords(categoryName, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final word = words[index];
        return ListTile(
          key: ValueKey(word.name),
          leading: const Icon(Icons.drag_handle),
          title: Text(
            word.name,
            style: TextStyle(
              fontSize: context.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () => showWordDialog(context, word),
        );
      },
    );
  }

  void _showActionSheet(Word word, String categoryName) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('他のリストにも追加'),
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
              title: const Text('リストから削除'),
              onTap: () async {
                await ref
                    .read(categoriesProvider.notifier)
                    .updateWordAssignment(categoryName, word.name, false);
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
