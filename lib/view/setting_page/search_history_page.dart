import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/all_words_provider.dart';
import '../../provider/search_history_provider.dart';
import '../../utility/responsive_sizes.dart';
import '../widget/common_word_list_view.dart';
import '../widget/show_word_dialog.dart';
import '../widget/word_card.dart';

class SearchHistoryPage extends ConsumerWidget {
  const SearchHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // プロバイダーから履歴リストを取得（先頭が最新）
    final history = ref.watch(searchHistoryProvider);
    final allWords = ref.watch(allWordsProvider);

    final wordsByName = {for (final w in allWords) w.name: w};
    final historyWords =
        history.map((name) => wordsByName[name]).nonNulls.take(15).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('検索履歴'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: '履歴を消去',
            onPressed: () =>
                ref.read(searchHistoryProvider.notifier).clearHistory(),
          )
        ],
      ),
      body: historyWords.isEmpty
          ? Center(
              child: Text(
                '検索履歴がありません',
                style: TextStyle(fontSize: context.fontSizeMedium),
              ),
            )
          : CommonWordListView(
              words: historyWords,
              itemBuilder: (context, word) => WordCard(
                word: word,
                onTap: () => showWordDialog(context, word),
                margin: EdgeInsets.symmetric(
                  vertical: context.paddingExtraSmall,
                  horizontal: context.paddingExtraSmall,
                ),
              ),
            ),
    );
  }
}
