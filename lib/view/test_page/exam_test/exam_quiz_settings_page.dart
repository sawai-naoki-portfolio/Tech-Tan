import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/exam_questions_provider.dart';
import '../../../provider/exam_quiz_filter_provider.dart';
import '../../../provider/exam_type_provider.dart';
import '../../../provider/question_mistakes_provider.dart';
import '../../../utility/exam_question.dart';
import '../../../utility/exam_type.dart';
import '../../../utility/exam_quiz_filter.dart';
import '../../../utility/exam_season.dart';
import '../../../utility/responsive_sizes.dart';
import '../../widget/exam_switcher.dart';
import 'exam_quiz_page.dart';

/// ---------------------------------------------------------------------------
/// ExamQuizSettingsPage
/// ─ 実践問題（過去問）の出題範囲を決めてから出題する画面。
///
/// 簿記の仕訳問題は「級 × 商業/工業」の 3 通りを選ぶだけで済んだが、
/// 情報処理技術者試験は
///   ・分野が 3 系 × 中分類 20 前後
///   ・実施回が 30〜43 回分
///   ・1 回分を通しで解く演習が学習の中心
/// と条件が多いため、出題方式（モード）から選ぶ構成にしている。
/// ---------------------------------------------------------------------------
class ExamQuizSettingsPage extends ConsumerWidget {
  const ExamQuizSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exam = ref.watch(examTypeProvider);
    final filter = ref.watch(currentExamQuizFilterProvider);
    final questionsAsync = ref.watch(examQuestionsProvider(exam));
    final mistakes = ref.watch(questionMistakesProvider);

    void update(ExamQuizFilter next) {
      ref.read(examQuizFilterProvider.notifier).update(exam, next);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('実践問題'),
        centerTitle: true,
      ),
      body: questionsAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('過去問データを読み込んでいます…'),
            ],
          ),
        ),
        error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
        data: (questions) {
          final selectable = filter.apply(
            questions,
            mistakeCounts: mistakes,
          );

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: context.paddingMedium,
              vertical: context.paddingSmall,
            ),
            children: [
              const ExamSwitcher(),
              const SizedBox(height: 16),
              const _SectionTitle('出題方式'),
              RadioGroup<ExamQuizMode>(
                groupValue: filter.mode,
                onChanged: (value) {
                  if (value == null) return;
                  update(filter.copyWith(mode: value));
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final mode in ExamQuizMode.values)
                      RadioListTile<ExamQuizMode>(
                        value: mode,
                        title: Text(mode.label),
                        subtitle: Text(
                          mode.description,
                          style:
                              TextStyle(fontSize: context.fontSizeExtraSmall),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
              const Divider(height: 32),

              const _SectionTitle('出題分野'),
              _FieldSelector(
                exam: exam,
                filter: filter,
                onChanged: update,
              ),
              const Divider(height: 32),

              // モードごとに必要な設定だけを出す
              if (filter.mode == ExamQuizMode.season) ...[
                const _SectionTitle('解く回を選ぶ'),
                _SeasonPicker(
                  exam: exam,
                  filter: filter,
                  onChanged: update,
                ),
              ] else ...[
                if (filter.mode == ExamQuizMode.random) ...[
                  const _SectionTitle('出題する回'),
                  _SeasonRangeSelector(
                    exam: exam,
                    filter: filter,
                    onChanged: update,
                  ),
                  const Divider(height: 32),
                ],
                const _SectionTitle('出題数'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final count in kQuestionCountOptions)
                      ChoiceChip(
                        label: Text('$count問'),
                        selected: filter.questionCount == count,
                        onSelected: (_) =>
                            update(filter.copyWith(questionCount: count)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              _StartPanel(
                filter: filter,
                selectable: selectable,
                totalCount: questions.length,
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

/// 出題開始ボタンと、選ばれている条件のサマリ
class _StartPanel extends StatelessWidget {
  final ExamQuizFilter filter;
  final List<ExamQuestion> selectable;
  final int totalCount;

  const _StartPanel({
    required this.filter,
    required this.selectable,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canStart = selectable.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                filter.summary(),
                style: TextStyle(fontSize: context.fontSizeSmall),
              ),
              const SizedBox(height: 6),
              Text(
                canStart
                    ? '今回の出題: ${selectable.length}問（収録 $totalCount問）'
                    : '条件に合う問題がありません',
                style: TextStyle(
                  fontSize: context.fontSizeSmall,
                  fontWeight: FontWeight.bold,
                  color: canStart
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: canStart
              ? () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ExamQuizPage()),
                  )
              : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(
            '問題を解く',
            style: TextStyle(fontSize: context.fontSizeMedium),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: context.paddingSmall),
          ),
        ),
        if (!canStart)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              filter.mode == ExamQuizMode.weak
                  ? '間違えた問題がまだありません。まずはランダム演習から始めてみましょう。'
                  : '出題分野や回の指定を見直してください。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.fontSizeExtraSmall),
            ),
          ),
      ],
    );
  }
}

/// 大分類（系）と中分類の絞り込み
class _FieldSelector extends ConsumerWidget {
  final ExamType exam;
  final ExamQuizFilter filter;
  final ValueChanged<ExamQuizFilter> onChanged;

  const _FieldSelector({
    required this.exam,
    required this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tree = ref.watch(examCategoriesProvider(exam));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '未選択なら全分野から出題します。',
          style: TextStyle(fontSize: context.fontSizeExtraSmall),
        ),
        const SizedBox(height: 8),
        for (final field in kExamFields)
          _FieldTile(
            field: field,
            categories: tree[field] ?? const [],
            filter: filter,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

class _FieldTile extends StatelessWidget {
  final String field;
  final List<String> categories;
  final ExamQuizFilter filter;
  final ValueChanged<ExamQuizFilter> onChanged;

  const _FieldTile({
    required this.field,
    required this.categories,
    required this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = filter.fields.contains(field);
    final selectedCategories =
        categories.where(filter.categories.contains).toList();

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 12, bottom: 8),
      leading: Checkbox(
        value: isSelected,
        onChanged: (value) {
          final fields = {...filter.fields};
          if (value ?? false) {
            fields.add(field);
          } else {
            fields.remove(field);
            // 系のチェックを外したら、その配下の中分類も外す
            onChanged(filter.copyWith(
              fields: fields,
              categories: filter.categories
                  .where((c) => !categories.contains(c))
                  .toSet(),
            ));
            return;
          }
          onChanged(filter.copyWith(fields: fields));
        },
      ),
      title: Text(field),
      subtitle: selectedCategories.isEmpty
          ? null
          : Text(
              '中分類 ${selectedCategories.length} 件を指定中',
              style: TextStyle(fontSize: context.fontSizeExtraSmall),
            ),
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final category in categories)
              FilterChip(
                label: Text(
                  category,
                  style: TextStyle(fontSize: context.fontSizeExtraSmall),
                ),
                selected: filter.categories.contains(category),
                onSelected: (selected) {
                  final next = {...filter.categories};
                  final fields = {...filter.fields};
                  if (selected) {
                    next.add(category);
                    // 中分類を選んだら、その親の系も自動で有効にする
                    fields.add(field);
                  } else {
                    next.remove(category);
                  }
                  onChanged(filter.copyWith(categories: next, fields: fields));
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// 年度別演習で「どの回を解くか」を 1 つ選ぶ
class _SeasonPicker extends ConsumerWidget {
  final ExamType exam;
  final ExamQuizFilter filter;
  final ValueChanged<ExamQuizFilter> onChanged;

  const _SeasonPicker({
    required this.exam,
    required this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasons = ref.watch(examSeasonsProvider(exam));
    if (seasons.isEmpty) {
      return const Text('収録されている回がありません');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '新しい回から順に並んでいます。',
          style: TextStyle(fontSize: context.fontSizeExtraSmall),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final season in seasons)
              ChoiceChip(
                label: Text(
                  season.label,
                  style: TextStyle(fontSize: context.fontSizeExtraSmall),
                ),
                selected: filter.targetSeason == season.raw,
                onSelected: (_) =>
                    onChanged(filter.copyWith(targetSeason: season.raw)),
              ),
          ],
        ),
      ],
    );
  }
}

/// ランダム演習で対象にする回を複数選ぶ（未選択なら全期間）
class _SeasonRangeSelector extends ConsumerWidget {
  final ExamType exam;
  final ExamQuizFilter filter;
  final ValueChanged<ExamQuizFilter> onChanged;

  const _SeasonRangeSelector({
    required this.exam,
    required this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasons = ref.watch(examSeasonsProvider(exam));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '未選択なら全期間から出題します。',
          style: TextStyle(fontSize: context.fontSizeExtraSmall),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => onChanged(filter.copyWith(seasons: const {})),
              child: const Text('全期間'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              // 直近の出題傾向に合わせたいときのショートカット
              onPressed: seasons.isEmpty
                  ? null
                  : () => onChanged(filter.copyWith(
                        seasons: seasons
                            .take(5)
                            .map((ExamSeason s) => s.raw)
                            .toSet(),
                      )),
              child: const Text('直近5回'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final season in seasons)
              FilterChip(
                label: Text(
                  season.label,
                  style: TextStyle(fontSize: context.fontSizeExtraSmall),
                ),
                selected: filter.seasons.contains(season.raw),
                onSelected: (selected) {
                  final next = {...filter.seasons};
                  if (selected) {
                    next.add(season.raw);
                  } else {
                    next.remove(season.raw);
                  }
                  onChanged(filter.copyWith(seasons: next));
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.fontSizeLarge,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
