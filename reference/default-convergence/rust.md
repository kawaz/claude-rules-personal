# Rust のデフォルト収束パターン

各 bullet は「危険な使い方」だけが対象。括弧内の文脈では正当。

- **外部入力・I/O 境界・回復可能な失敗**で `unwrap()` / `expect()` (テスト・初期化時 fail-fast・到達不能不変条件の `expect()` は対象外)
- 借用で済むのに脳死で `.clone()`
- **公開 API / ドメイン分岐が必要な層**で `Box<dyn Error>` / `anyhow` により型情報を捨てる (CLI / アプリ最上位 / サンプル / テストは対象外)
- 列挙で表せる状態を `bool` の組合せや `Option` の入れ子で表す
- 単一スレッドで足りるのに先回りで `Arc<Mutex<_>>` 共有
- 本来 enum で表せる状態を `String` で持ち回る (stringly-typed state)
