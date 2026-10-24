import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_manager.dart';
import '../provider/checked_questions_provider.dart';
import '../provider/custom_words_provider.dart';
import '../provider/exam_type_provider.dart';
import '../provider/search_history_provider.dart';
import '../provider/search_query_provider.dart';
import '../provider/words_provider.dart';
import '../utility/responsive_sizes.dart';
import '../utility/search_normalize.dart';
import '../utility/word.dart';
import 'category_page/category_assignment_sheet.dart';
import 'category_page/category_selection_page.dart';
import 'it_news_page.dart';
import 'schedule_page/schedule_management_page.dart';
import 'setting_page/settings_page.dart';
import 'test_page/check_test/checked_questions_page.dart';
import 'test_page/exam_test/exam_questions_list_page.dart';
import 'test_page/exam_test/exam_quiz_settings_page.dart';
import 'test_page/word_test/word_quiz_settings_page.dart';
import 'widget/exam_switcher.dart';
import 'widget/show_word_dialog.dart';
import 'widget/word_card.dart';

/// ---------------------------------------------------------------------------
/// SearchPage
/// ---------------------------------------------------------------------------
/// 単語検索画面（ホーム）。単語名や読みから検索を行い、
/// 結果がリスト表示され、各単語の詳細ダイアログなどへ遷移できる。
/// 上部の試験切り替えは、実践問題・単語テスト・ニュースの既定の範囲になる。

/// 検索欄が空のときに表示する「おすすめ」15件。
/// Provider がキャッシュするため、再描画のたびに並びが変わることはない。
final randomWordsProvider = Provider<List<Word>>((ref) {
  final assetWords = ref.watch(wordsProvider).value ?? const <Word>[];
  final customWords = ref.watch(customWordsProvider);
  final all = [...assetWords, ...customWords];
  if (all.isEmpty) return const [];
  final shuffled = List<Word>.from(all)..shuffle();
  return List<Word>.unmodifiable(shuffled.take(15));
});

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

/// _SearchPageState
/// SearchPage の内部状態。検索欄の入力をデバウンスして
/// searchQueryProvider へ流し込む役割を持つ。
class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // テキストコントローラにリスナ登録（入力は 250ms デバウンスして反映する）
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final text = _controller.text;
    // 入力を消したときは即座に反映したほうが体感が速い
    if (text.isEmpty) {
      ref.read(searchQueryProvider.notifier).update('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).update(text);
    });
  }

  void _openMenu() {
    // メニュー表示時にキーボードフォーカスを解除
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          margin: EdgeInsets.all(sheetContext.paddingMedium),
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(sheetContext.paddingSmall),
                  child: Text(
                    'メニュー',
                    style: TextStyle(
                        fontSize: sheetContext.fontSizeLarge,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.folder,
                  label: '単語マイリスト',
                  builder: (_) => const CategorySelectionPage(),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.quiz,
                  label: '単語テスト',
                  builder: (_) => const WordQuizSettingsPage(),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.check_box,
                  label: '単語チェック問題',
                  builder: (_) => const CheckedQuestionsPage(),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.assignment,
                  label: '実践問題（過去問）',
                  builder: (_) => const ExamQuizSettingsPage(),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.library_books,
                  label: '過去問一覧',
                  builder: (_) => const ExamQuestionsListPage(),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.calendar_today,
                  label: 'スケジュール管理',
                  builder: (_) => const ScheduleManagementPage(),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.article,
                  label: 'ITニュース',
                  builder: (_) => const ItNewsPage(),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.settings,
                  label: '設定',
                  builder: (_) => const SettingsPage(),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examTypeProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('テク単'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'メニュー',
              onPressed: _openMenu,
            ),
          ],
        ),
        body: Column(
          children: [
            // 勉強中の試験を切り替える。実践問題・単語テスト・ニュースの既定範囲になる。
            const ExamSwitcher(),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.paddingMedium,
                vertical: context.paddingSmall,
              ),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: '単語名を入力',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            // 実践問題への導線をホームに置き、毎日の演習を始めやすくする
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.paddingMedium),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ExamQuizSettingsPage()),
                  ),
                  icon: const Icon(Icons.assignment),
                  label: Text('${exam.label}の実践問題を解く'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(vertical: context.paddingSmall),
                  ),
                ),
              ),
            ),
            SizedBox(height: context.paddingSmall),
            // 検索結果リスト（入力ごとの全体再描画を防止）
            const Expanded(child: _SearchResultList()),
          ],
        ),
        bottomNavigationBar: AdManager.bannerAdWidget(),
      ),
    );
  }
}

/// メニュー内の 1 項目
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final WidgetBuilder builder;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: builder));
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: context.paddingMedium, horizontal: context.paddingSmall),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            context.horizontalSpaceMedium,
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: context.fontSizeMedium)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultList extends ConsumerWidget {
  const _SearchResultList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final wordsAsync = ref.watch(wordsProvider);
    final customWords = ref.watch(customWordsProvider);
    final exam = ref.watch(examTypeProvider);

    return wordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('読み込みエラー: $err')),
      data: (assetWords) {
        // 「センサー」で「センサ」を引けるよう、入力側も同じ規則でそろえる
        final normalizedQuery = normalizeForSearch(query);

        final List<Word> list;
        if (normalizedQuery.isEmpty) {
          // 空入力時はキャッシュ済みのランダム 15 件を使う。
          // ただし勉強中の試験の学習範囲（下位試験を含む累積）を先に見せる。
          final random = ref.watch(randomWordsProvider);
          final scope = exam.cumulativeLabels;
          list = [
            ...random.where((w) => scope.contains(w.category)),
            ...random.where((w) => !scope.contains(w.category)),
          ];
        } else {
          // 検索語が入っていれば全試験の単語からフィルタする。
          // 用語自体は試験をまたいで共通するため、範囲を絞らないほうが役に立つ。
          list = [...assetWords, ...customWords]
              .where((w) => w.matches(normalizedQuery))
              .toList();
        }

        if (list.isEmpty) {
          return const Center(child: Text('一致する単語がありません'));
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            final word = list[i];
            return WordCard(
              word: word,
              onTap: () {
                // 検索履歴に保存
                ref.read(searchHistoryProvider.notifier).addWord(word.name);
                // 詳細ダイアログ
                showWordDialog(context, word);
              },
              onLongPress: () => _showActionSheet(context, ref, word),
            );
          },
        );
      },
    );
  }

  void _showActionSheet(BuildContext context, WidgetRef ref, Word word) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('保存する'),
            onTap: () {
              Navigator.pop(sheetContext);
              showModalBottomSheet(
                  context: context,
                  builder: (_) => CategoryAssignmentSheet(word: word));
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_box),
            title: const Text('単語チェック問題に登録する'),
            onTap: () {
              Navigator.pop(sheetContext);
              final checked = ref.read(checkedQuestionsProvider);
              final messenger = ScaffoldMessenger.of(context);
              if (checked.contains(word.name)) {
                messenger
                    .showSnackBar(const SnackBar(content: Text('既に登録済みです。')));
              } else {
                ref.read(checkedQuestionsProvider.notifier).add(word.name);
                messenger
                    .showSnackBar(const SnackBar(content: Text('登録しました。')));
              }
            },
          ),
        ]),
      ),
    );
  }
}
