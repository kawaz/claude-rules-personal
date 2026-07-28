---
name: itumono-review-claude
description: Claude CLIを使ったコードレビュー（外部ツールからの利用を想定）
---

引数: レビュー対象やレビュー観点（省略可）

claude 自身がこのコマンドを使うことは想定していない（サブエージェントで済む）。
codex や gemini など外部 AI ツールが claude のレビュー能力を利用する際の手順書。

## 実行

```bash
claude -p --allowedTools "Read,Glob,Grep" "レビュー指示 $ARGUMENTS"
```

結果を報告する。出力に VERDICT が含まれない場合は `VERDICT: PASS` または `VERDICT: ISSUES_FOUND` を付与する。
