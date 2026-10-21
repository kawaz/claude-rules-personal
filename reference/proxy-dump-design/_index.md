# proxy-dump-design の索引

proxy / gateway / ロードバランサに付ける「通信の一時ダンプ」(時限と容量の上限つきで request / response をファイルに残し、一定時間後に消える口) の設計パターン。新しく設計する時は 4 本とも読む。実装・レビューで一部だけ要る時は該当の 1 本を読む。

- [model](model.md) — 目的、残すもの (request / 生 response / 試行)、一致条件、状態と停止理由、適用例。
  通信をダンプしたい, request を残す, upstream が何を返したか, 試行, attempt, adopted
- [capacity](capacity.md) — 設定キー、容量と並列度 (申告値と実使用量)、判定の位置、クリーンアップ、保存先の権限。
  max_bytes, fs 空き容量, 上限で止める, 48h で消す, truncated, 700 / 600
- [files](files.md) — ディレクトリ構成、メタ json と body の分離、圧縮、rewrites、index.jsonl、flush。
  index.jsonl, response.body, content-encoding, decoded, rewrites, seq, duration_ms
- [api](api.md) — start / end / list / prune、follow モード (embed / persist)、labels。
  dump start, follow, SSE で流す, lagged, labels, prune
