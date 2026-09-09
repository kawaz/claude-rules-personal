# docs 執筆の参照知識

kawaz リポの `docs/` 構造標準と、何をどこに書き残すかの判断。入口は「どこに置くか」「いつ書くか」「裁定待ちをどう管理するか」の 3 つ。テンプレ本体は `templates/` 配下にあり、索引は docs-layout に含まれる。

- [docs-layout](docs-layout.md) — 命名規則・ディレクトリ構造・各カテゴリの運用・テンプレ一覧・既存リポの移行・参考実装。
  発火語: docs 構造, どこに置く, DESIGN.md, STRUCTURE.md, decisions, DR-NNNN, findings, journal, runbooks, docs/issue, テンプレ
- [translation-pairs](translation-pairs.md) — 日本語原本 + 英訳ペアの必須対象、push 時ガード、相互リンクの書式。
  発火語: 翻訳ペア, README-ja, DESIGN-ja, 英訳, check-outdated-translations, bump-semver vcs outdated
- [knowledge-timing](knowledge-timing.md) — issue 解決時の記録先の表、DR / runbook / findings / journal を立てるタイミング、並列作業時の journal 習慣。
  発火語: いつ DR を立てる, issue を close, 記録を残す, journal を書く, runbook 化, findings にする
- [questions-registry](questions-registry.md) — `docs/QUESTIONS.md` の運用 (裁定待ち Q / 確認待ち C)、AskUserQuestion 禁止、統括固有の観点。
  発火語: QUESTIONS.md, 裁定待ち, 確認待ち, AskUserQuestion, 今何待ち
