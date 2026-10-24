# テク単 — 設計ドキュメント

> **情報処理技術者試験（IP / FE / AP）の単語帳と過去問演習を 1 つにした学習アプリ。**
> IT 用語 2,176 語と午前問題 9,820 問（図表 約 3,100 枚）を収録し、IP → FE → AP と積み上げて学べる（Flutter / Android・iOS）。

<table>
<tr>
<td width="25%"><img src="screenshots/01_home.png" alt="ホーム"></td>
<td width="25%"><img src="screenshots/02_exam_settings.png" alt="出題設定"></td>
<td width="25%"><img src="screenshots/06_detail_figure.png" alt="図表つきの問題"></td>
<td width="25%"><img src="screenshots/07_word_list.png" alt="単語一覧"></td>
</tr>
<tr>
<td align="center">ホーム（試験切替・検索）</td>
<td align="center">出題方式・分野・回</td>
<td align="center">図表つきの問題</td>
<td align="center">累積の単語一覧</td>
</tr>
</table>

## プロジェクト概要

| 項目 | 内容 |
|---|---|
| 種別 | スマートフォンアプリ（個人開発。簿記検定向けの前作「簿記単」の続編。簿記単はこのポートフォリオに含めていない） |
| 対応 OS | Android / iOS |
| 担当・進め方 | 企画・データ整備・設計・テストを 1 人で担当。実装とドキュメント作成には生成 AI（Claude Code）を活用し、仕様決め・設計の判断・レビュー・テストでの検証は自分で行った |
| 開発時期 | 2026 年 7 月（コミットの記録: 7/28〜7/29） |
| 公開状況 | 未公開 |
| 規模 | Dart 約 10,100 行（`lib/` 88 ファイル）＋ テスト 93 ケース ／ 主要 25 画面 |
| 収録データ | 単語 2,176 語、過去問 9,820 問、図表 約 3,100 枚（開発版で約 38MB。公開版は第三者の解説を除いたため約 28MB） |
| 収益モデル | 広告（バナー・インタースティシャル・リワード・アプリ起動） |

### 技術スタック

| 分類 | 技術 |
|---|---|
| 言語 / フレームワーク | Dart 3 / Flutter |
| 状態管理 | Riverpod 3（`Notifier` / `FutureProvider.family` / `Provider` を使い分け） |
| 永続化 | SharedPreferences |
| 画面部品 | `table_calendar`, `math_expressions`（電卓）, `webview_flutter` |
| 通信 | `http` + `xml`（Google ニュース RSS） |
| 収益化 | `google_mobile_ads`（AdMob） |
| 開発ツール | Dart CLI（アセット一覧の生成、解説の差し替えと検証） |

---

## このプロジェクトで伝えたいこと

### 1. データの「形のばらつき」を入口で吸収した

収録データの選択肢には 3 通りの持ち方（本文入り／記号＋選択肢画像／問題図の中に描かれた 4 択）がありました。`ExamQuestion.fromJson` で常に「ア〜エの 4 件」に正規化し、描画側（`ExamQuestionView`）は分岐なしで扱えるようにしています。画像の振り分け規則もここに閉じ込めました。

### 2. 「収録しているのに引けない」を計測して潰した

収録語と過去問 9,820 問に出てくる用語を突き合わせて被覆状況を計測したところ、問題は語数不足よりも**表記ゆれ**でした（`センサー` と入力すると収録済みの `センサ` が引けない）。`normalizeForSearch`（長音・カタカナ/ひらがな・全角/半角・区切り記号・エー/エイ）を検索語と見出し語の双方に適用し、計測で洗い出した頻出語を追加した結果、**10 問以上に登場する用語の収録率は 32.7% → 46.8%** に改善しました。

### 3. 大容量の JSON（解説込みで約 19MB）を「必要な分だけ・別スレッドで」読む

過去問 JSON は、解説を含む開発版で 3 試験合わせて約 19MB あります（公開版は収集元の解説を除いたため約 9MB）。`FutureProvider.family<List<ExamQuestion>, ExamType>` にして**実際に開いた試験だけ**を読み、パースは `compute()` で別 isolate に逃がして UI スレッドを止めません。

### 4. 気付きにくい不具合をテストで先回りした

Flutter のアセット指定はディレクトリを再帰しないため、約 1,900 の画像ディレクトリを `pubspec.yaml` に列挙する必要があります。登録漏れは**実機でだけ図が表示されない**不具合になるため、生成ツール（`tool/generate_asset_list.dart`）を作り、さらに「参照画像が実在するか」「ディレクトリが登録されているか」までテストで検証しています。

### 5. 第三者の著作物を扱う責任

問題文・図表は IPA が公表した過去問題ですが、元データの**解説文は収集元サイトの著作物**でした。これを自前の文章に置き換える仕組みを作り、差し替えツールが**元の解説と 25 文字以上連続して一致していないか**を検証してから適用するようにしています。ポートフォリオ公開版には差し替え済みの解説だけを同梱しています（→ [設計書 7 章](design.md#7-データの権利処理解説の自前化)）。

### 6. 試験の包含関係を 1 か所で表現した

IP ⊂ FE ⊂ AP の関係を `ExamType.level` / `cumulative` に集約し、単語は試験をまたいで重複しない**差分**で持っています。単語一覧・おすすめ・テスト範囲がすべてこの定義を共有するため、範囲の食い違いが起きません。

---

## 技術的な課題と解決

| 課題 | 解決 |
|---|---|
| 選択肢の持ち方が 3 通りあり、画面側で分岐が増える | モデルの生成時に 4 件へ正規化 |
| JIS 表記と利用者の入力表記が違い検索に引っかからない | 検索語・見出し語の双方を同じ規則で正規化（引けないより引きすぎるほうが実用的と判断） |
| 起動時にすべての過去問を読むと遅い | 試験ごとの遅延読み込み＋別 isolate でのパース |
| 約 1,900 ディレクトリのアセット登録 | 生成ツール＋登録漏れを検出するテスト |
| 同一問題が複数回出題され、解説が食い違う（323 件） | 差し替えツールが本文の一致する問題すべてに反映 |
| `share_plus` 13 系がプラグイン側の Kotlin でコンパイルできない | 11 系に据え置き（理由を `pubspec.yaml` に記録） |

---

## ドキュメント一覧

| ドキュメント | 内容 |
|---|---|
| [要件定義書](requirements.md) | 背景・目的・対象ユーザー・機能要件・非機能要件・簿記単からの変更点 |
| [画面定義書](screen-definitions.md) | 25 画面の一覧と、主要画面の表示項目／操作／業務ルール |
| [設計書](design.md) | システム構成・レイヤー・クラス図・シーケンス図・データ設計・性能・権利処理 |
| [テスト仕様・結果](test-report.md) | データ整合性テストと単体テスト（93 ケース）の内訳 |
| [diagrams/](diagrams/) | PlantUML ソース（`src/`）と SVG（`svg/`） |
| [screenshots/](screenshots/) | 主要画面（デバッグビルドのため広告は Google のテスト広告） |

### 図の一覧

| 図 | PlantUML | SVG |
|---|---|---|
| ユースケース図 | [usecase.puml](diagrams/src/usecase.puml) | [usecase.svg](diagrams/svg/usecase.svg) |
| システム構成図 | [architecture.puml](diagrams/src/architecture.puml) | [architecture.svg](diagrams/svg/architecture.svg) |
| クラス図 | [class.puml](diagrams/src/class.puml) | [class.svg](diagrams/svg/class.svg) |
| シーケンス図① 過去問演習 | [seq-exam-quiz.puml](diagrams/src/seq-exam-quiz.puml) | [seq-exam-quiz.svg](diagrams/svg/seq-exam-quiz.svg) |
| シーケンス図② 単語検索 | [seq-search.puml](diagrams/src/seq-search.puml) | [seq-search.svg](diagrams/svg/seq-search.svg) |
| シーケンス図③ 単語テスト | [seq-word-test.puml](diagrams/src/seq-word-test.puml) | [seq-word-test.svg](diagrams/svg/seq-word-test.svg) |
| 画面遷移図 | [screen-transition.puml](diagrams/src/screen-transition.puml) | [screen-transition.svg](diagrams/svg/screen-transition.svg) |

SVG の再生成：

```bash
cd Doc/diagrams/src
java -jar plantuml.jar -charset UTF-8 -tsvg -o ../svg *.puml
```
