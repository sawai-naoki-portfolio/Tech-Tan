import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_manager.dart';
import '../provider/checked_questions_provider.dart';
import '../provider/custom_words_provider.dart';
import '../provider/exam_type_provider.dart';
import '../provider/words_provider.dart';
import '../utility/exam_type.dart';
import '../utility/responsive_sizes.dart';
import '../utility/word.dart';
import 'category_page/category_assignment_sheet.dart';
import 'widget/add_word_dialog.dart';
import 'widget/common_word_list_view.dart';
import 'widget/show_word_dialog.dart';
import 'widget/word_card.dart';

/// 一覧の絞り込み。試験を選んだときは「その試験まで」の累積で表示する。
const _allFilterId = '__all__';
const _customFilterId = '__custom__';

/// ---------------------------------------------------------------------------
/// WordListPage
/// ─ 収録単語を対象試験ごとに絞り込んで一覧表示する画面。
///   単語データは試験をまたいで重複しない「差分」で作られているため、
///   試験を選んだときは下位試験の単語も含めた累積で表示する
///   （応用情報の受験者には IP・FE の単語も必要なため）。
///   右下の [+] から、データベースに無い単語を自分で追加できる。
/// ---------------------------------------------------------------------------
class WordListPage extends ConsumerStatefulWidget {
  const WordListPage({super.key});

  @override
  WordListPageState createState() => WordListPageState();
}

class WordListPageState extends ConsumerState<WordListPage> {
  /// 絞り込みの選択値。'__all__' / ExamType.id / '__custom__' のいずれか。
  /// 初期値は勉強中の試験に合わせる（initState で設定）。
  String? _selectedFilterId;

  @override
  void initState() {
    super.initState();
    // 開いた直後から自分の試験範囲が見えるようにしておく
    _selectedFilterId = ref.read(examTypeProvider).id;
  }

  /// 選択中の絞り込みに合致する単語だけを返す
  List<Word> _filter(List<Word> words) {
    final id = _selectedFilterId;
    if (id == null || id == _allFilterId) return words;
    if (id == _customFilterId) {
      return words.where((w) => w.isCustom).toList();
    }
    final scope = ExamType.fromId(id).cumulativeLabels;
    return words.where((w) => scope.contains(w.category)).toList();
  }

  /// カスタム単語の追加ダイアログを開き、入力されれば永続化する
  Future<void> _addCustomWord() async {
    final word = await showDialog<Word>(
      context: context,
      builder: (_) => const AddWordDialog(),
    );
    if (word == null || !mounted) return;

    if (ref.read(customWordsProvider).any((w) => w.name == word.name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('同じ名前の単語が既に登録されています。')),
      );
      return;
    }
    await ref.read(customWordsProvider.notifier).addWord(word);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「${word.name}」を追加しました。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wordsProvider);
    // ユーザーが追加したカスタム単語も一覧に含める
    final customWords = ref.watch(customWordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('単語一覧'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomWord,
        tooltip: '単語を追加',
        child: const Icon(Icons.add),
      ),
      body: wordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
        data: (assetWords) {
          final words = [...assetWords, ...customWords];
          final filtered = _filter(words);

          return Column(
            children: [
              // フィルター用のドロップダウンを上部に配置
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.paddingMedium,
                  vertical: context.paddingSmall,
                ),
                child: Row(
                  children: [
                    Text(
                      '範囲:',
                      style: TextStyle(fontSize: context.fontSizeMedium),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedFilterId,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: _allFilterId,
                            child: Text('全て'),
                          ),
                          for (final exam in ExamType.values)
                            DropdownMenuItem(
                              value: exam.id,
                              child: Text(
                                exam.cumulativeHint == null
                                    ? exam.cumulativeLabel
                                    : '${exam.cumulativeLabel}'
                                        '（${exam.cumulativeHint}）',
                              ),
                            ),
                          const DropdownMenuItem(
                            value: _customFilterId,
                            child: Text('自分で追加した単語'),
                          ),
                        ],
                        onChanged: (newVal) {
                          if (newVal == null) return;
                          setState(() => _selectedFilterId = newVal);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // 累積であることと件数を明示する
              Padding(
                padding: EdgeInsets.only(
                  left: context.paddingMedium,
                  right: context.paddingMedium,
                  bottom: context.paddingSmall,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _scopeDescription(filtered.length),
                    style: TextStyle(
                      fontSize: context.fontSizeExtraSmall,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: CommonWordListView(
                  words: filtered,
                  itemBuilder: (context, word) {
                    return GestureDetector(
                      onLongPress: () => _showActionSheet(word),
                      child: WordCard(
                        word: word,
                        onTap: () => showWordDialog(context, word),
                        margin: EdgeInsets.symmetric(
                          vertical: context.paddingExtraSmall,
                          horizontal: context.paddingExtraSmall,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      // 一覧を眺める時間が長い画面のため、学習を妨げないバナーで表示する
      bottomNavigationBar: AdManager.bannerAdWidget(),
    );
  }

  /// 表示中の範囲の説明文（累積であることが伝わるようにする）
  String _scopeDescription(int count) {
    final id = _selectedFilterId;
    if (id == null || id == _allFilterId) return '全 $count 語';
    if (id == _customFilterId) return '自分で追加した単語 $count 語';

    final exam = ExamType.fromId(id);
    if (exam.level == 0) return '${exam.label}の範囲 $count 語';
    final included = exam.cumulative.map((e) => e.label).join('・');
    return '$included を合わせた $count 語';
  }

  void _showActionSheet(Word word) {
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
            if (word.isCustom)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('この単語を削除'),
                onTap: () async {
                  await ref
                      .read(customWordsProvider.notifier)
                      .removeWord(word.name);
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
