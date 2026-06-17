# ルール群の構造を再編する

## 背景

`for-all/rules/` (24 本) + `for-me/rules/` (15 本) は、思いついた都度
個別ルールとして取り込んできた結果フラットに積み上がっており、
「どのルールがどの場面で効くか」「どのルールとどのルールが同じ責務か」
の地図がない。

4 並列レビュー (codex x2 + nitpick x2, 2026-06-17) で、この
インクリメンタル取り込みに起因する構造的な歪みが繰り返し指摘された:

- design 系 4-5 ファイルが「同じ思考プロセスを別言語で」書いている
- トップレベルの index / 読む順序がない (4 本中複数が指摘)
- `interface-wording.md` の `[[cli-design-preferences]]` が for-all →
  for-me 越境 dead link (新規追加分が既存の境界規約を踏んだ)
- `.draft-` prefix のルールが想定に反して全文注入される
  (prefix で読み飛ばされない)
- `for-me/findings/` が配備ロジック (setup.sh / repos_mapping.json は
  `for-*/rules` と `for-*/skills` のみ対象) の外に紛れ込んでいた
  → `docs/findings/` へ移動済み

これらは個別に潰すより、**ルール群をどう構造化するか**という上位の
設計判断として一度まとめて扱うべき。本 issue はその構造設計に限定し、
個別ルールの中身の修正 (secret/testing/CI/dependency の新設可否、
矛盾ルールの統合など) は別 issue で扱う。

## スコープ

含む (構造):

1. フェーズ別 index の導入
2. 2 層モデルでの責務切り直し
3. 取り込みプロセスの是正 (根本原因への対処)
4. 整合性 lint の導入

含まない (各論・別 issue):

- 個別ルールの新設 (secret-hygiene / testing-policy /
  ci-failure-handling / dependency-policy / cost-guard など)
- ルール間の論理矛盾の解消 (work-principles ×
  top-tier-model-delegation の一本化など)
- 機械的 fix (kawaz-identity 自己参照 / interface-wording 越境リンク /
  `.draft-` 退避) — これらは即着手でよく issue を待たない

## 1. フェーズ別 index の導入

目的は**人間と AI が見通せる地図**であって、コンテキスト節約
(=フェーズ別の出し分け) ではない。後者は rules がフラットに全注入される
以上 index では達成できず、harness 側の機能が要る別問題。

- `for-all/rules/_index.md` を 1 本作る。ファイルは 1 本も移動しない
  (rename は wikilink を壊すため)。
- 開発フェーズごとに該当ルールを wikilink で列挙する。
  粗い区切り: 設計 / 実装 / コミット・プッシュ / CI・リリース /
  レビュー / 運用・インフラ / メタ (ルール・docs 運用そのもの)。
- 多重所属はそのまま複数フェーズに同じリンクを置く
  (push-workflow が commit と CI の両方に出てよい)。
- 各エントリは「リンク + いつ効くか 1 行」まで。判断の中身は本体に
  置き、index に複製しない (複製は二重管理 + no-historical-noise /
  省コンテキスト原則の違反予備軍)。
- for-all 自己完結とし、for-me への越境リンクは張らない
  (リポ単体・for-me を持たない overlay で解決先を欠くため。
  for-me 分が地図に必要になったら for-me 側に別 index を置く)。

## 2. 2 層モデルでの責務切り直し

「設計」ドメインのルールは、**読むフェーズ**で 2 層に分かれる。
層をまたぐ統合はしない (入力と検証を混ぜるため)。同じ層の中だけ
統合を検討する。

上位層 — 判断基準 (着手前に読む / 意思決定の入力):

- `design-priority` (正しさをコストより優先)
- `design-thinking` (ドメインから考える思考の型)

下位層 — 自己点検 (判断後に読む / 出力の検証):

- `default-convergence-guard` (言語別の地雷リスト)
- `self-written-rule-blind-spots` (対極を必ず探す)

判断の指針:

- codex#2 案「全部 design-principles.md に統合」は層をまたぐので不可。
- nitpick 案「全部分けて残す」は現状追認で、取り込みの副産物である
  分散を温存する。
- 中間を取る。同層内 (design-priority × design-thinking、点検系 2 本)
  は、別々に参照している感覚がない以上、統合候補。
- `document-design-rationale` は「記録の作法」で別ドメイン。この 2 層の
  外に置き、巻き込まない (レビューが「design 系 4-5 本」と一括りに
  した分から除外する)。
- フェーズ index 上では、設計フェーズの中をこの 2 層 (着手前 / 点検) で
  入れ子にして見せると、index と 2 層モデルが自然に接続する。

## 3. 取り込みプロセスの是正

本 issue の根本原因。「思いついた都度ルール化する」運用が、
`design-priority` の「正しい設計を選べ」を**ルールファイルの設計には
適用していない**という片面 (= `self-written-rule-blind-spots` の
ケーススタディそのもの)。ファイルを畳むのは対症療法で、ここを直さないと
再発する。

- 今後ルールを追加するときは「既存のどのルールに属するか / 新設が
  必要か」を必ず判断する、を `rule-writing-guidelines.md` または
  `self-written-rule-blind-spots.md` に 1 段追記する。
- 追加時に該当フェーズの index エントリも同時に更新する
  (index と本体の整合を取り込み手順に組み込む)。

## 4. 整合性 lint の導入

今回の越境リンク事故も `.draft-` 全注入も `/Users/kawaz` 残存も、
機械的に検出できる類。個別の 20 指摘を人力で潰すより上位の打ち手。
setup.sh か CI に最小構成で 1 本入れる。

- wikilink 解決チェック (`[[name]]` の解決先が配備後に存在するか)。
  for-all → for-me 越境のような構造上の dead link を検出。
- ローカル絶対パス残存チェック (`rg '/Users/kawaz'`)。
  `sanitize-local-paths.md` の逆方向 (削除・rename 時の取り残し)。
- rules 配下に置くべきでないもの (長大 draft / 配備対象外ディレクトリ)
  の検出は、必要なら段階的に追加。

## 先行資料

- `docs/findings/2026-05-28-rules-narrow-scope-audit.md`
  (移動済み。ルール scope の監査で本 issue と地続き。再編設計時に参照)
- 4 並列レビュー原本 (2026-06-17)

## 進め方

1 (index) と 4 (lint) はファイルを動かさず追加するだけで、既存の link を
壊さない。先に着手してよい。2 (2 層切り直し) は wikilink を触るので、
4 の lint を入れてから着手すると事故を検出できる。3 (プロセス是正) は
1-2 を実際にやってみて確定した手順を文章化するのが順当。
