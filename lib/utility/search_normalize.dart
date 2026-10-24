/// ---------------------------------------------------------------------------
/// normalizeForSearch
/// ─ 検索の表記ゆれを吸収するための正規化。
///
/// IPA の試験問題と収録データは JIS の表記（センサ・サーバ・プリンタ）に従うが、
/// 利用者は長音を付けて入力する（センサー・サーバー・プリンター）ことが多い。
/// 素直に部分一致で検索すると、収録済みの語がまったく引けなくなってしまうため、
/// 見出し語と入力の双方を次の規則でそろえてから比較する。
///
///   ・全角の英数字・記号 → 半角
///   ・カタカナ → ひらがな（"センサ" と "せんさ" のどちらでも引ける）
///   ・長音符・中黒・空白・区切り記号 → 削除
///   ・英字 → 小文字
///
/// 長音を落とすため "データ" と "デート" のような取り違えは起こりうるが、
/// 引けないより引きすぎるほうが検索としては実用的なので許容している。
/// ---------------------------------------------------------------------------
String normalizeForSearch(String input) {
  final buffer = StringBuffer();

  for (final rune in input.runes) {
    var code = rune;

    // 全角の英数字・記号（！〜～）を半角へ寄せる
    if (code >= 0xFF01 && code <= 0xFF5E) {
      code -= 0xFEE0;
    }
    // 全角スペースは半角スペース扱いにしてから、後段で落とす
    if (code == 0x3000) {
      code = 0x20;
    }
    // カタカナ（ァ〜ヶ）をひらがなへ。長音符 0x30FC は範囲外なので残る。
    if (code >= 0x30A1 && code <= 0x30F6) {
      code -= 0x60;
    }

    final char = String.fromCharCode(code);
    if (_ignoredChars.contains(char)) continue;

    buffer.write(char);
  }

  // 外来語の「エー」と「エイ」は書き手によって揺れる
  // （フェールセーフ / フェイルセーフ、メーン / メイン など）。
  // 長音符は上で落としているので、え段のあとの「い」も落として同じ形にそろえる。
  // 「けいさん」→「けさん」のように和語まで縮むが、
  // 検索語と見出し語の双方に同じ規則を適用するため引けなくなることはない。
  return _collapseEiToE(buffer.toString().toLowerCase());
}

/// え段の直後に続く「い」を落として、長音表記とそろえる
String _collapseEiToE(String input) {
  final buffer = StringBuffer();
  String? previous;
  for (final char in input.split('')) {
    if (char == 'い' && previous != null && _eRow.contains(previous)) {
      continue;
    }
    buffer.write(char);
    previous = char;
  }
  return buffer.toString();
}

/// え段のひらがな（カタカナは変換済みなので、ひらがなだけ見ればよい）
const _eRow = {
  'え', 'け', 'せ', 'て', 'ね', 'へ', 'め', 'れ', 'げ', 'ぜ', 'で', 'べ', 'ぺ',
  'ぇ', //
};

/// 表記の揺れやすい区切り記号。比較の前に取り除く。
const _ignoredChars = {
  'ー', // 長音符（センサー ↔ センサ）
  '・',
  '･',
  ' ',
  '-',
  '‐',
  '−',
  '—',
  '/',
  '_',
  '.',
  '、',
  '。',
  '（',
  '）',
  '(',
  ')',
};
