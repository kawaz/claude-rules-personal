# 裁定・確認待ち一覧 (ユーザ用)

## 運用規約

<details>
<summary>ゼロコンテキストエージェント向け（本セクションは消さない）</summary>

- 裁定/確認待ち項目を 1項目=1ラベル=1セクション で記載
- ラベル形式: XX-Q1（バッチやセッション内で一意な短プレフィクス、Qn単独の使い回し禁止、長期一意性は不要)
- 依頼形式: 「👺XX-Q1 の裁定お願いします」（参照用途ではラベルに👺を付けない。誤陽性がユーザのハイライト/アラームを汚す）
- チャット提示と同一ターンで本ファイルに記録 + path 指定 commit (push はリリース窓に同乗)
- 裁定が下りたら該当セクションを即削除し、内容は正規の記録先 (DR / issue / journal / close_reason) へ反映。本ファイルは常に「現在待ち」だけを持つ
- 参照は[]()で提示（リポ内は相対、リポ外はフルパス）
- 初版質問/依頼は長文で書かない（ユーザが説明を求めらたら本ファイルに説明を追加し、チャットで👺ラベルで再依頼）

</details>

## 裁定待ち

### 👺PM-Q1: plugin は 1 つに同居させるか、配布スコープごとに分けるか

plugin には `for-all` / `for-me` のような配布スコープの区別が無く、install した環境に
全部入る。現行 `for-me/skills` 14 個は personal 専用だが、plugins.json が `for-all` に
ある以上、同居させると emeradaco 環境にも入る。

- a (推奨): `rules-personal` (全環境向け: hooks + for-all 相当) と
  `rules-personal-me` (personal 専用: for-me 相当) の 2 plugin に分け、
  plugins.json の配置で配り分ける
- b: 1 plugin に同居。emeradaco に personal 専用 skill が入るのを許容する
- c: `for-me` 相当は symlink 継続、`for-all` 相当だけ plugin 化

a 推奨の理由: 配布スコープの区別は現に必要 (worker-fleet や jj-workflow を
emeradaco 環境へ配る理由がない)。plugin の慣習に寄せつつ区別を保つには
plugin を分けるのが素直で、install の有無で表現できる。

### 👺PM-Q2: skill/agent の変更ごとに version bump を必須にするか

現在 `check-version-bumped` の trigger は `hooks/` のみで、「rule/skill/docs のみの
変更では bump 不要」と justfile に明記している。skill/agent が plugin 配布物になると
この前提が変わる。

- a (推奨): trigger paths に `skills/` `agents/` を追加する。他 kawaz plugin リポ
  (plugin-reference / gh-monitor / session-analysis) は全て `skills/` を trigger に
  入れている
- b: trigger は `hooks/` のまま。skill 修正は bump せず、必要時にまとめて bump

a 推奨の理由: bump しないと `claude plugin update` が反映しないので、b だと
「push したのに古い skill のまま」が常態化する。

#### 背景説明 (基本省略、詳細を求められたら補充)

symlink 方式は保存した瞬間に反映されるが、plugin 方式は
push → bump → `plugin update` → `/reload-plugins` を経る。この即時性の喪失は
plugin 化の代償として受け入れる前提の判断。

## 確認待ち
