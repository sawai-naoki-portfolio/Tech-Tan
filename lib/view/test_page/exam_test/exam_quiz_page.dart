import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ads/ad_manager.dart';
import '../../../provider/checked_exam_questions_provider.dart';
import '../../../provider/exam_questions_provider.dart';
import '../../../provider/exam_quiz_filter_provider.dart';
import '../../../provider/exam_type_provider.dart';
import '../../../provider/question_mistakes_provider.dart';
import '../../../utility/exam_question.dart';
import '../../../utility/exam_quiz_filter.dart';
import '../../../utility/responsive_sizes.dart';
import '../../widget/calculator_widget.dart';
import 'exam_question_view.dart';
import 'exam_quiz_result_page.dart';
import 'question_inquiry_button.dart';

/// ---------------------------------------------------------------------------
/// ExamQuizPage
/// ─ 実践問題を 1 問ずつ出題する画面。
///   出題内容は ExamQuizSettingsPage で決めた条件から、最初のデータ到着時に
///   一度だけ確定させる（再描画のたびに問題が変わらないようにするため）。
/// ---------------------------------------------------------------------------
class ExamQuizPage extends ConsumerStatefulWidget {
  /// 「もう一度」から問題数を増やして再挑戦するときに使う上書き値
  final int? overrideCount;

  const ExamQuizPage({super.key, this.overrideCount});

  @override
  ConsumerState<ExamQuizPage> createState() => _ExamQuizPageState();
}

class _ExamQuizPageState extends ConsumerState<ExamQuizPage> {
  /// 出題対象。データの読み込みが終わるまでは null。
  List<ExamQuestion>? _quiz;

  int _currentIndex = 0;

  /// 各問の正誤（出題順）
  final List<bool> _results = [];

  bool get _isAnswered => _results.length > _currentIndex;

  @override
  void initState() {
    super.initState();
    AdManager.loadAd(AdType.interstitial);
  }

  void _onAnswered(bool isCorrect, ExamQuestion question) {
    setState(() => _results.add(isCorrect));
    if (!isCorrect) {
      // 苦手復習モードの出題順を決めるため、誤答を問題単位で記録する
      ref.read(questionMistakesProvider.notifier).increment(question.id);
    }
  }

  void _next() {
    final quiz = _quiz;
    if (quiz == null) return;

    if (_currentIndex < quiz.length - 1) {
      setState(() => _currentIndex++);
      return;
    }

    AdManager.showInterstitialAd(onComplete: () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ExamQuizResultPage(
            questions: quiz,
            results: List<bool>.from(_results),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examTypeProvider);
    final questionsAsync = ref.watch(examQuestionsProvider(exam));
    // 条件付きで watch すると Riverpod の依存関係が壊れるため、必ず先頭で watch する
    final filter = ref.watch(currentExamQuizFilterProvider);
    final mistakes = ref.watch(questionMistakesProvider);

    // 出題内容は、データが届いた最初のビルドで確定させる。
    // AppBar のしおり・お問い合わせボタンも同じ問題を参照するため、
    // body を組み立てる前にここで解決しておく必要がある。
    final allQuestions = questionsAsync.value;
    if (allQuestions != null) {
      _quiz ??= _pick(allQuestions, filter, mistakes);
    }
    final quiz = _quiz;

    return Scaffold(
      appBar: AppBar(
        title: Text('${exam.shortLabel} 実践問題'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            tooltip: '電卓',
            onPressed: () => showCalculatorSheet(context),
          ),
          if (quiz != null && quiz.isNotEmpty) ...[
            _BookmarkButton(question: quiz[_currentIndex]),
            QuestionInquiryButton(question: quiz[_currentIndex]),
          ],
        ],
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('データ読み込みエラー: $error')),
        data: (_) {
          final questions = quiz ?? const <ExamQuestion>[];

          if (questions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '条件に一致する問題がありません。\n出題範囲を見直してください。',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final current = questions[_currentIndex];
          final isLast = _currentIndex == questions.length - 1;

          return Column(
            children: [
              _ProgressHeader(
                current: _currentIndex + 1,
                total: questions.length,
                correctCount: _results.where((r) => r).length,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.paddingMedium,
                    vertical: context.paddingSmall,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExamQuestionView(
                        // 問題が変わったら選択状態をリセットしたいので key を付ける
                        key: ValueKey(current.id),
                        question: current,
                        onAnswered: (isCorrect) =>
                            _onAnswered(isCorrect, current),
                      ),
                      const SizedBox(height: 24),
                      if (_isAnswered)
                        ElevatedButton.icon(
                          onPressed: _next,
                          icon: Icon(isLast
                              ? Icons.flag
                              : Icons.arrow_forward),
                          label: Text(
                            isLast ? '結果を見る' : '次の問題へ',
                            style: TextStyle(fontSize: context.fontSizeMedium),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: context.paddingSmall),
                          ),
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 出題条件を適用する。「もう一度」で増量された場合は出題数だけ差し替える。
  List<ExamQuestion> _pick(
    List<ExamQuestion> all,
    ExamQuizFilter filter,
    Map<String, int> mistakes,
  ) {
    final override = widget.overrideCount;
    final effective =
        override == null ? filter : filter.copyWith(questionCount: override);
    return effective.apply(all, mistakeCounts: mistakes);
  }
}

/// 進捗バーと現在の正解数
class _ProgressHeader extends StatelessWidget {
  final int current;
  final int total;
  final int correctCount;

  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.correctCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: EdgeInsets.symmetric(
        horizontal: context.paddingMedium,
        vertical: context.paddingSmall,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '問題 $current / $total',
                style: TextStyle(
                  fontSize: context.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '正解 $correctCount',
                style: TextStyle(
                  fontSize: context.fontSizeSmall,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : current / total,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// 「あとで解き直す」に登録するボタン
class _BookmarkButton extends ConsumerWidget {
  final ExamQuestion question;

  const _BookmarkButton({required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isChecked =
        ref.watch(checkedExamQuestionsProvider).contains(question.id);
    return IconButton(
      icon: Icon(isChecked ? Icons.bookmark : Icons.bookmark_border),
      tooltip: isChecked ? 'あとで解き直すから外す' : 'あとで解き直す',
      onPressed: () {
        ref.read(checkedExamQuestionsProvider.notifier).toggle(question.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isChecked ? '登録を解除しました' : 'あとで解き直すに登録しました'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
