import 'package:flutter/material.dart';

import '../../utility/responsive_sizes.dart';
import '../test_page/exam_test/exam_questions_list_page.dart';
import '../test_page/exam_test/exam_quiz_settings_page.dart';
import '../test_page/word_test/word_quiz_settings_page.dart';
import '../word_list_page.dart';
import 'cache_clear_screen.dart';
import 'feedback_page.dart';
import 'memo_list_page.dart';
import 'privacy_policy.dart';
import 'search_history_page.dart';
import 'theme_settings_page.dart';

/// ---------------------------------------------------------------------------
/// SettingsPage
/// ─ 各種設定・データ管理画面への入口をまとめた画面
/// ---------------------------------------------------------------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: '全般'),
          _SettingsTile(
            icon: Icons.color_lens,
            title: 'テーマの変更',
            builder: (_) => const ThemeSettingsPage(),
          ),
          _SettingsTile(
            icon: Icons.delete_forever,
            title: 'キャッシュクリア',
            builder: (_) => const CacheClearScreen(),
          ),
          const Divider(),
          const _SectionHeader(title: '単語検索'),
          _SettingsTile(
            icon: Icons.history,
            title: '検索履歴',
            builder: (_) => const SearchHistoryPage(),
          ),
          const Divider(),
          const _SectionHeader(title: 'メモ一覧・単語一覧'),
          _SettingsTile(
            icon: Icons.note,
            title: 'メモ一覧',
            builder: (_) => const MemoListPage(),
          ),
          _SettingsTile(
            icon: Icons.list,
            title: '単語一覧',
            builder: (_) => const WordListPage(),
          ),
          _SettingsTile(
            icon: Icons.quiz,
            title: '単語テストの出題範囲',
            builder: (_) => const WordQuizSettingsPage(),
          ),
          const Divider(),
          const _SectionHeader(title: '実践問題（過去問）'),
          _SettingsTile(
            icon: Icons.tune,
            title: '出題範囲の設定',
            builder: (_) => const ExamQuizSettingsPage(),
          ),
          _SettingsTile(
            icon: Icons.library_books,
            title: '過去問一覧',
            builder: (_) => const ExamQuestionsListPage(),
          ),
          _SettingsTile(
            icon: Icons.bookmark,
            title: 'あとで解き直す問題',
            builder: (_) => const ExamQuestionsListPage.bookmarked(),
          ),
          _SettingsTile(
            icon: Icons.trending_down,
            title: '間違えた問題',
            builder: (_) => const ExamQuestionsListPage.weak(),
          ),
          const Divider(),
          const _SectionHeader(title: 'セキュリティとプライバシーポリシー'),
          _SettingsTile(
            icon: Icons.description,
            title: 'プライバシーポリシー',
            builder: (_) => const PrivacyPolicy(),
          ),
          _SettingsTile(
            icon: Icons.feedback,
            title: 'フィードバック',
            builder: (_) => const FeedbackPage(),
          ),
        ],
      ),
    );
  }
}

/// セクション見出し
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.paddingMedium),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.fontSizeLarge,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 画面遷移する設定項目
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final WidgetBuilder builder;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: builder),
      ),
    );
  }
}
