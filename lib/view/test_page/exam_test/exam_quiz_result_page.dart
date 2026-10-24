import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ads/ad_manager.dart';
import '../../../provider/checked_exam_questions_provider.dart';
import '../../../provider/question_mistakes_provider.dart';
import '../../../utility/exam_question.dart';
import '../../../utility/responsive_sizes.dart';
import 'exam_question_detail_page.dart';
import 'exam_quiz_page.dart';

/// リワード広告を見たときに増える問題数
const _rewardBonusCount = 5;

/// ---------------------------------------------------------------------------
/// ExamQuizResultPage
/// ─ 実践問題の結果画面。
///   情報処理技術者試験の午前は 60% が合格ラインなので、
///   正答率と合否の目安を最初に出す。各問はカードで振り返れる。
/// ---------------------------------------------------------------------------
class ExamQuizResultPage extends ConsumerWidget {
  final List<ExamQuestion> questions;
  final List<bool> results;

  const ExamQuizResultPage({
    super.key,
    required this.questions,
    required this.results,
  });

  /// 情報処理技術者試験の午前試験の合格基準
  static const passingRate = 0.6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correctCount = results.where((r) => r).length;
    final rate = questions.isEmpty ? 0.0 : correctCount / questions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('結果')),
      body: Padding(
        padding: EdgeInsets.all(context.paddingSmall),
        child: Column(
          children: [
            _ScoreCard(
              correctCount: correctCount,
              total: questions.length,
              rate: rate,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  // 途中で中断した場合に備え、範囲外は未回答（不正解）扱いにする
                  final isCorrect =
                      index < results.length ? results[index] : false;
                  return _ResultCard(
                    question: questions[index],
                    index: index,
                    isCorrect: isCorrect,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  icon: const Icon(Icons.home),
                  label: Text('ホームに戻る',
                      style: TextStyle(fontSize: context.fontSizeMedium)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _retry(context),
                  icon: const Icon(Icons.refresh),
                  label: Text('もう一度',
                      style: TextStyle(fontSize: context.fontSizeMedium)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// リワード広告を挟んで再挑戦する。報酬を得られた場合のみ問題数を増やす。
  void _retry(BuildContext context) {
    final currentCount = questions.length;

    void restart(int quizCount) {
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ExamQuizPage(overrideCount: quizCount),
        ),
      );
    }

    AdManager.showRewardedAd(
      onUserEarned: () async {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('報酬ゲット！'),
            content: const Text('問題数が＋$_rewardBonusCount問増量されました！'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        restart(currentCount + _rewardBonusCount);
      },
      // 広告を閉じただけ／未ロード時は元の問題数で再挑戦
      onAdClosedWithoutReward: () => restart(currentCount),
    );
  }
}

/// 得点と合格ラインの達成状況
class _ScoreCard extends StatelessWidget {
  final int correctCount;
  final int total;
  final double rate;

  const _ScoreCard({
    required this.correctCount,
    required this.total,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reachedPassing = rate >= ExamQuizResultPage.passingRate;
    final accent = reachedPassing ? Colors.green : theme.colorScheme.error;
    final percent = (rate * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            '$correctCount / $total 問正解',
            style: TextStyle(
              fontSize: context.fontSizeExtraLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '正答率 $percent%',
            style: TextStyle(
              fontSize: context.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 8,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            reachedPassing
                ? '合格ライン（60%）に届いています。この調子で続けましょう。'
                : '合格ラインは 60% です。間違えた問題は「苦手復習」で解き直せます。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: context.fontSizeExtraSmall),
          ),
        ],
      ),
    );
  }
}

/// 1問分の結果カード
class _ResultCard extends ConsumerWidget {
  final ExamQuestion question;
  final int index;
  final bool isCorrect;

  const _ResultCard({
    required this.question,
    required this.index,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent =
        isCorrect ? theme.colorScheme.primary : theme.colorScheme.error;
    final mistakeCount = ref.watch(questionMistakesProvider)[question.id] ?? 0;
    final isBookmarked =
        ref.watch(checkedExamQuestionsProvider).contains(question.id);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExamQuestionDetailPage(question: question),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: accent.withValues(alpha: 0.06),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '問題 ${index + 1}',
                    style: TextStyle(
                      fontSize: context.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCorrect ? '正解' : '不正解',
                    style: TextStyle(
                      fontSize: context.fontSizeSmall,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                    ),
                    tooltip: 'あとで解き直す',
                    onPressed: () => ref
                        .read(checkedExamQuestionsProvider.notifier)
                        .toggle(question.id),
                  ),
                ],
              ),
              Text(
                '${question.title} ・ ${question.classificationLabel}',
                style: TextStyle(
                  fontSize: context.fontSizeExtraSmall,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                question.question,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.fontSizeSmall),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '正解: ${question.answer}',
                    style: TextStyle(
                      fontSize: context.fontSizeSmall,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (mistakeCount > 0)
                    Text(
                      '累計ミス $mistakeCount 回',
                      style: TextStyle(
                        fontSize: context.fontSizeExtraSmall,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'タップすると解説を見られます',
                style: TextStyle(
                  fontSize: context.fontSizeExtraSmall,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
