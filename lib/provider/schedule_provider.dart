import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/schedule_notifier.dart';
import '../utility/schedule_item.dart';

/// 学習スケジュールの状態を管理する Provider
final scheduleProvider =
    NotifierProvider<ScheduleNotifier, List<ScheduleItem>>(
  ScheduleNotifier.new,
);
