import 'package:flutter/material.dart';

import 'responsive_sizes.dart';

/// ---------------------------------------------------------------------------
/// SwipeToDeleteCard
/// ─ スワイプして削除するためのカードをラップします。
///   削除前に確認ダイアログを表示し、削除が確定されたときに onDismissed を呼び出します。
/// ---------------------------------------------------------------------------
class SwipeToDeleteCard extends StatelessWidget {
  final Widget child;
  final Key keyValue;
  final Future<bool> Function() onConfirm;
  final VoidCallback onDismissed;

  const SwipeToDeleteCard({
    super.key,
    required this.keyValue,
    required this.child,
    required this.onConfirm,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: keyValue,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: context.paddingMedium),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // 削除前に確認処理を行う
      confirmDismiss: (direction) async => await onConfirm(),
      // 削除が決定した場合の処理
      onDismissed: (direction) => onDismissed(),
      child: child,
    );
  }
}
