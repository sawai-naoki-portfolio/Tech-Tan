import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ads/ad_manager.dart';
import '../../../provider/all_words_provider.dart';
import '../../../provider/mistake_counts_provider.dart';
import '../../../provider/word_quiz_filter_provider.dart';
import '../../../utility/generate_quiz_questions.dart';
import '../../../utility/responsive_sizes.dart';
import '../../../utility/word_test_question.dart';
import 'word_test_result_page.dart';

/// ---------------------------------------------------------------------------
/// WordTestPage
/// ---------------------------------------------------------------------------
/// 単語の説明文から用語名を当てる 4 択テスト。
/// 選択肢をタップすると正誤判定が行われ、最終的にテスト結果画面へ遷移する。
class WordTestPage extends ConsumerStatefulWidget {
  final int quizCount;

  const WordTestPage({super.key, this.quizCount = 10});

  @override
  ConsumerState<WordTestPage> createState() => _WordTestPageState();
}

class _WordTestPageState extends ConsumerState<WordTestPage> {
  List<WordTestQuestion>? _quiz; // 出題用の問題リスト（データ到着後に一度だけ生成）
  int _currentIndex = 0;
  bool _isAnswered = false; // 現在の問題に対して処理中か（連打防止）

  @override
  void initState() {
    super.initState();
    AdManager.loadAd(AdType.interstitial);
  }

  @override
  Widget build(BuildContext context) {
    final allWords = ref.watch(allWordsProvider);
    final filters = ref.watch(wordQuizFilterProvider);

    // 説明文が問題文になるため、説明が未入力のものは除く
    final pool = allWords
        .where((w) =>
            filters.contains(w.category) && w.description.trim().isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('単語テスト')),
      body: Builder(
        builder: (context) {
          if (pool.isEmpty) {
            return const Center(child: Text('出題できる単語がありません'));
          }
          // 初回のデータ到着時にだけ出題内容を確定させる
          final quiz = _quiz ??=
              generateQuizQuestions(pool, pool, quizCount: widget.quizCount);
          if (quiz.isEmpty) {
            return const Center(child: Text('出題できる単語がありません'));
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
                // 問題（単語の説明）の表示
                Text(
                  current.word.description,
                  style: TextStyle(
                    fontSize: context.fontSizeMedium,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                // 選択肢ボタン群：回答後は正解・不正解の色分けを反映
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                      ),
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

    // 不正解の場合、ミス回数をカウントアップ
    if (!current.isCorrect) {
      await ref
          .read(mistakeCountsProvider.notifier)
          .increment(current.word.name);
    }

    // 1秒後に次の問題へ。最後なら結果画面へ
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
        MaterialPageRoute(builder: (_) => WordTestResultPage(quiz: quiz)),
      );
    });
  }
}
