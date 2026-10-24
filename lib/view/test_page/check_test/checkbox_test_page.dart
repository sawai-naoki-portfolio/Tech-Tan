import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ads/ad_manager.dart';
import '../../../provider/all_words_provider.dart';
import '../../../provider/checked_questions_provider.dart';
import '../../../provider/mistake_counts_provider.dart';
import '../../../utility/generate_quiz_questions.dart';
import '../../../utility/responsive_sizes.dart';
import '../../../utility/word.dart';
import '../../../utility/word_test_question.dart';
import '../word_test/word_test_result_page.dart';

/// ---------------------------------------------------------------------------
/// CheckboxTestPage
/// ---------------------------------------------------------------------------
/// 「単語チェック問題」に登録した単語だけを対象にしたテスト画面。
/// 誤答候補は全単語から集めるため、登録数が少なくても消去法では解けない。
class CheckboxTestPage extends ConsumerStatefulWidget {
  const CheckboxTestPage({super.key});

  @override
  ConsumerState<CheckboxTestPage> createState() => _CheckboxTestPageState();
}

class _CheckboxTestPageState extends ConsumerState<CheckboxTestPage> {
  List<WordTestQuestion>? _quiz; // 出題対象（データ到着後に一度だけ生成）
  int _currentIndex = 0;
  bool _isAnswered = false; // 現在の問題に対して処理中か（連打防止）

  @override
  void initState() {
    super.initState();
    AdManager.loadAd(AdType.interstitial);
  }

  /// チェック済み単語だけを抽出し、そこからクイズ問題を作成する
  List<WordTestQuestion> _generateQuiz(List<Word> words, Set<String> checked) {
    final filtered = words
        .where((w) =>
            checked.contains(w.name) && w.description.trim().isNotEmpty)
        .toList();
    if (filtered.isEmpty) return const [];
    return generateQuizQuestions(filtered, words, quizCount: 10);
  }

  @override
  Widget build(BuildContext context) {
    final allWords = ref.watch(allWordsProvider);
    final checked = ref.watch(checkedQuestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('単語チェック')),
      body: Builder(
        builder: (context) {
          // 初回のデータ到着時にだけ、チェック済み単語から問題を生成する
          final quiz = _quiz ??= _generateQuiz(allWords, checked);
          if (quiz.isEmpty) {
            return const Center(child: Text('チェックされた問題がありません'));
          }

          final current = quiz[_currentIndex];
          return Padding(
            padding: EdgeInsets.all(context.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '問題 ${_currentIndex + 1} / ${quiz.length}',
                  style: TextStyle(
                    fontSize: context.fontSizeExtraLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  current.word.description,
                  style: TextStyle(
                    fontSize: context.fontSizeMedium,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                ...current.options.map((option) {
                  Color? btnColor;
                  if (current.userAnswer != null) {
                    if (option == current.word.name) {
                      btnColor = Colors.green;
                    } else if (option == current.userAnswer) {
                      btnColor = Colors.red;
                    }
                  }
                  return Container(
                    margin:
                        EdgeInsets.symmetric(vertical: context.paddingSmall),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: btnColor),
                      onPressed: current.userAnswer == null
                          ? () => _answer(quiz, current, option)
                          : null,
                      child: Text(
                        option,
                        style: TextStyle(fontSize: context.fontSizeMedium),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                if (current.userAnswer != null)
                  Text(
                    current.isCorrect
                        ? '正解！'
                        : '不正解。正解は ${current.word.name} です。',
                    style: TextStyle(
                      fontSize: context.fontSizeMedium,
                      color: current.isCorrect ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _answer(
    List<WordTestQuestion> quiz,
    WordTestQuestion current,
    String option,
  ) async {
    if (_isAnswered) return;
    _isAnswered = true;

    setState(() => current.userAnswer = option);

    if (!current.isCorrect) {
      await ref
          .read(mistakeCountsProvider.notifier)
          .increment(current.word.name);
    }

    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    if (_currentIndex < quiz.length - 1) {
      setState(() {
        _currentIndex++;
        _isAnswered = false;
      });
      return;
    }

    AdManager.showInterstitialAd(onComplete: () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WordTestResultPage(quiz: quiz, isCheckboxTest: true),
        ),
      );
    });
  }
}
