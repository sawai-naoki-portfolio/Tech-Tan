import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ads/ad_manager.dart';
import '../../../provider/checked_exam_questions_provider.dart';
import '../../../provider/exam_questions_provider.dart';
import '../../../provider/exam_type_provider.dart';
import '../../../provider/question_mistakes_provider.dart';
import '../../../utility/exam_question.dart';
import '../../../utility/exam_quiz_filter.dart';
import '../../../utility/search_normalize.dart';
import '../../../utility/responsive_sizes.dart';
import '../../widget/exam_switcher.dart';
import 'exam_question_detail_page.dart';

/// 一覧の絞り込み条件
enum _ListFilter {
  all('すべて'),
  bookmarked('あとで解き直す'),
  weak('間違えた問題');

  const _ListFilter(this.label);

  final String label;
}

/// ---------------------------------------------------------------------------
/// ExamQuestionsListPage
/// ─ 収録されている過去問を回・分野で絞りながら閲覧する画面。
///   「あとで解き直す」に登録した問題や、間違えたことのある問題だけを
///   取り出して復習する導線も兼ねている。
/// ---------------------------------------------------------------------------
class ExamQuestionsListPage extends ConsumerStatefulWidget {
  /// 開いた直後に適用しておく絞り込み（ホームや設定から直接飛ぶときに使う）
  final _ListFilter _initialFilter;

  const ExamQuestionsListPage({super.key})
      : _initialFilter = _ListFilter.all;

  /// 「あとで解き直す」に登録した問題だけを開く
  const ExamQuestionsListPage.bookmarked({super.key})
      : _initialFilter = _ListFilter.bookmarked;

  /// 間違えたことのある問題だけを開く
  const ExamQuestionsListPage.weak({super.key})
      : _initialFilter = _ListFilter.weak;

  @override
  ConsumerState<ExamQuestionsListPage> createState() =>
      _ExamQuestionsListPageState();
}

class _ExamQuestionsListPageState
    extends ConsumerState<ExamQuestionsListPage> {
  static const _allSeasons = '__all__';

  late _ListFilter _filter = widget._initialFilter;
  String _selectedSeason = _allSeasons;
  String? _selectedField;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examTypeProvider);
    final questionsAsync = ref.watch(examQuestionsProvider(exam));
    final seasons = ref.watch(examSeasonsProvider(exam));
    final bookmarked = ref.watch(checkedExamQuestionsProvider);
    final mistakes = ref.watch(questionMistakesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('過去問一覧'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const ExamSwitcher(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.paddingMedium,
              vertical: context.paddingSmall,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                isDense: true,
                hintText: '問題文・分野から探す',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                EdgeInsets.symmetric(horizontal: context.paddingMedium),
            child: Row(
              children: [
                for (final filter in _ListFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        filter.label,
                        style:
                            TextStyle(fontSize: context.fontSizeExtraSmall),
                      ),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
                const SizedBox(width: 8),
                for (final field in kExamFields)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(
                        field,
                        style:
                            TextStyle(fontSize: context.fontSizeExtraSmall),
                      ),
                      selected: _selectedField == field,
                      onSelected: (selected) => setState(
                          () => _selectedField = selected ? field : null),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.paddingMedium,
              vertical: context.paddingExtraSmall,
            ),
            child: Row(
              children: [
                Text('回:', style: TextStyle(fontSize: context.fontSizeSmall)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedSeason,
                    isExpanded: true,
                    isDense: true,
                    items: [
                      const DropdownMenuItem(
                        value: _allSeasons,
                        child: Text('すべての回'),
                      ),
                      for (final season in seasons)
                        DropdownMenuItem(
                          value: season.raw,
                          child: Text(season.labelWithYear),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedSeason = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: questionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('データ読み込みエラー: $error')),
              data: (questions) {
                final filtered = _applyFilters(questions, bookmarked, mistakes);
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _emptyMessage(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: context.fontSizeSmall),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final question = filtered[index];
                    return _QuestionTile(
                      question: question,
                      mistakeCount: mistakes[question.id] ?? 0,
                      isBookmarked: bookmarked.contains(question.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // 一覧を眺める時間が長い画面のため、学習を妨げないバナーで表示する
      bottomNavigationBar: AdManager.bannerAdWidget(),
    );
  }

  List<ExamQuestion> _applyFilters(
    List<ExamQuestion> questions,
    Set<String> bookmarked,
    Map<String, int> mistakes,
  ) {
    final normalizedQuery = normalizeForSearch(_query);

    final filtered = questions.where((question) {
      if (_selectedSeason != _allSeasons &&
          question.seasonRaw != _selectedSeason) {
        return false;
      }
      if (_selectedField != null && question.field != _selectedField) {
        return false;
      }
      switch (_filter) {
        case _ListFilter.bookmarked:
          if (!bookmarked.contains(question.id)) return false;
        case _ListFilter.weak:
          if ((mistakes[question.id] ?? 0) == 0) return false;
        case _ListFilter.all:
          break;
      }
      if (normalizedQuery.isNotEmpty && !question.matches(normalizedQuery)) {
        return false;
      }
      return true;
    }).toList();

    // 新しい回を先に、同じ回なら問番号順に並べる
    filtered.sort((a, b) {
      final bySeason = a.season.compareTo(b.season);
      if (bySeason != 0) return bySeason;
      return a.number.compareTo(b.number);
    });
    return filtered;
  }

  String _emptyMessage() {
    switch (_filter) {
      case _ListFilter.bookmarked:
        return '「あとで解き直す」に登録した問題はまだありません。\n出題画面の右上のしおりアイコンから登録できます。';
      case _ListFilter.weak:
        return '間違えた問題はまだありません。';
      case _ListFilter.all:
        return '条件に一致する問題がありません。';
    }
  }
}

class _QuestionTile extends StatelessWidget {
  final ExamQuestion question;
  final int mistakeCount;
  final bool isBookmarked;

  const _QuestionTile({
    required this.question,
    required this.mistakeCount,
    required this.isBookmarked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(
        question.question,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: context.fontSizeSmall),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Flexible(
              child: Text(
                '${question.title} ・ ${question.classificationLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.fontSizeExtraSmall,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (question.figures.isNotEmpty || question.choices.any((c) => c.hasImage))
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.image_outlined,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isBookmarked)
            Icon(Icons.bookmark, size: 16, color: theme.colorScheme.primary),
          if (mistakeCount > 0)
            Text(
              '×$mistakeCount',
              style: TextStyle(
                fontSize: context.fontSizeExtraSmall,
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (!isBookmarked && mistakeCount == 0)
            const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamQuestionDetailPage(question: question),
        ),
      ),
    );
  }
}
