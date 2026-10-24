// *****************************************************************************
// アプリのエントリーポイント
// -----------------------------------------------------------------------------
// Flutter / 広告 SDK の初期化を行い、Riverpod の ProviderScope でアプリ全体を
// ラップして MyApp を起動する。
// 画面・状態・広告の実装はそれぞれ view / notifier / ads 配下を参照。
// *****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ads/ad_manager.dart';
import 'provider/theme_provider.dart';
import 'provider/use_material3_provider.dart';
import 'view/search_page.dart';

/// テーマの基準色。IT・技術系の印象に寄せて青を採用している。
const _seedColor = Color(0xFF0B63CE);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdManager.initialize();

  // 起動直後に必要な広告のみ先読みする。
  // バナーは表示側（BannerAdView）が自前でロードするためここでは扱わない。
  AdManager.loadAd(AdType.appOpen);
  AdManager.loadAd(AdType.interstitial);
  AdManager.loadAd(AdType.rewarded);

  runApp(
    Phoenix(
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

/// [MyApp]
/// ─────────────────────────────────────────────────────────
/// アプリ全体のテーマ設定やホーム画面(SearchPage)を設定するルートウィジェットです。
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final useMaterial3 = ref.watch(useMaterial3Provider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'テク単',
      theme: ThemeData(
        fontFamily: 'Murecho',
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
        brightness: Brightness.light,
        useMaterial3: useMaterial3,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Murecho',
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
        useMaterial3: useMaterial3,
      ),
      themeMode: themeMode,
      home: const SearchPage(),
    );
  }
}
