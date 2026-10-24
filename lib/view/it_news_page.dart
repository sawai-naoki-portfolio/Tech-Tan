import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../ads/ad_manager.dart';
import '../provider/exam_type_provider.dart';
import '../utility/exam_type.dart';
import '../utility/responsive_sizes.dart';
import 'news_web_view_page.dart';

/// ニュースの 1 記事
class Article {
  final String title;
  final String link;
  final String pubDate;
  final String? thumbnail;
  final String? source; // 発行元

  Article({
    required this.title,
    required this.link,
    required this.pubDate,
    this.thumbnail,
    this.source,
  });
}

/// Google ニュースの RSS から記事一覧を取得する。
///
/// FutureProvider にしているため、画面の再描画のたびに再取得されることはない
/// （build 内で future を組み立てると毎回リクエストが飛んでしまう）。
final newsArticlesProvider =
    FutureProvider.family<List<Article>, String>((ref, query) async {
  final uri = Uri.parse('https://news.google.com/rss/search'
      '?q=${Uri.encodeComponent(query)}&hl=ja&gl=JP&ceid=JP:ja');
  // 応答が返らないまま画面が固まるのを防ぐためタイムアウトを設ける
  final res = await http.get(uri).timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) {
    throw Exception('ニュースの取得に失敗しました (HTTP ${res.statusCode})');
  }

  final doc = XmlDocument.parse(res.body);
  final articles = doc
      .findAllElements('item')
      .map((node) {
        final thumbnails = node.findElements('media:thumbnail');
        return Article(
          title: node.getElement('title')?.innerText ?? '',
          link: node.getElement('link')?.innerText ?? '',
          pubDate: node.getElement('pubDate')?.innerText ?? '',
          thumbnail: thumbnails.isEmpty
              ? null
              : _safeImageUrl(thumbnails.first.getAttribute('url')),
          source: node.getElement('source')?.innerText,
        );
      })
      // 外部由来のリンクは https/http のものだけを扱う
      .where((a) => _isHttpUrl(a.link))
      .toList();

  // 毎回同じ記事ばかりにならないよう、取得時に一度だけシャッフルして15件に絞る
  articles.shuffle();
  return articles.length > 15 ? articles.sublist(0, 15) : articles;
});

/// 記事ページの og:image を取得する（サムネイルが RSS に無い場合の補完）
final ogImageProvider =
    FutureProvider.family<String?, String>((ref, url) async {
  if (!_isHttpUrl(url)) return null;
  try {
    final res =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
    if (res.statusCode != 200) return null;
    // 巨大なページを丸ごと正規表現に掛けないよう、先頭部分（<head> 相当）だけを見る
    final head =
        res.body.length > 200000 ? res.body.substring(0, 200000) : res.body;
    final match = RegExp(r'<meta\s+property="og:image"\s+content="([^"]+)"',
            caseSensitive: false)
        .firstMatch(head);
    return _safeImageUrl(match?.group(1));
  } catch (_) {
    return null;
  }
});

/// http / https 以外のスキーム（javascript: や file: など）を弾く
bool _isHttpUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;
  final scheme = uri.scheme.toLowerCase();
  return scheme == 'https' || scheme == 'http';
}

/// 画像として読み込んでよい URL のみを返す
String? _safeImageUrl(String? url) => _isHttpUrl(url) ? url : null;

/// ---------------------------------------------------------------------------
/// ItNewsPage
/// ─ 3 資格それぞれの試験情報に加えて、情報処理技術者試験そのものと
///   IT 業界全般のニュースをタブで切り替えて読む画面。
///   開いたときは、勉強中の試験のタブが選ばれた状態で始まる。
/// ---------------------------------------------------------------------------
class ItNewsPage extends ConsumerStatefulWidget {
  const ItNewsPage({super.key});

  @override
  ConsumerState<ItNewsPage> createState() => _ItNewsPageState();
}

class _ItNewsPageState extends ConsumerState<ItNewsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// タブの見出しと検索クエリ。前半 3 つは ExamType と 1 対 1 で対応する。
  static final _tabs = <({String label, String query})>[
    for (final exam in ExamType.values)
      (label: exam.shortLabel, query: exam.newsQuery),
    (label: '情報処理', query: '情報処理技術者試験'),
    (label: 'IT全般', query: 'IT 技術 ニュース'),
  ];

  @override
  void initState() {
    super.initState();
    // 勉強中の試験のタブを初期表示にする
    final initialIndex = ExamType.values.indexOf(ref.read(examTypeProvider));
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openArticle(Article article) {
    // 記事の閲覧は「開いて戻る」を繰り返す回遊型の導線のため、
    // ここで全画面広告を挟むと摩擦が大きい。広告は記事画面のバナーで表示する。
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewsWebViewPage(url: article.link)),
    );
  }

  Widget _buildTab(int index) {
    final query = _tabs[index].query;
    final articlesAsync = ref.watch(newsArticlesProvider(query));

    return articlesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('取得エラー: $error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(newsArticlesProvider(query)),
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
      data: (articles) {
        if (articles.isEmpty) {
          return const Center(child: Text('記事が見つかりませんでした'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(newsArticlesProvider(query)),
          child: ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, i) => _ArticleCard(
              article: articles[i],
              onTap: () => _openArticle(articles[i]),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ITニュース'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, _buildTab),
      ),
      // 記事一覧は滞在時間が長いため、全画面広告ではなくバナーで表示する
      bottomNavigationBar: AdManager.bannerAdWidget(),
    );
  }
}

/// 記事カード
class _ArticleCard extends ConsumerWidget {
  final Article article;
  final VoidCallback onTap;

  const _ArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(context, ref, theme),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                article.title,
                style: TextStyle(
                  fontSize: context.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                '${article.source ?? ''} ・ ${article.pubDate}',
                style: TextStyle(
                  fontSize: context.fontSizeSmall,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, WidgetRef ref, ThemeData theme) {
    final thumbnail = article.thumbnail;
    if (thumbnail != null) {
      return Image.network(
        thumbnail,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(context, theme),
      );
    }

    // RSS にサムネイルが無い場合は記事ページの og:image を試す
    final ogImage = ref.watch(ogImageProvider(article.link));
    return ogImage.maybeWhen(
      data: (url) => url == null
          ? _placeholder(context, theme)
          : Image.network(
              url,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(context, theme),
            ),
      orElse: () => Container(
        width: double.infinity,
        height: 180,
        color: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _placeholder(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 180,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        article.source ?? '',
        style: TextStyle(
          fontSize: context.fontSizeMedium,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
