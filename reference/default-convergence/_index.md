# 言語別のデフォルト収束パターン

`default-convergence-guard` rule の言語別の実名パターン。その言語のコードを書く前に該当する 1 ファイルを読み、書く瞬間に「要件がこれを要求したか」を自問する。各 bullet は「危険な使い方」だけが対象で、括弧内の対象外の文脈では正当。

- [rust](rust.md) — Rust で手癖に流れやすい書き方 (`unwrap`、`.clone()`、`anyhow`、`Arc<Mutex<_>>`、stringly-typed state)。
  Rust を書く, unwrap, expect, clone, Box<dyn Error>, anyhow, Arc<Mutex>, bool の組合せ, Option の入れ子, String で状態
- [go](go.md) — Go で手癖に流れやすい書き方 (`return err` の素通し、`any`、`panic` / `recover`、goroutine leak、`init()`)。
  Go を書く, return err, interface{}, any, panic, recover, context.TODO, context.Background, goroutine leak, init(), global state
- [typescript](typescript.md) — TypeScript で手癖に流れやすい書き方 (握りつぶし、`?.` の乱用、`useEffect` / `useMemo` の儀式化、boolean prop の増殖)。
  TypeScript を書く, try/catch, console.error, Promise rejection, ?., useEffect, useMemo, useCallback, boolean prop, discriminated union
