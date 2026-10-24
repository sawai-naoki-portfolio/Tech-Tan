// *****************************************************************************
// AdConfig
// -----------------------------------------------------------------------------
// AdMob の広告ユニット ID をソースコードから切り離すための設定クラス。
//
// 値は --dart-define-from-file で外部ファイルから注入する：
//   flutter run   --dart-define-from-file=dart_defines.json
//   flutter build apk --release --dart-define-from-file=dart_defines.json
//
// dart_defines.json は .gitignore 済み。書式は dart_defines.example.json を参照。
// 未指定の場合は Google 公式のテスト用 ID にフォールバックするため、
// 設定ファイルが無い環境でもビルド・実行はできる（ただし収益は発生しない）。
//
// 【注意】広告ユニット ID は暗号鍵のような「秘密情報」ではない。
// APK/IPA を解析すれば誰でも取得できるため、隠すこと自体にセキュリティ上の効果はない。
// ここで外部化しているのは、公開リポジトリに自分の収益用 ID を載せないための運用上の配慮。
// *****************************************************************************

/// Google 公式のテスト用広告ユニット ID
/// https://developers.google.com/admob/android/test-ads
class TestAdUnitIds {
  TestAdUnitIds._();

  static const appOpen = 'ca-app-pub-3940256099942544/9257395921';
  static const banner = 'ca-app-pub-3940256099942544/6300978111';
  static const rewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const interstitial = 'ca-app-pub-3940256099942544/1033173712';
}

class AdConfig {
  AdConfig._();

  // --- Android ---
  static const androidAppOpen = String.fromEnvironment(
    'ADMOB_ANDROID_APP_OPEN',
    defaultValue: TestAdUnitIds.appOpen,
  );
  static const androidBanner = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER',
    defaultValue: TestAdUnitIds.banner,
  );
  static const androidRewarded = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED',
    defaultValue: TestAdUnitIds.rewarded,
  );
  static const androidInterstitial = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL',
    defaultValue: TestAdUnitIds.interstitial,
  );

  // --- iOS ---
  // iOS 用の広告ユニットは未発行のため、既定ではテスト ID のまま。
  static const iosAppOpen = String.fromEnvironment(
    'ADMOB_IOS_APP_OPEN',
    defaultValue: TestAdUnitIds.appOpen,
  );
  static const iosBanner = String.fromEnvironment(
    'ADMOB_IOS_BANNER',
    defaultValue: TestAdUnitIds.banner,
  );
  static const iosRewarded = String.fromEnvironment(
    'ADMOB_IOS_REWARDED',
    defaultValue: TestAdUnitIds.rewarded,
  );
  static const iosInterstitial = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL',
    defaultValue: TestAdUnitIds.interstitial,
  );

  /// 本番用の ID が 1 つでも注入されているか。
  /// false のままリリースビルドすると広告収益が発生しないため、起動時に警告を出す。
  static bool get hasProductionIds =>
      androidAppOpen != TestAdUnitIds.appOpen ||
      androidBanner != TestAdUnitIds.banner ||
      androidRewarded != TestAdUnitIds.rewarded ||
      androidInterstitial != TestAdUnitIds.interstitial;
}
