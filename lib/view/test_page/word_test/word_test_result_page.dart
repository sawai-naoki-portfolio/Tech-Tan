import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ads/ad_manager.dart';
import '../../../provider/all_words_provider.dart';
import '../../../provider/checked_questions_provider.dart';
import '../../../provider/mistake_counts_provider.dart';
import '../../../utility/responsive_sizes.dart';
import '../../../utility/word.dart';
import '../../../utility/word_test_question.dart';
import '../check_test/checkbox_test_page.dart';
import 'word_test_page.dart';

/// ---------------------------------------------------------------------------
/// WordTestResultPage
/// ---------------------------------------------------------------------------
/// 単語テストの結果画面。全体の正解数と、各問題の詳細（問題文・自分の回答・
/// 正解・選択肢・累計ミス回数）をカード形式で表示する。
class WordTestResultPage extends ConsumerWidget {
  final List<WordTestQuestion> quiz;
  final bool isCheckboxTest; // チェックテストから来たかどうか

  const WordTestResultPage({
    super.key,
    required this.quiz,
    this.isCheckboxTest = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correctCount = quiz.where((q) => q.isCorrect).length;

    return Scaffold(
      appBar: AppBar(title: const Text('テスト結果')),
      body: Padding(
        padding: EdgeInsets.all(context.paddingSmall),
        child: Column(
          children: [
            Text(
              '結果：$correctCount / ${quiz.length} 問正解',
              style: TextStyle(
                fontSize: context.fontSizeExtraLarge,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemCount: quiz.length,
                itemBuilder: (context, index) => _ResultCard(
                  question: quiz[index],
                  index: index,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: context.paddingSmall,
                        horizontal: context.paddingMedium),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  icon: const Icon(Icons.home),
                  label: Text('ホームに戻る',
                      style: TextStyle(fontSize: context.fontSizeMedium)),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        vertical: context.paddingSmall,
                        horizontal: context.paddingMedium),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () => _retry(context),
                  icon: const Icon(Icons.refresh),
                  label: Text('もう一度',
                      style: TextStyle(fontSize: context.fontSizeMedium)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 再挑戦。チェックテストはそのまま、通常テストはリワード広告で問題数を増やせる。
  void _retry(BuildContext context) {
    if (isCheckboxTest) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CheckboxTestPage()),
      );
      return;
    }

    final currentCount = quiz.length;

    void restart(int quizCount) {
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WordTestPage(quizCount: quizCount)),
      );
    }

    AdManager.showRewardedAd(
      onUserEarned: () async {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('報酬ゲット！'),
            content: const Text('問題数が＋10問増量されました！'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        restart(currentCount + 10);
      },
      // 広告を閉じただけ or 未ロード時は通常モードで再スタート
      onAdClosedWithoutReward: () => restart(currentCount),
    );
  }
}

/// 1問分の結果カード
class _ResultCard extends ConsumerWidget {
  final WordTestQuestion question;
  final int index;

  const _ResultCard({required this.question, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent =
        question.isCorrect ? theme.colorScheme.primary : theme.colorScheme.error;
    final mistakeCount =
        ref.watch(mistakeCountsProvider)[question.word.name] ?? 0;
    final isChecked =
        ref.watch(checkedQuestionsProvider).contains(question.word.name);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: accent.withValues(alpha: 0.08),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            padding: EdgeInsets.all(context.paddingSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '問題 ${index + 1}',
                  style: TextStyle(
                    fontSize: context.fontSizeExtraLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  question.word.description,
                  style: TextStyle(fontSize: context.fontSizeSmall),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(
                      vertical: context.paddingSmall,
                      horizontal: context.paddingMedium),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    question.isCorrect ? '正解' : '不正解',
                    style: TextStyle(
                      fontSize: context.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'あなたの回答: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: question.userAnswer ?? '未回答',
                        style: TextStyle(
                          fontSize: context.fontSizeMedium,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (!question.isCorrect) ...[
                        const TextSpan(
                          text: '\n正解: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        TextSpan(
                          text: question.word.name,
                          style: TextStyle(
                            fontSize: context.fontSizeMedium,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '選択肢:',
                  style: TextStyle(
                    fontSize: context.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: question.options.map((option) {
                    return ActionChip(
                      label: Text(option,
                          style: TextStyle(fontSize: context.fontSizeSmall)),
                      // 選択肢をタップすると、その単語の説明をダイアログで確認できる
                      onPressed: () => _showOptionMeaning(context, ref, option),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  '累計ミス回数: $mistakeCount 回',
                  style: TextStyle(
                    fontSize: context.fontSizeExtraSmall,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // カード右上のチェックボックスで「単語チェック問題」に登録できる
          Positioned(
            top: 8,
            right: 8,
            child: Checkbox(
              value: isChecked,
              onChanged: (_) => ref
                  .read(checkedQuestionsProvider.notifier)
                  .toggle(question.word.name),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionMeaning(BuildContext context, WidgetRef ref, String option) {
    final words = ref.read(allWordsProvider);
    final match = words.firstWhere(
      (w) => w.name == option,
      orElse: () => Word(
        name: option,
        yomigana: '',
        description: '説明がありません',
        category: '',
      ),
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(option),
        content: Text(match.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
