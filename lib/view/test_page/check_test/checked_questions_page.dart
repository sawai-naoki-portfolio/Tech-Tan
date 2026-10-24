import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/all_words_provider.dart';
import '../../../provider/checked_questions_provider.dart';
import '../../../utility/responsive_sizes.dart';
import '../../../utility/swipe_to_delete_card.dart';
import '../../../utility/word.dart';
import '../../category_page/category_assignment_sheet.dart';
import '../../widget/show_word_dialog.dart';
import '../../widget/word_card.dart';
import 'checkbox_test_page.dart';

/// ---------------------------------------------------------------------------
/// CheckedQuestionsPage
/// ---------------------------------------------------------------------------
/// 「単語チェック問題」として登録した単語の一覧画面。
/// 上部の「問題出題」から、チェック済みの単語だけを対象にテストを開始できる。
class CheckedQuestionsPage extends ConsumerWidget {
  const CheckedQuestionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checked = ref.watch(checkedQuestionsProvider);
    final allWords = ref.watch(allWordsProvider);
    final filtered = allWords.where((w) => checked.contains(w.name)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('単語チェック問題'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(context.paddingMedium),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: context.paddingSmall),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: filtered.isEmpty
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CheckboxTestPage()),
                        ),
                child: Text('問題出題',
                    style: TextStyle(fontSize: context.fontSizeLarge)),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('チェックされた問題はありません'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final word = filtered[index];
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
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('キャンセル'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: const Text('削除'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: () async {
                          await ref
                              .read(checkedQuestionsProvider.notifier)
                              .remove(word.name);
                        },
                        child: GestureDetector(
                          onLongPress: () => _showActionSheet(context, ref, word),
                          child: WordCard(
                            word: word,
                            onTap: () => showWordDialog(context, word),
                            margin: EdgeInsets.symmetric(
                                vertical: context.paddingExtraSmall,
                                horizontal: context.paddingExtraSmall),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context, WidgetRef ref, Word word) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('保存する'),
              onTap: () {
                Navigator.pop(sheetContext);
                showModalBottomSheet(
                  context: context,
                  builder: (_) => CategoryAssignmentSheet(word: word),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('削除'),
              onTap: () async {
                await ref
                    .read(checkedQuestionsProvider.notifier)
                    .remove(word.name);
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
