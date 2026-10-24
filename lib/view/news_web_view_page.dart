import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../ads/ad_manager.dart';

/// WebView 内での遷移を許可するスキーム。
/// これ以外（javascript: / file: / data: / intent: / 独自スキームなど）は
/// 端末内ファイルの読み出しや外部アプリの意図しない起動につながるため遮断する。
const _allowedSchemes = {'https', 'http'};

bool _isAllowedUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;
  return _allowedSchemes.contains(uri.scheme.toLowerCase());
}

/// ---------------------------------------------------------------------------
/// NewsWebViewPage
/// ─ ニュース記事をアプリ内ブラウザで表示する画面。
///   外部サイトを JavaScript 有効で開くため、遷移先スキームの制限と
///   カメラ・位置情報などの権限要求の拒否を行っている。
/// ---------------------------------------------------------------------------
class NewsWebViewPage extends StatefulWidget {
  final String url;

  const NewsWebViewPage({super.key, required this.url});

  @override
  State<NewsWebViewPage> createState() => _NewsWebViewPageState();
}

class _NewsWebViewPageState extends State<NewsWebViewPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  String _currentHost = '';

  @override
  void initState() {
    super.initState();

    // 不正・危険なスキームの URL はそもそも読み込まない
    if (!_isAllowedUrl(widget.url)) {
      _isLoading = false;
      _errorMessage = 'この記事のURLは開けません。';
      return;
    }
    _currentHost = Uri.parse(widget.url).host;

    // Android 用プラットフォーム実装を登録
    if (Platform.isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // 許可したスキーム以外への遷移はブロックする
            if (!_isAllowedUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _currentHost = Uri.tryParse(url)?.host ?? _currentHost;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            // サブリソースの失敗ではページ全体をエラー扱いにしない
            if (!error.isForMainFrame.orTrue) return;
            setState(() {
              _isLoading = false;
              _errorMessage = '記事を読み込めませんでした。';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // 外部サイトからのカメラ・マイク・位置情報などの要求は一律で拒否する
    final platformController = controller.platform;
    if (platformController is AndroidWebViewController) {
      platformController
        ..setOnPlatformPermissionRequest((request) => request.deny())
        ..setMediaPlaybackRequiresUserGesture(true)
        ..setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (request) async => const GeolocationPermissionsResponse(
            allow: false,
            retain: false,
          ),
        );
    }

    _controller = controller;
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('ブラウザを開けませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('記事閲覧'),
            // 表示中のドメインを見せて、どのサイトを見ているか分かるようにする
            if (_currentHost.isNotEmpty)
              Text(
                _currentHost,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'ブラウザで開く',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _openInBrowser,
                      child: const Text('ブラウザで開く'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                if (controller != null) WebViewWidget(controller: controller),
                if (_isLoading) const LinearProgressIndicator(minHeight: 2),
              ],
            ),
      // 記事は読むのに時間がかかるため、閲覧を妨げないバナーで広告を表示する
      bottomNavigationBar: AdManager.bannerAdWidget(),
    );
  }
}

extension on bool? {
  /// null（プラットフォームが判定できない場合）はメインフレーム扱いにする
  bool get orTrue => this ?? true;
}
