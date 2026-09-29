# Claude Mods の `$` (engine interface)

mod が engine と外界に触れる唯一の口。呼び方は `$.noun.method(...)` に限られ、`claude plugin validate` が列挙した呼び出し以外は実行時に拒まれる。Claude Code 2.1.283 の型定義 (`CoreEngineInterface`) と 2.1.284 の実機観測による。

## noun とメソッド

| noun | メソッド | 要点 |
|---|---|---|
| `plugin` | `name`, `root` | `root` は plugin のディレクトリ (同梱ファイルは `${$.plugin.root}/...`) |
| `ui` | `log`, `ask`, `toast`, `status`, `notice`, `open` / `close` / `panes`, `resolve`, `invalidate`, `blit`, `scroll`, `focus`, `copy` | `status` は plugin ごと 1 行 (prompt の下、`undefined` で消す)。`log(text, { to: 'debug' })` は debug log へ (session id 等は `[REDACTED]` に置換される)。`ask` は AskUserQuestion ダイアログを出す |
| `model` | `complete`, `fork`, `classify` | session の client で 1 回の completion |
| `audio` | `play`, `speak` | |
| `mcp` | `call` | 接続中 MCP server の tool を呼ぶ |
| `session` | `messages`, `cwd`, `root`, `model`, `turns`, `id`, `repo`, `surfaces`, `surface`, `usage`, `version`, `compact`, `authorize`, `send` | `id` は transcript ファイル名の session id。`send` は下記 |
| `turn` | `abort` | |
| `prompt` | `submit`, `read`, `fill`, `suggest` | 詳細は reference の `claude-mods/prompt-injection` |
| `tool` | `list`, `call`, `check`, `register` | `call` は permission 判定とダイアログを通る。`check` は判定だけを問い合わせる (ダイアログも PreToolUse も走らない)。`register` で model が呼べる tool (`mcp__<plugin>__<name>`) を足す |
| `command` | `list`, `run`, `register` | slash command を足す (`/name`) |
| `config` | `list`, `set` | 専用ダイアログでしか変えられない行は `{ deny }` |
| `agent` | `spawn`, `list`, `register` | subagent 定義を足す・起こす |
| `fs` | `read`, `write`, `list`, `exists`, `stat`, `ancestors` | 相対パスは session の cwd 基準、UTF-8 |
| `store` | `get`, `set`, `delete`, `keys` | plugin 専用の KV。session と reload を跨ぐ。値は JSON |
| `state` | `get`, `set` | session の値を host が持つ (reload を跨ぐ)。描画中の `get` は購読になり、`set` で再描画される。読むのは誰でも、書くのは持ち主だけ |
| `clock` | `now`, `sleep`, `after`, `every` | `after` / `every` は `cancel()` を返す。module の reload で落ちる |
| `http` | `fetch` | host 経由 |
| `process` | `run`, `spawn` | host で user 権限のコマンドを argv で (shell なし)。CLI の session のみ |
| `settings` | `read` | settings のマージ結果か 1 source 分。読み取り専用。`~/.claude.json` と OAuth は読まない |
| `env` | `get`, `set` | プロセス環境。`set` は以後起動する Bash / MCP / `process.run` の子に継承される |

plugin は `engine.create` で独自の noun を足せる (built-in の `telemetry` が `$.telemetry` を足す)。

## 制限

- `fs.read` / `fs.write` は 4 MiB を超えると reject。追記 API は無いので、log を `read` + `write` で伸ばす作りは 4 MiB で止まる (ファイルを分ける)。network 越しのパス表記は触らずに reject
- `store` は全体で JSON 4 MiB まで。関数・循環参照は reject、`Date` は ISO 文字列、`Map` / `Set` は `{}` になる
- `env.get` / `env.set` の変数名、`state.get` / `state.set` の `plugin` / `key` は文字列リテラル必須 (validate が列挙し、列挙外は拒否)
- `http.fetch` は http / https だけ (WebSocket・SSE・生 socket は無い)。応答は body を全部読んでから `{ status, ok, headers, text }` で返り、stream しない。長期接続を持つ・再接続する手段は `$` に無く、SSE の endpoint を叩けば「サーバが閉じるまで resolve しない fetch」になるだけ。長期接続が要るものは全部 `process.spawn` の子 (stdout を stream で読める) に置き、再接続も子の終了を見て spawn し直す module 側のループで行う。body は文字列。`socketPath` で Unix socket 越しの HTTP を話せる (絶対パス、約 100 byte まで)。timeout の記述は型定義に無い
- `process.run(argv, { cwd, env, stdin, timeoutMs })` は終了後に出力をまとめて返す。timeout は既定 30 秒、最大 10 分。背景に残って書き続ける子がいると timeout まで返らない。git は repo hooks 無効で走る。signal で終わった子は `exitCode: 1`
- `process.spawn({ argv, cwd, env, input })` は出力を `{ stream, text }` の断片で stream し、最後に `{ code, signal }`。ループを抜ける・`next.signal` の abort・module の unload で子が kill される。`input` は 1 回書いて閉じるだけで、書き続ける stdin は無い
- 予算: hook 自身のコードの時間が 1 回 10 秒まで。`$` 呼び出しと `next(e)` の待ちは数えない (`$.clock.sleep` は数える)。実測では `$.process.run` で 20 秒待っても、during 配置で `next(e)` を 20 秒保留しても超過しなかった。module 内の素の Promise (自前 Button の押下待ち等) を待つ時間は数えられると読める (定義文からの推測、未検証)
- `$.clock.every` 等の callback から呼んだ `$` は、同じ plugin の `*` hook には現れない

## 外部プロセスとつなぐ形

| 形 | 使う口 | 向き |
|---|---|---|
| CLI を叩く | `$.process.run(['tool', 'sub', ...])` | 往復 1 回 |
| session 寿命の子を持つ | `session.start` から `$.process.spawn` し、`for await` で出力を読み続ける (hook は待たずに返す) | 外 → mod の stream |
| HTTP server に訊く | `$.http.fetch(url, { socketPath })` | 往復 1 回 |
| ファイルを poll | `session.start` から `$.clock.every(ms, () => $.fs.read(...))` | 外 → mod |
| 別の Claude Code session へ送る | `$.session.send({ to, text })` | mod → 別 session |

`$.process.spawn` の子の例:

```ts
on('session.start', async ($, e, next) => {
  const started = await next(e)
  void (async () => {
    const child = $.process.spawn({ argv: ['some-watcher', e.cwd] })
    for await (const { text } of child) $.ui.log(text, { to: 'debug' })
  })()
  return started
})
```

## `$.session.send`

- `to` は名前・agent id・受信した `from` アドレス、または `{ sessionId }` / `{ agentId }`。model の SendMessage と同じ経路で送り、`session.send` event を通る
- 結果は `{ isDelivered, reason? }`。`isDelivered` は相手の queue に入ったことで、読まれたことではない
- 届く範囲は同じ `CLAUDE_CONFIG_DIR` の session だけ。別 config home の session には `$.session.send` も model の SendMessage も届かない (`no live session on this machine has id ...` / `No agent named '...' is reachable.`)
- 受け側では `session.receive` の `origin` が `{ kind: 'peer', plugin: '<送り手の plugin>' }` になる

## 2026-09-29 時点の未確認

- `http.fetch` の `socketPath` の説明 "one per session, in a private directory" の意味 (任意の UDS に繋げるのか)
- `$.store` の保存先 (`CLAUDE_CONFIG_DIR` 配下か固定パスか)
