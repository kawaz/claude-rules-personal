---
name: itumono-full-review
description: マルチペルソナ並列コードレビュー
---

引数: レビュー対象やレビュー観点（省略時は未コミットのdiff）

# マルチペルソナ並列コードレビュー

以下を**全て並列に**起動してレビューし、結果を集約する。
**残置 backlog ファイルを必ず読み込む**ことで複数ラウンド間で指摘が漏れないようにする。

## 残置 backlog (必ず使う)

レビューは複数ラウンド回ることが多い。**過去ラウンドの指摘 (Critical / Warning /
Info) は backlog ファイルに集約**し、次ラウンドの先頭で読み込んで dedup 対象に含める。

backlog file path 規約: `/tmp/itumono-backlog-{repo_basename}.md`
(例: `/tmp/itumono-backlog-hyoui.md`)

### ラウンド開始時

1. backlog file を Read。存在しなければ新規。
2. backlog 内の未対応 / Warning 残置を「今回 review で改めて評価する候補」として
   集約候補 list に追加。
3. 各ペルソナ / 外部 AI を起動するときは、prompt に backlog の内容も渡して
   「過去ラウンドの未対応指摘も再評価対象」と明示。

### ラウンド終了時

1. 今回のラウンドで上がった指摘を backlog file に追記 (= 階層 markdown で
   ラウンド N の項目として並べる)。
2. 既に対応済の指摘は backlog から消す or `[done]` マーク。
3. backlog file は commit しない (= `/tmp` 配下の作業ファイル)。

これで「ラウンド 1 で warning にした項目をラウンド 3 で漏らす」事故を防ぐ。

## レビュアー

- **ペルソナ5つ**: レビュー対象に適した専門家4つ + 非専門家1つを Task tool で並列起動。コード修正は禁止、それ以外は自由。ラウンドごとにペルソナを変えてよい。前 round の残置 backlog があれば prompt に含めて再評価対象にする。
- **ペルソナの model 指定 (必須)**: Task tool 起動時に `model` を必ず明示する (未指定はメインのモデルを継承し、メインが Fable だと全ペルソナが最高コストで走る)。使い分け:
  - 初期ラウンド / 数を撒くスクリーニング → `opus`
  - 最終ラウンド / リリース判定 / 本質指摘が欲しいラウンド → `fable` (メインが Fable の場合)。本気の品質判定を劣る tier に委譲しない。fable ペルソナは観点分割で並列するより 1 本に全方位を見せるほうが効く (詳細: top-tier-model-delegation ルール)
- **外部AIツール**: `/itumono-review-codex`、`/itumono-review-gemini` と同等の手順で並列実行。codex には「瑣末な点へのクソリプはしないで。致命的な点だけ指摘して」の指示を必ず含める (= ただし `codex review --base SHA` 経由ではプロンプト併用不可なので default prompt + post-process で VERDICT 付与する経路を選ぶ)。モデルは `-c 'model="gpt-5.3-codex"'` を指定する (`codex review` の Code Review 機能は gpt-5.3-codex 専用。`-m` は不可)。外部ツールは 10〜15 分かかることもあるのでタイムアウトは長めに設定する。他のレビュアーと大きな時間差がある場合はバックグラウンドで待ちつつ、揃った分で先に進めてよい。遅れた結果は返ってきた時点で追加反映する。
- **gemini rate limit 対策**: `gemini-2.5-pro` が rate-limit (= "RATE_LIMIT_EXCEEDED") で死んだら、即座に `gemini -m gemini-2.5-flash -p ...` に fallback。flash は別 quota で通ることが多い。

### 外部 AI の典型コマンド

```bash
# codex: 特定 base からの diff scope を絞りたい (custom prompt 不可、default review prompt)
codex review -c 'model="gpt-5.3-codex"' --base <BASE_SHA>

# codex: 未コミット変更を custom prompt で評価
codex review -c 'model="gpt-5.3-codex"' "未コミットの変更をレビューして。瑣末な点へのクソリプはしないで。致命的な点だけ指摘して。"

# gemini: diff を直接 stdin で渡す (= jj/git の出力をパイプ)
jj diff -r 'BASE..HEAD' --git | NODE_OPTIONS="--no-warnings=DEP0040" gemini -y -p "致命的な点だけ指摘して、最後に VERDICT: PASS or VERDICT: ISSUES_FOUND を出力"

# gemini pro が rate limit なら flash に fallback
jj diff -r 'BASE..HEAD' --git | NODE_OPTIONS="--no-warnings=DEP0040" gemini -m gemini-2.5-flash -y -p "..."
```

各レビュアーは最後に `VERDICT: PASS` または `VERDICT: ISSUES_FOUND` を出力する。

## レビュー観点

設計・ロジック・セキュリティ等の意味的な問題に集中する。
コードスタイルや重複排除等の整理は `/simplify` の責務であり、レビューでは指摘しない。

## 結果集約

- 過去ラウンド backlog の未対応指摘も dedup 対象に含める
- 同一箇所の類似指摘をマージ（指摘元を併記）
- 複数レビュアーが同じ箇所を指摘 → 高確信度
- severity 順（critical > warning > info）でソートしてレポート出力
- レポート出力後、**backlog file に今回ラウンドの結果を追記**する (上記「残置 backlog」参照)
