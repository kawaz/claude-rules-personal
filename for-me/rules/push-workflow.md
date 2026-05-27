# Push ワークフロー

## push は `pkf run push` を使う

`jj git push` や `git push` を直接実行しない。必ず `pkf run push` を使う。

理由: `pkf run push` は deps で check + test + 翻訳ペア検証 + version bump 漏れ検出などの品質ゲートを通してから push する。直接 push するとこれらをスキップしてしまう。

直接 `git push` / `jj git push` を試みても push-guard プラグインの hook がブロックし、`pkf run push` に誘導する。

Taskfile.pkl 未整備のリポ（マイグレーション途中）は、そのリポの push 用 task に従う。

## push 後は CI を watch する

push したら必ず CI の結果を確認する:

```bash
sleep 3
run_id=$(gh run list --repo OWNER/REPO --limit 1 --json databaseId -q '.[0].databaseId')
gh run watch "$run_id" --repo OWNER/REPO
```

- バックグラウンドで watch して良い
- 失敗したらその場で対処
- CI が起動していない場合は理由を調査（workflow ファイルのエラー等）
