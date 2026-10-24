import 'package:tech_tan/utility/schedule_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduleItem', () {
    final item = ScheduleItem(
      id: 'abc',
      title: '応用情報の勉強',
      subject: '商業情報処理',
      startTime: DateTime(2026, 7, 27, 9, 30),
      endTime: DateTime(2026, 7, 27, 11, 0),
      description: '第3章まで',
      tasks: ['テキストを読む', '過去問を解く'],
    );

    test('toJson / fromJson で内容が保たれる', () {
      final restored = ScheduleItem.fromJson(item.toJson());

      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.subject, item.subject);
      expect(restored.startTime, item.startTime);
      expect(restored.endTime, item.endTime);
      expect(restored.description, item.description);
      expect(restored.tasks, item.tasks);
      expect(restored.isCompleted, isFalse);
      expect(restored.isExamDate, isFalse);
    });

    test('古い形式（isExamDate なし）でも復元できる', () {
      final json = item.toJson()..remove('isExamDate');

      expect(ScheduleItem.fromJson(json).isExamDate, isFalse);
    });

    test('copyWith は指定した項目だけを差し替える', () {
      final updated = item.copyWith(isCompleted: true);

      expect(updated.isCompleted, isTrue);
      expect(updated.id, item.id);
      expect(updated.title, item.title);
      expect(updated.tasks, item.tasks);
    });
  });
}
