# Push ワークフロー

## push は `just push` を使う

`jj git push` や `git push` を直接実行しない。必ず `just push` を使う。

理由: `just push` は check + test を通してから push する。直接 push すると品質チェックをスキップしてしまう。

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
