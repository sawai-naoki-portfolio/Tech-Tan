// *****************************************************************************
// AdManager
// -----------------------------------------------------------------------------
// AdMob 広告のロード・表示を一手に引き受けるクラス。
// ・広告ユニット ID はビルドモード（リリース／デバッグ）とプラットフォームで自動切替
// ・インタースティシャル広告には表示間隔のキャップを設けている
// ・バナーは画面ごとに独立したインスタンスを持つ BannerAdView として提供する
//   （同一の Ad インスタンスを複数の AdWidget に渡すと例外になるため）
// *****************************************************************************

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_config.dart';

/// 使いたい広告の種類
enum AdType {
  appOpen, // アプリ起動時広告（App Open Ad）
  banner, // バナー広告
  rewarded, // リワード広告
  interstitial, // インタースティシャル広告
}

class AdManager {
  AdManager._();

  // ---------------------------------------------------------------------------
  // 広告ユニット ID
  // ---------------------------------------------------------------------------
  // 実際の ID は AdConfig（--dart-define-from-file で注入）が保持している。
  // デバッグビルドでは常にテスト用 ID を使い、誤クリックによるポリシー違反を防ぐ。

  /// 広告 SDK が動作するプラットフォームか（Web / デスクトップでは動作しない）
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// 本番 ID を使ってよいか（リリースビルドのみ）
  static bool get _useProdIds => kReleaseMode && isSupported;

  static bool get _isIOS => !kIsWeb && Platform.isIOS;

  static String get _appOpenAdUnitId => !_useProdIds
      ? TestAdUnitIds.appOpen
      : (_isIOS ? AdConfig.iosAppOpen : AdConfig.androidAppOpen);

  static String get _bannerAdUnitId => !_useProdIds
      ? TestAdUnitIds.banner
      : (_isIOS ? AdConfig.iosBanner : AdConfig.androidBanner);

  static String get _rewardedAdUnitId => !_useProdIds
      ? TestAdUnitIds.rewarded
      : (_isIOS ? AdConfig.iosRewarded : AdConfig.androidRewarded);

  static String get _interstitialAdUnitId => !_useProdIds
      ? TestAdUnitIds.interstitial
      : (_isIOS ? AdConfig.iosInterstitial : AdConfig.androidInterstitial);

  // ---------------------------------------------------------------------------
  // 保持しているインスタンス
  // ---------------------------------------------------------------------------
  static RewardedAd? _rewardedAd;
  static InterstitialAd? _interstitialAd;

  /// インタースティシャルの最短表示間隔。
  /// 記事タップのたびに全画面広告が出るとユーザー体験を損ない、
  /// AdMob のポリシー（過度な広告表示）にも抵触しうるため必ずキャップを掛ける。
  static const _interstitialCapInterval = Duration(minutes: 3);
  static const _interstitialCapKey = 'last_interstitial_ad';

  /// App Open 広告の最短表示間隔
  static const _appOpenCapInterval = Duration(hours: 2);
  static const _appOpenCapKey = 'last_app_open_ad';

  static bool _initialized = false;

  /// SDK 初期化。main() から一度だけ呼ぶ。
  static Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    _initialized = true;
    if (kReleaseMode && !AdConfig.hasProductionIds) {
      // リリースビルドなのにテスト用 ID のままだと収益が発生しない
      debugPrint('[AdManager] 本番の広告ユニットIDが未設定です。'
          'ビルド時に --dart-define-from-file=dart_defines.json を指定してください。');
    }
    await MobileAds.instance.initialize();
  }

  /// 任意のタイミングで呼ぶだけでOK
  static void loadAd(AdType type) {
    if (!isSupported) return;
    switch (type) {
      case AdType.appOpen:
        _loadAppOpenAd();
      case AdType.banner:
        // バナーは BannerAdView が各画面で自前にロードするため、ここでは何もしない。
        break;
      case AdType.rewarded:
        _loadRewardedAd();
      case AdType.interstitial:
        _loadInterstitialAd();
    }
  }

  static void _loadInterstitialAd() {
    if (_interstitialAd != null) return; // ロード済みなら二重取得しない
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (err) {
          debugPrint('InterstitialAd load failed: $err');
          _interstitialAd = null;
        },
      ),
    );
  }

  /// アプリ起動時用 App Open Ad をロードしてすぐ表示
  static void _loadAppOpenAd() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_appOpenCapKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    // 前回表示から一定時間が経っていなければ何もしない
    if (now - lastShown < _appOpenCapInterval.inMilliseconds) return;

    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, err) => ad.dispose(),
          );
          ad.show();
          // 表示したタイミングを保存
          prefs.setInt(_appOpenCapKey, now);
        },
        onAdFailedToLoad: (err) => debugPrint('AppOpenAd load failed: $err'),
      ),
    );
  }

  /// リワード広告をロード（表示は showRewardedAd() で）
  static void _loadRewardedAd() {
    if (_rewardedAd != null) return;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (err) => debugPrint('RewardedAd failed: $err'),
      ),
    );
  }

  /// バナー用 Widget を返す。
  /// 画面ごとに独立した BannerAd を保持するため、複数画面で同時に使っても安全。
  static Widget bannerAdWidget() {
    if (!isSupported) return const SizedBox.shrink();
    return BannerAdView(adUnitId: _bannerAdUnitId);
  }

  /// リワード広告を表示
  /// [onUserEarned] 報酬を得たとき / [onAdClosedWithoutReward] 報酬なしで閉じたとき
  static void showRewardedAd({
    required VoidCallback onUserEarned,
    required VoidCallback onAdClosedWithoutReward,
  }) {
    final ad = _rewardedAd;
    if (ad == null) {
      // 広告未ロード or ネットワークエラー時は報酬ナシ扱い
      onAdClosedWithoutReward();
      return;
    }
    _rewardedAd = null;
    bool earned = false;
    ad
      ..fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          if (!earned) onAdClosedWithoutReward();
          loadAd(AdType.rewarded);
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          onAdClosedWithoutReward();
          loadAd(AdType.rewarded);
        },
      )
      ..show(onUserEarnedReward: (ad, reward) {
        earned = true;
        onUserEarned();
      });
  }

  /// インタースティシャル広告を表示し、閉じられたら [onComplete] を呼ぶ。
  /// 未ロード時・表示間隔のキャップ内のときは広告を出さず即座に [onComplete] を呼ぶ。
  static void showInterstitialAd({required VoidCallback onComplete}) {
    if (!isSupported || _interstitialAd == null) {
      onComplete();
      return;
    }
    _showInterstitialAd(onComplete);
  }

  static Future<void> _showInterstitialAd(VoidCallback onComplete) async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_interstitialCapKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final ad = _interstitialAd;
    if (ad == null ||
        now - lastShown < _interstitialCapInterval.inMilliseconds) {
      onComplete();
      return;
    }
    _interstitialAd = null;
    await prefs.setInt(_interstitialCapKey, now);
    ad
      ..fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          onComplete();
          loadAd(AdType.interstitial);
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          onComplete();
          loadAd(AdType.interstitial);
        },
      )
      ..show();
  }
}

/// ---------------------------------------------------------------------------
/// BannerAdView
/// ─ 自分専用の BannerAd をロードし、破棄まで面倒を見るバナー表示ウィジェット。
///   AdWidget は 1 つの Ad インスタンスにつき 1 つしかツリーに置けないため、
///   静的インスタンスを共有せず画面ごとに生成する。
/// ---------------------------------------------------------------------------
class BannerAdView extends StatefulWidget {
  final String adUnitId;

  const BannerAdView({super.key, required this.adUnitId});

  @override
  State<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends State<BannerAdView> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed: $error');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null || !_isLoaded) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
