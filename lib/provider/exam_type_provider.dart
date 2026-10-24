import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/exam_type_notifier.dart';
import '../utility/exam_type.dart';

/// いま勉強している試験（ITパスポート / 基本情報 / 応用情報）
final examTypeProvider = NotifierProvider<ExamTypeNotifier, ExamType>(
  ExamTypeNotifier.new,
);
