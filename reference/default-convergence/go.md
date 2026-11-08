# Go のデフォルト収束パターン

各 bullet は「危険な使い方」だけが対象。括弧内の文脈では正当。

- **呼び出し側が操作対象や文脈を失う境界**で `return err` を素通し (sentinel error / 既に十分な文脈を持つ下位エラー / 抽象境界で実装詳細を漏らしたくない場合は対象外)
- `interface{}` / `any` で型を曖昧化、または広すぎる interface を切る
- 復帰不能でないのに `panic`、または `recover` で握りつぶす
- 意味の薄い `data` / `info` / `obj` 命名
- 由来不明な `context.TODO()` / `context.Background()` を関数内で生成
- goroutine / channel の leak (cancel・close 経路を設計せず spawn)
- 巨大 `init()` / global mutable state で初期化順序に依存
