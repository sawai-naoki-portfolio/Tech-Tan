import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// ExamImageView
/// ─ 過去問の図表を表示するウィジェット。
///
/// 情報処理技術者試験の図（回路図・表・DFD など）は文字が小さく、
/// スマートフォンの幅では読み切れないことが多い。
/// そのためタップで全画面のピンチズーム表示に切り替えられるようにしている。
/// 画像が欠けているデータもごく一部あるため、失敗時は静かに代替表示へ倒す。
/// ---------------------------------------------------------------------------
class ExamImageView extends StatelessWidget {
  final String assetPath;

  /// 一覧などで縦に潰したいときの上限高さ。null なら原寸比のまま。
  final double? maxHeight;

  const ExamImageView({
    super.key,
    required this.assetPath,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '問題の図表。タップで拡大表示します。',
      button: true,
      child: InkWell(
        onTap: () => _openFullScreen(context),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // 図は白背景で作られているため、ダークテーマでも白地の板の上に置く
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight ?? double.infinity,
            ),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => _MissingImage(
                assetPath: assetPath,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullScreenImagePage(assetPath: assetPath),
      ),
    );
  }
}

/// 画像が読み込めなかったときの代替表示
class _MissingImage extends StatelessWidget {
  final String assetPath;

  const _MissingImage({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_not_supported_outlined, color: Colors.black45),
          const SizedBox(height: 8),
          const Text(
            '図を表示できませんでした',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            assetPath.split('/').last,
            style: const TextStyle(color: Colors.black38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// ピンチズームできる全画面表示
class _FullScreenImagePage extends StatelessWidget {
  final String assetPath;

  const _FullScreenImagePage({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('図を拡大'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 6,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) =>
                _MissingImage(assetPath: assetPath),
          ),
        ),
      ),
    );
  }
}
