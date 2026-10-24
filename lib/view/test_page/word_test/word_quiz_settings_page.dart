import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifier/word_quiz_filter_notifier.dart';
import '../../../provider/all_words_provider.dart';
import '../../../provider/exam_type_provider.dart';
import '../../../provider/word_quiz_filter_provider.dart';
import '../../../utility/exam_type.dart';
import '../../../utility/responsive_sizes.dart';
import '../../../utility/word.dart';
import 'word_test_page.dart';

/// ---------------------------------------------------------------------------
/// WordQuizSettingsPage
/// ─ 単語テストの出題範囲（どの試験の単語から出すか）を選んで出題する画面。
///   テク単は 3 資格ぶんの単語を収録しているため、簿記単と違って
///   出題前に範囲を決められるようにしている。
/// ---------------------------------------------------------------------------
class WordQuizSettingsPage extends ConsumerWidget {
  const WordQuizSettingsPage({super.key});

  /// チェック項目の下に出す補足。どの段階の単語かを示す。
  static Widget? _levelHint(BuildContext context, String category) {
    if (category == Word.customCategory) return null;
    final exam = ExamType.values.firstWhere(
      (e) => e.label == category,
      orElse: () => ExamType.itPassport,
    );
    const hints = {
      0: '基礎用語（どの試験でも土台になります）',
      1: '実装・技術寄りの用語',
      2: '応用・設計寄りの用語',
    };
    final hint = hints[exam.level];
    if (hint == null) return null;
    return Text(
      hint,
      style: TextStyle(fontSize: context.fontSizeExtraSmall),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(wordQuizFilterProvider);
    final allWords = ref.watch(allWordsProvider);
    final exam = ref.watch(examTypeProvider);

    // 説明文が問題文になるため、説明が空の単語は出題できない
    final available = allWords
        .where((w) =>
            filters.contains(w.category) && w.description.trim().isNotEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('単語テスト設定'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: context.paddingMedium,
          vertical: context.paddingSmall,
        ),
        children: [
          Text(
            '単語の説明文から、その用語名を4択で当てるテストです。',
            style: TextStyle(fontSize: context.fontSizeSmall),
          ),
          const SizedBox(height: 16),
          Text(
            '出題範囲',
            style: TextStyle(
              fontSize: context.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          // 単語データは試験をまたいで重複しない差分なので、
          // 「自分の試験に合わせる」＝下位試験も含めた累積を選ぶことになる。
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => ref
                    .read(wordQuizFilterProvider.notifier)
                    .updateFilters(exam.cumulativeLabels),
                icon: const Icon(Icons.tune, size: 18),
                label: Text(
                  '${exam.label}の範囲に合わせる'
                  '${exam.cumulativeHint == null ? '' : '（${exam.cumulativeHint}）'}',
                  style: TextStyle(fontSize: context.fontSizeExtraSmall),
                ),
              ),
            ),
          ),
          for (final filter in WordQuizFilterNotifier.availableFilters)
            CheckboxListTile(
              title: Text(filter),
              subtitle: _levelHint(context, filter),
              value: filters.contains(filter),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => ref
                  .read(wordQuizFilterProvider.notifier)
                  .toggleFilter(filter, value ?? false),
            ),
          const SizedBox(height: 8),
          Text(
            '出題できる単語: $available語',
            style: TextStyle(
              fontSize: context.fontSizeSmall,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            // 1つも選択されていない／出題できる単語が無いときは開始できない
            onPressed: available == 0
                ? null
                : () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const WordTestPage()),
                    ),
            icon: const Icon(Icons.play_arrow),
            label: Text('テストを始める',
                style: TextStyle(fontSize: context.fontSizeMedium)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: context.paddingSmall),
            ),
          ),
          if (available == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '出題範囲を1つ以上選択してください。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: context.fontSizeExtraSmall),
              ),
            ),
        ],
      ),
    );
  }
}
