# デフォルト収束の警戒

LLM は要件に関係なく「よく見る無難な実装」へ吸い寄せられる。
正しい設計を選ぶ (design-priority) の対極として、安易に流れ着く
具体パターンを名指しで自覚し、選んだのか流れたのかを区別する。

**前提**: conventional・標準 idiom・チーム規約に沿うことは第一候補。
本ルールが避けたいのは「無自覚に」デフォルトへ流れること。下記パターンも
正当な使用文脈があり、各 bullet の「危険な使い方」だけが対象。

## 吸い寄せられやすい実名パターン

### 言語共通

- ドメイン語を持たない `utils` / `helpers` / `common` / `Manager` /
  `Helper` / `Service` に関数を寄せ集める (DDD 等で domain 語と
  組み合わさる `OrderService` 等は対象外)
- 既存の素直な関数で足りるのに抽象基底・trait・interface を先に立てる
- 意味不明な literal や環境差分を持つ設定値をその場にハードコード
  (仕様由来で局所的な小定数は対象外)
- 「将来必要かも」で使われないオプション引数・フラグを足す

### Rust

- **外部入力・I/O 境界・回復可能な失敗**で `unwrap()` / `expect()`
  (テスト・初期化時 fail-fast・到達不能不変条件の `expect()` は対象外)
- 借用で済むのに脳死で `.clone()`
- **公開 API / ドメイン分岐が必要な層**で `Box<dyn Error>` / `anyhow`
  により型情報を捨てる (CLI / アプリ最上位 / サンプル / テストは対象外)
- 列挙で表せる状態を `bool` の組合せや `Option` の入れ子で表す
- 単一スレッドで足りるのに先回りで `Arc<Mutex<_>>` 共有
- 本来 enum で表せる状態を `String` で持ち回る (stringly-typed state)

### Go

- **呼び出し側が操作対象や文脈を失う境界**で `return err` を素通し
  (sentinel error / 既に十分な文脈を持つ下位エラー / 抽象境界で実装詳細を
  漏らしたくない場合は対象外)
- `interface{}` / `any` で型を曖昧化、または広すぎる interface を切る
- 復帰不能でないのに `panic`、または `recover` で握りつぶす
- 意味の薄い `data` / `info` / `obj` 命名
- 由来不明な `context.TODO()` / `context.Background()` を関数内で生成
- goroutine / channel の leak (cancel・close 経路を設計せず spawn)
- 巨大 `init()` / global mutable state で初期化順序に依存

### TypeScript

- `try/catch` で握りつぶし `console.error` だけ (原因も復帰も示さない)、
  Promise rejection の握りつぶし
- `any` / 検証なしの `as Foo` / `Record<string, any>` で型エラーを黙らせる
  (`as const` / DOM 境界 / 検証済み narrowing 後の assertion は対象外)
- **本来 invariant な値**への non-null assertion `!` / 設計不備を隠す
  `?.` の乱用 (optional なドメイン値への `?.` は対象外)
- 外部 JSON / API レスポンスをランタイム検証なしで cast
- 副作用を何でも `useEffect` に詰める、`useMemo` / `useCallback` の儀式化
- boolean prop が増殖して状態の組合せが爆発 (= discriminated union に
  すべき場面)

## How to apply

- 上記に該当する実装を書く瞬間に「要件がこれを要求したか」を自問
- 要件由来でなく手癖ならやめる。**ベストプラクティスから外れる方を
  選ぶ場合のみ** design-rationale を残す (conventional な idiom 採用は
  rationale 不要)
- 「要件が違っても同じ形になる実装」は要件を反映できていない兆候
- conventional は第一候補。避けるのは*無自覚な*デフォルト依存

## Why

要件を読まずデフォルトに流れた実装は、たまたま動いても要件とずれる。
名指しの地雷リストが自覚の引き金になる。

## 関連

- [[design-priority]] — 正しい設計を積極的に選ぶ側
- [[design-thinking]] — 早すぎる抽象化・ワークアラウンド禁止
- [[document-design-rationale]] — ベストプラクティスから外れる選択の記録
- [[self-written-rule-blind-spots]] — 片面ルールの警戒 (conventional 第一候補の対極視点)
