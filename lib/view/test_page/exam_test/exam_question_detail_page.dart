import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/checked_exam_questions_provider.dart';
import '../../../provider/question_mistakes_provider.dart';
import '../../../utility/exam_question.dart';
import '../../../utility/responsive_sizes.dart';
import '../../widget/calculator_widget.dart';
import 'exam_question_view.dart';
import 'question_inquiry_button.dart';

/// ---------------------------------------------------------------------------
/// ExamQuestionDetailPage
/// ─ 1 問を「解く」タブと「解答・解説」タブで表示する画面。
///   解答 UI は出題画面と同じ ExamQuestionView を再利用している。
/// ---------------------------------------------------------------------------
class ExamQuestionDetailPage extends ConsumerWidget {
  final ExamQuestion question;

  const ExamQuestionDetailPage({super.key, required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakeCount = ref.watch(questionMistakesProvider)[question.id] ?? 0;
    final isBookmarked =
        ref.watch(checkedExamQuestionsProvider).contains(question.id);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(question.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.calculate),
              tooltip: '電卓',
              onPressed: () => showCalculatorSheet(context),
            ),
            IconButton(
              icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border),
              tooltip: 'あとで解き直す',
              onPressed: () => ref
                  .read(checkedExamQuestionsProvider.notifier)
                  .toggle(question.id),
            ),
            QuestionInquiryButton(question: question),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.edit), text: '解く'),
              Tab(icon: Icon(Icons.visibility), text: '解答・解説'),
            ],
          ),
        ),
        body: Column(
          children: [
            // 上部：基本情報カード
            Padding(
              padding: EdgeInsets.all(context.paddingSmall),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InfoCard(title: '試験', value: question.exam.shortLabel),
                  _InfoCard(title: '出題回', value: question.season.eraLabel),
                  _InfoCard(
                      title: '分野',
                      value: question.field.replaceAll('系', '')),
                  _InfoCard(title: 'ミス', value: '$mistakeCount 回'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // タブ1：自分で解く（出題画面と同じ挙動）
                  SingleChildScrollView(
                    padding: EdgeInsets.all(context.paddingMedium),
                    child: ExamQuestionView(
                      key: ValueKey('solve_${question.id}'),
                      question: question,
                      onAnswered: (isCorrect) {
                        if (isCorrect) return;
                        ref
                            .read(questionMistakesProvider.notifier)
                            .increment(question.id);
                      },
                    ),
                  ),
                  // タブ2：最初から答えと解説を表示
                  SingleChildScrollView(
                    padding: EdgeInsets.all(context.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExamQuestionView(
                          key: ValueKey('reveal_${question.id}'),
                          question: question,
                          revealAnswer: true,
                        ),
                        if (mistakeCount > 0) ...[
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () {
                              ref
                                  .read(questionMistakesProvider.notifier)
                                  .clear(question.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('苦手リストから外しました')),
                              );
                            },
                            icon: const Icon(Icons.done_all),
                            label: const Text('この問題は克服した（苦手リストから外す）'),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 上部に並ぶ小さな情報カード
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
