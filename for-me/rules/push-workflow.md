# Push ワークフロー

`jj git push` / `git push` を直接実行しない。リポ側の push task (justfile 等) を使う。
直接 push しても push-guard プラグインの hook がブロックし、正規経路に誘導する。

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
