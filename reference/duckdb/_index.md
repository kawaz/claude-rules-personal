# DuckDB

- [data-lake](data-lake.md) — 定期的な計測・ログを溜めて推移を集計する置き方 (ライブの層 + 日次・月次の zstd Parquet、DuckDB で読む)。
  データを溜める, 時系列, 計測の記録, ログを貯める, Parquet, zstd, 日次, 月次, まとめ直し, compaction, 間引き, read_parquet, union_by_name, SQLite が大きい, データレイク
- [wasm-dashboard](wasm-dashboard.md) — 溜めた Parquet をブラウザの DuckDB-WASM で集計する画面を artifacts に置く形 (data の symlink、一覧の取り方、CDN の版を揃える理由)。
  ダッシュボード, DuckDB-WASM, duckdb-wasm, ブラウザで集計, artifacts に置く, data の symlink, jsDelivr, getJsDelivrBundles, Blob URL の worker, LOAD parquet, read_parquet is not in the catalog, glob できない, キャッシュの共有, 版を揃える
