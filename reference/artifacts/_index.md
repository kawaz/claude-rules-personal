# artifacts (生成物をブラウザで見せる・共有する)

- [workspace](workspace.md) — 各リポの `artifacts/` (jj workspace) に生成物を置き、tailnet 内のブラウザで開く仕組み (置き場の作り方、URL との対応、sandbox の意味)。
  生成物をブラウザで見る, artifacts workspace, URL で見せる, tmpspace.net, caddy-app-proxy, file track --include-ignored, index.html, スクリーンショットを見せる
- [share](share.md) — `artifacts/` の生成物を期限付きの公開 URL (Cloudflare R2 + r2.dev) に上げて、tailnet の外の人に共有する (作成 / 更新・期限延長 / 取り下げ)。
  共有したい, 公開 URL, 外の人に見せる, artifacts-share, new, sync, prune, まずいファイルを上げた, 期限を延ばす, 取り下げる, r2.dev, R2, ttl-3d, .artifacts-share.jsonl, キーチェーン, トークンを作り直す, 403, 上げてよい場所でない
