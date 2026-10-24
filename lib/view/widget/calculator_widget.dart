// ============================================================================
// CalculatorWidget
// -----------------------------------------------------------------------------
// 実践問題を解いている最中に呼び出せる電卓。
// 基本情報・応用情報では稼働率や基数変換など計算を伴う問題が出るため、
// アプリを離れずに計算できるようボトムシートとして提供する。
// ============================================================================

import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

import '../../utility/responsive_sizes.dart';

/// 電卓をボトムシートで開く
Future<void> showCalculatorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const CalculatorWidget(),
  );
}

class CalculatorWidget extends StatefulWidget {
  const CalculatorWidget({super.key});

  @override
  State<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  String display = '0';

  /// 数値が整数なら整数として、そうでなければ小数点以下も含めて文字列にする
  String _formatResult(double result) {
    if (result == result.roundToDouble()) return result.toInt().toString();
    return result.toString();
  }

  void _onPressed(String key) {
    setState(() {
      if (key == 'C') {
        display = '0';
      } else if (key == 'DEL') {
        display = display.substring(0, display.length - 1);
        if (display.isEmpty) display = '0';
      } else if (key == '±') {
        if (display.startsWith('-')) {
          display = display.substring(1);
        } else if (display != '0') {
          display = '-$display';
        }
      } else if (key == '=') {
        try {
          final expression = Parser().parse(display);
          final result =
              expression.evaluate(EvaluationType.REAL, ContextModel()) as double;
          display = _formatResult(result);
        } catch (_) {
          display = 'Error';
        }
      } else {
        // 初期状態 "0" またはエラー時に数字を押したら上書きする
        if ((display == '0' || display == 'Error') &&
            '0123456789.'.contains(key)) {
          display = key;
        } else {
          if (display == 'Error') display = '';
          display += key;
        }
      }
    });
  }

  Widget _buildButton(String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return ElevatedButton(
      onPressed: () => _onPressed(label),
      child: Text(label, style: TextStyle(fontSize: context.fontSizeMedium)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const keys = [
      'C', '±', '/', 'DEL', //
      '7', '8', '9', '*', //
      '4', '5', '6', '-', //
      '1', '2', '3', '+', //
      '0', '.', '(', ')', //
      '=', '', '', '', //
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(context.paddingMedium),
        child: SizedBox(
          height: 460,
          child: Column(
            children: [
              Row(
                children: [
                  Text('電卓',
                      style: TextStyle(
                          fontSize: context.fontSizeMedium,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: '閉じる',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              // 計算結果または入力中の式
              Container(
                padding: EdgeInsets.all(context.paddingMedium),
                alignment: Alignment.centerRight,
                child: Text(
                  display,
                  style: TextStyle(fontSize: context.fontSizeExtraLarge),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  childAspectRatio: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: keys.map(_buildButton).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
