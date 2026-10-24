# Claude Mods の `$` (engine interface)

mod が engine と外界に触れる唯一の口。呼び方は `$.noun.method(...)` に限られ、`claude plugin validate` が列挙した呼び出し以外は実行時に拒まれる。Claude Code 2.1.299 の型定義 (`CoreEngineInterface`) と公式リポの built-in mod、実機観測による。どの呼び出しも同名の op event になり、上の plugin の hook が書き換え・拒否・代答できる (reference の `claude-mods/capabilities`)。

## noun とメソッド

| noun | メソッド | 要点 |
|---|---|---|
| `plugin` | `name`, `root` | `root` は plugin のディレクトリ (同梱ファイルは `${$.plugin.root}/...`) |
| `ui` | `log`, `toast`, `status`, `notify`, `notice`, `ask`, `open` / `close` / `panes`, `resolve`, `invalidate`, `blit`, `scroll`, `focus`, `copy`, `selection` | 下の「ui」節 |
| `model` | `complete`, `fork`, `classify` | session の client と credential で 1 回の completion。下の「model」節 |
| `audio` | `play`, `speak` | `play({ asset })` は plugin 同梱のファイル (macOS は `afplay`、他 OS の端末は鳴らない)、`{ url }` / `{ base64, mime }` も可。clip は queue されず重なる。`speak` は OS の合成音声 (macOS は `say`)、発話同士は queue される |
| `mcp` | `call`, `connect` | `call(server, tool, args)` は接続中 MCP server の tool を engine の接続で呼ぶ (permission prompt 無し。上の hook が許可の代わり)。`connect(server)` は自 plugin の manifest が挙げた server を接続し `{ isConnected: true, server }` / `{ isConnected: false, reason, message }` (`unlisted` / `unapproved` / `disabled` / `policy` / `auth` / `failed`)。manifest に挙げた server は session 開始時に接続済みなので、tool を出し惜しむなら `tool.check` で拒む |
| `session` | `messages`, `cwd`, `root`, `model`, `turns`, `id`, `repo`, `surfaces`, `usage`, `version`, `compact`, `send`, `append`, `authorize`, `identity` | 下の「session」節。`surface` は deprecated (`surfaces()[0]`) |
| `turn` | `abort` | `abort({ turnId })` は main loop の実行中の turn を中断マーカー無しで止める (`turn.start` で受け取った id)。別の turn の id は reject |
| `prompt` | `submit`, `read`, `media`, `fill`, `suggest`, `compose` | `submit` は自前の turn (session が idle になってから)。`compose(facts?)` は system prompt の節を組んで返す (誰にも送らない)。`media` は下の「managed で install された mod だけの口」。`read` / `fill` / `suggest` は reference の `claude-mods/prompt-injection` |
| `tool` | `list`, `call`, `check`, `register` | `call` は permission 判定とダイアログを通る。`check` は判定だけを問い合わせる (ダイアログも PreToolUse も classifier も走らない)。`register({ name, description, inputSchema?, isDeferred? })` で model が呼べる tool (`mcp__<plugin>__<name>`) を次の prompt から足す。`isDeferred: false` で schema を最初から prompt の tool 一覧に載せ、`true` / 省略は ToolSearch の後ろ。`session.start` で session が bind されるまで reject。応答は同名の `tool.call` hook で返す (下の「tool」節) |
| `command` | `list`, `run`, `register` | `register({ name, description, argumentHint?, immediate? })` で `/name` を足す (built-in の名前は拒否)。`immediate: true` は turn の途中でも即実行。応答は `command.run` hook で返す。`run` は session が idle になってから走る |
| `config` | `list`, `set` | `/config` の行 (built-in と各 plugin の `userConfig`)。trusted source が持つ行・専用ダイアログでしか変えられない行は `{ deny }` |
| `telemetry` | `log`, `mark` | first-party analytics の行と、operator が設定した collector への record。first-party の行を queue するのは built-in `telemetry` で、built-in と engine 以外の呼び手は拒まれる。collector への record も engine が上げたものだけが collector に届く。hook はどの plugin もできる |
| `agent` | `spawn`, `list`, `register` | `spawn({ prompt, description?, subagentType?, model?, name?, cwd? })` は background で起こし `{ model, agentId }` を返す (答えはその agent の `turn.complete`)。`list()` は subagent と teammate (`id` / `teammateId?` / `type` / `status` / `parentId?` / `spawnedBy?` / `name?`)。`agent.spawn` を通らない loop (fork した skill) は含み、workflow の agent は含まない。teammate は終わる時かその数秒後に、subagent はそれより後に一覧から落ちる (実測: 終わった subagent は 1 秒後も `status: 'completed'` で残っていた)。`id` は `turn.*` / `tool.call` の `e.agentId` と、Agent tool の結果の `agentId` と同じ値 (実測)。`register(spec)` は `<plugin>:<name>` の agent 型を次の turn から足す (agent ファイルの全欄: `tools` / `disallowedTools` / `model` / `effort` / `permissionMode` / `mcpServers` / `hooks` / `maxTurns` / `skills` / `initialPrompt` / `memory` / `background` / `omitClaudeMd` / `isolation` ...) |
| `fs` | `read`, `write`, `list`, `exists`, `stat`, `ancestors` | 相対パスは session の cwd 基準、UTF-8。`read(path, { as: 'bytes' })` は `{ base64 }`。`list` は `{ name, kind, size, mtimeMs, isLink }` (symlink は `other` + `isLink`)。`stat(path, { resolve: true })` は `realPath` も返す (guard は `realPath` を root 配下の allow-list で判定する。型定義の例)。`ancestors({ names, of?, below? })` は CLAUDE.md と同じ読み方で祖先ディレクトリの指定ファイルを root から順に返す (`{ dir, name, content, parts }`、`@include` 込み) |
| `store` | `get`, `set`, `delete`, `keys` | plugin 専用の KV。session と reload を跨ぐ。値は JSON |
| `state` | `get`, `set` | session の値を host が持つ (reload を跨ぐ。寿命は reference の `claude-mods/practices`)。key は `types/index.d.ts` の `PluginState` に宣言する (無いと読み込まれない。reference の `claude-mods/overview`)。`get` は `{ value, version }`、`set(ref, value, { ifVersion })` は `{ isSet, version }`。描画中の `get` は購読になり、`set` で再描画される。読むのは誰でも、書くのは持ち主だけ。描画中の `set` は拒否 (`onPress` 等から書く) |
| `clock` | `now`, `sleep`, `after`, `every` | `after` / `every` は `cancel()` を返す。module の reload で落ちる。`sleep(ms, { signal: next.signal })` で dispatch と一緒に終わらせる |
| `http` | `fetch` | host 経由。`init` は `{ method, headers, body, auth, socketPath }` |
| `process` | `run`, `spawn` | host で user 権限のコマンドを argv で (shell なし)。CLI の session のみ |
| `settings` | `read` | settings のマージ結果か 1 source 分 (`{ source: 'user' / 'project' / 'local' / 'flag' / 'policy' }`)。読み取り専用。`env` や helper コマンドも含めて全 key がそのまま渡る。`~/.claude.json` と OAuth は読まない |
| `env` | `get`, `set` | プロセス環境。`set` は以後起動する Bash / MCP / `process.run` の子に継承される。`undefined` で unset |

plugin は `engine.create` で独自の noun を足せる (`return { ...beneath, <noun>: ... }`。他 plugin の noun を置き換えると読み込み失敗)。型の契約の書き方は reference の `claude-mods/develop`。

### ui

- `log(text, { to })`: transcript に dim の 1 行 (model には送らない)。`{ to: 'debug' }` は debug log だけ (実測: session id 等は `[REDACTED]` に置換される)。端末は先頭 2000 字、remote surface と debug log は 10000 字まで描く。`-p` / SDK host には `ui_log` で届く
- `toast(text, { timeoutMs })`: transcript 右上の plugin toast の積み (既定 4000ms)。組織の mod の toast が先に出る
- `status(text)`: plugin ごと 1 行を prompt の下に固定 (`undefined` で消す)
- `notify(text, { title })`: 人の `preferredNotifChannel` で OS 通知を出す。先に人の `Notification` hook が `plugin_notification` として走る。結果は `{ isSent: true, channel }` (`iterm2` / `iterm2_with_bell` / `kitty` / `ghostty` / `terminal_bell`) か `{ isSent: false, reason }` (`disabled` / `no-channel` / `no-surface` / `refused`)。頻度の制限は無い
- `notice(tool_use_id, text)`: その tool call の開いているダイアログの下に 1 行 (call の解決で消える)
- `ask(question, options)`: AskUserQuestion ダイアログで人に訊く (reference の `claude-mods/dialogs`)
- `open({ id, title?, focus?, closeOnEscape?, holdToasts?, rows?, columns? })` / `close({ id })` / `panes()`: plugin が描く pane (`ui.render` の `Pane`)。人の操作 (command・prompt・press) から開いたものは幅を問わず置かれ、そうでないものは 144 桁 (一度人が開いたことのある id は 110 桁) から。置かれない間は `{ isPlaced: false, reason }` で、描かれずに待つ。`-p` / VS Code のように描く surface が無い所でも `isPlaced: false`
- `selection()`: fullscreen で人が最後に選択した文字列と、それが 1 行に収まればその transcript 行の `requestId`。無ければ `undefined` (fullscreen off・`-p` 含む)
- `copy({ text, surface? })`: surface の clipboard に書く。`{ isCopied }` / `{ isCopied: false, reason }` (`no-surface` / `no-clipboard` / `refused`)
- `resolve(e)`: `ui.render` の `e` の surface の要素表 (`const { Box, Text } = $.ui.resolve(e)`)。dispatch ではなく読み取り。端末の要素は `Box` / `Text` / `Button` / `Input` / `Select` / `Link` / `Code` / `Markdown` / `Client` / `Raster` / `Image`。`Text` は `size` / `weight` / `mono` / `tabular` を持ち (`bold` は deprecated で `weight`)、`Box` の余白は数値か `xs`〜`xl`
- `invalidate(event)`: cache された答えを捨てて問い直す。`ui.render` は再描画 (1 秒 10 回まで。端末で表示中の pane・展開した band・prompt hint は 30 回)、他は `prompt.section` / `prompt.context` / `prompt.attachment` / `tool.describe` / `command.describe` / `config.describe`。変わった答えは次の turn に送られ prompt cache を書き直す。process の終了で消えるので、resume 後に欲しければ `session.start` で再度呼ぶ
- `blit` / `scroll` / `focus`: `Raster` / `Image` の再描画なしの差し替え、site のスクロール、focus ring の移動

### model

- `complete({ model, prompt, system?, maxTokens?, effort?, timeoutMs? }, { signal? })`: tool も履歴も無い 1 回の completion。`prompt` / `system` は文字列か `{ text, cache?: true }` の block 列で、`cache: true` の block までを prompt cache に載せる。`maxTokens` 既定 1024 (上限は model の出力上限か 64000 の小さい方)。結果は `{ isAnswered: true, text, usage }` か `{ isAnswered: false, reason }` (`api-error` + `status` / `error`、`empty-reply`、`aborted`)。provider 側の失敗では reject しない
- `fork({ prompt })`: main thread が最後に送った request (model・system prompt・tool・messages) の後ろに `prompt` を足した tool 無しの completion。prefix が cache から出る。最初の応答前と `/clear` 後は `reason: 'nothing-to-fork'`
- `classify(text, labels, { model? })`: label を 1 つ選ばせる。どれも名指さなければ `undefined`

### session

- `messages({ agentId?, as? })`: transcript を最新 4096 件まで。既定は `{ role, text, toolUses }` の行、`{ as: 'api' }` で Messages API 形 (`{ role, content }`)。`agentId` で subagent / fork / 同 process の teammate の会話を読む (読めなければ `{ deny }`)
- `usage({ breakdown?, columns? })`: `{ startedAt, context, rateLimits, cost }` (status line と同じ数字)。`breakdown: 'full'` は `/context` と同じく token-count API で内訳を数え、`'summary'` は手元で見積もる
- `version()`: `{ version, base?, builtAt? }`
- `repo()`: git リポの root と origin remote (リポ外は `null`)
- `compact({ instructions? })`: `/compact` と同じ。turn の実行中は reject、hook が拒めば `{ skip }`
- `send({ to, text })`: 下の「`$.session.send`」節
- `append({ message: { type: 'user' | 'system', content }, agentId? })`: 会話に行を足す。`user` は人には打鍵として見えないが model が読む行、`system` は model が読まない notice。`content` は text block だけ (notice は 1 つ)。door は `note`、上の plugin が拒めば `{ deny }` で何も保存されない
  - 以下の request の中の位置は、代役の API に向けた request の body での実測 (reference の `claude-mods/lab-setup`)。first-party の API に送る形が同じかは見ていない
  - 実測: `user` の行は transcript に `isMeta: true` で残り、次の request で人の prompt と同じ user message (context block の後・prompt の前) に載る (起動・resume・`/clear`・compact の後の最初の prompt で観測)。main の tool loop の途中で足した時の位置は未観測
  - 実測: 載らない時機がある。compaction の chain の中 (`session.compact` / `classic.PostCompact` の after、`classic.SessionStart (compact)`) で足した行は `compact_boundary` の前に書かれて compact 後の会話に残らない。`turn.start` で足した行はその turn の最初の request に間に合わず、次の request で前の user message の末尾に差し込まれる (前の prefix が変わるので prompt cache もそこで切れる)。`-p` の起動時の `classic.SessionStart` の中では `refused: this session keeps no conversation to append to` で reject される
  - 実測: `agentId` 付きは走行中の subagent の次の request に、直前の tool_result と同じ user message の後ろの text block として載り、main の request には載らない。終わった subagent と存在しない id は `refused: no running loop is <agentId>` で reject される (両者は文言で区別できない)
- `authorize()`: session の Anthropic credential を host に持たせたまま opaque な handle を返す (`{ handle, kind: 'bearer' | 'api-key' }`、first-party の credential が無ければ `null`)。`$.http.fetch(url, { auth: handle })` で first-party の host にだけ header を付けて使う

### tool (`$.tool.register` した tool)

実測 (2.1.299、`--plugin-dir` の mod):

- `session.start` で登録した tool は対話・`-p`・subagent の request の `tools` に載り、model の呼び出しは同名の `tool.call` hook に届き、`{ result: string }` の文字列がそのまま tool_result になる。`/clear` と session 内の `/resume` の後も登録は残る
- engine は `inputSchema` で入力を検査しない。必須欄の欠落や型違いの値がそのまま handler に届くので、handler の入口で parse する
- `next` を呼ばずに答えると permission の判定を一切通らない (`tool.check`・PreToolUse・ダイアログ・auto mode の classifier のどれも起きない)。`next(e)` を呼ぶと判定を通るが、core まで降りて `<plugin> registered the tool <name> but no tool.call hook answered this call` のエラー結果 (`is_error: true`) が返る (permission mode default で許可した時。auto mode では classifier の結果 `Auto mode could not evaluate this action ...` が先に返る)。permission を通しつつ自前で答える形は見つかっていない
- handler の中の `$.session.id()` は subagent からの呼び出しでも main の session id で、呼び手の区別は `e.agentId` だけ。`$.session.cwd()` は作業ディレクトリの realpath
- `isDeferred: true` が効くのは ToolSearch が有効な時だけ。`ANTHROPIC_BASE_URL` が first-party の host でないと ToolSearch は無効になり (debug log `[ToolSearch:optimistic] disabled: ANTHROPIC_BASE_URL=... is not a first-party Anthropic host`)、deferred の tool も全文で `tools` に載る。`ENABLE_TOOL_SEARCH=true` で有効にできる
- 読み込み前の deferred の plugin tool を名前で直接呼んでも handler に届いた (対話 1 回)

### managed で install された mod だけの口

組織の managed settings が install・有効化した mod にだけ答え、他の mod には `{ deny }` を返す。型定義は「契約であって壁ではない」(どの mod も人の config ファイルを読める) と書く。

- `$.session.identity()`: `{ kind, organizationId?, organizationType?, email?, isVerified }`。`kind` は `claude.ai` / `console` / `api-key` / `oauth-token` / `none` / cloud provider 名 (`bedrock` / `vertex` ...)。組織と email が入るのは managed `forceLoginOrgUUID` がその組織を挙げている時だけ。`isVerified` はサーバが応答した値か (false ならディスクの login record 由来)。request は出さない
- `$.prompt.media({ id, offset? })`: `prompt.submit` hook の中で、`e.attachments` の `id` の画像・文書の bytes を 1 回 4 MiB まで base64 で返す (`{ type, mediaType, base64, size, next? }`。`next` があれば続きを `offset` で読む)。engine が扱えなかったものは `{ unreadable }`、submission の後や対象外は `{ deny }`。event を上げない engine 自身の読み取りで、hook は答えられない

## 制限

- `fs.read` / `fs.write` は 4 MiB を超えると reject。追記 API は無いので、log を `read` + `write` で伸ばす作りは 4 MiB で止まる (ファイルを分ける)。network 越しのパス表記は触らずに reject
- `store` は全体で JSON 4 MiB まで。関数・循環参照は reject、`Date` は ISO 文字列、`undefined` の欄は落ち、`Map` / `Set` は `{}` になる
- `env.get` / `env.set` の変数名、`state.get` / `state.set` の `plugin` / `key` は文字列リテラル必須 (validate が列挙し、列挙外は拒否)
- hook が `next()` に渡す・返す・`$` に渡す値: 28,000 階層より深い入れ子は上限を名指して拒否。getter が `RangeError` を投げた key だけ拒否される。`__proto__` key は落ちない (data としての own key)。長い文字列は切り詰めて log される
- `http.fetch` は http / https だけ (WebSocket・SSE・生 socket は無い)。応答は body を全部読んでから `{ status, ok, headers, text }` で返り、stream しない。body の上限は 4 MiB (`Content-Length` が超えると拒否。`HEAD` と `204` / `205` / `304` は除く)。長期接続を持つ・再接続する手段は `$` に無く、SSE の endpoint を叩けば「サーバが閉じるまで resolve しない fetch」になるだけ。長期接続が要るものは全部 `process.spawn` の子 (stdout を stream で読める) に置き、再接続も子の終了を見て spawn し直す module 側のループで行う。body は文字列。組織の web-fetch policy に従い、`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` の下では built-in の request と `auth` 付きの request を拒む。`socketPath` で Unix socket 越しの HTTP を話せる (絶対パス、約 100 byte まで。redirect も同じ socket、proxy 無し、`https:` は URL の host で TLS 検証)。timeout の記述は型定義に無い
- `process.run(argv, { cwd, env, stdin, timeoutMs })` は終了後に出力をまとめて返す。`env` は host の process の環境の上に重ねる (`process.spawn` も同じ)。stdout / stderr はそれぞれ先頭 4 MiB (`isStdoutTruncated` / `isStderrTruncated`)。timeout は既定 30 秒、最大 10 分。背景に残って書き続ける子がいると timeout まで返らない。実測: stdio を ignore にし detached で孫を起こしてすぐ終わる子なら、孫を待たずに返る (25〜26 ms、2 回。孫が turn の後も生きていたことの確認は 1 回)。git は repo hooks 無効で走る。signal で終わった子は `exitCode: 1` (実測)
- `process.spawn({ argv, cwd, env, input })` は出力を `{ stream, text }` の断片で stream し、最後に `{ code, signal }`。ループを抜ける・`return()`・`next.signal` の abort・module の unload で子が kill され、hook が return しても子は生きる (ループを終えて終わらせる)。`input` は 1 回書いて閉じるだけで、書き続ける stdin は無い。子が走った後に上の plugin が deny すると「走ったが plugin が結果を伏せた」旨で reject
- 予算: hook 自身のコードの時間が 1 回 10 秒まで。`$` 呼び出しと `next(e)` の待ちは数えない (`$.clock.sleep` は数える)。実測では `$.process.run` で 40 秒待っても、during 配置で `next(e)` を 20 秒保留しても超過しなかった。module 内の素の Promise (自前 Button の押下待ち等) を待つ時間は数えられると読める (定義文からの推測、未検証)
- 実測: `$.clock.sleep` で 12 秒待つ `tool.call` hook は 10 秒で `tool.call hook skipped: ran past its 10s budget` になり、hook が無いものとして core に落ちる (`$.tool.register` した tool なら許可ダイアログが出て、Yes で `no tool.call hook answered` のエラー結果)。止まらずに走り続けると debug log に `hook overran: <plugin>: still running 5000ms after its budget ran out; ignores its signal` も出る
- 実測: hook が `$.process.run` を待つ間に人が Esc を押すと、`$.process.run` は `aborted` で即 reject して子は kill され、`next.signal.aborted` は true、`turn.complete` は `reason: 'aborted'`
- `$.clock.every` 等の callback から呼んだ `$` は、同じ plugin の `*` hook には現れない (実測)
- plugin の reload・削除後もまだ走っている hook からの `$.agent.register` は拒否される

## 外部プロセスとつなぐ形

| 形 | 使う口 | 向き |
|---|---|---|
| CLI を叩く | `$.process.run(['tool', 'sub', ...])` | 往復 1 回 |
| session 寿命の子を持つ | `session.start` から `$.process.spawn` し、`for await` で出力を読み続ける (hook は待たずに返す) | 外 → mod の stream |
| HTTP server に訊く | `$.http.fetch(url, { socketPath })` | 往復 1 回 |
| ファイルを poll | `session.start` から `$.clock.every(ms, () => $.fs.read(...))` | 外 → mod |
| 別の Claude Code session へ送る | `$.session.send({ to, text })` | mod → 別 session |
| OS 通知 | `$.ui.notify(text)` (届かなければ `$.ui.toast` に倒す) | mod → 人 |

`$.process.spawn` の子の例 (型定義の例と同形):

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

- `to` は名前・agent id・受信した `from` アドレス、または `{ sessionId }` / `{ agentId }`。model の SendMessage と同じ経路で送り、`session.send` event を通る (自 plugin の hook は通らない)
- 結果は `{ isDelivered, reason? }`。`isDelivered` は相手の queue / inbox に入ったことで、読まれたことではない。`session.send` hook が返す答えと model に見える文面は reference の `claude-mods/capabilities` の `session.send` 行
- 届く範囲は同じ `CLAUDE_CONFIG_DIR` の session だけ。別 config home の session には `$.session.send` も model の SendMessage も届かない (実測: `no live session on this machine has id ...` / `No agent named '...' is reachable.`)
- 受け側では `session.receive` の `origin` が `{ kind: 'peer', plugin: '<送り手の plugin>' }` になる。`plugin` は送り手の自己申告

## `$.store` の保存先

`<plugins dir>/store/<plugin id>-<hash>.json`。`<plugins dir>` は `CLAUDE_CODE_PLUGIN_CACHE_DIR` があればそこ、無ければ `<CLAUDE_CONFIG_DIR>/plugins` (実測)。resume と別 session を跨いで残る。plugin id は `--plugin-dir` の mod なら `<name>-inline`。

## state ライブラリ

型定義は `import { atom, derive, memberOf, read, update } from 'claude-code'` を `$.state` の上の小さな部品として載せる: `atom(ref, initial)` (読むと未書き込みでも初期値)、`derive(sources, fn)` (source の version が動いた時だけ再計算)、`memberOf(family, e)` (描画中の instance の family member)、`read($, source)`、`update($, atom, fn)` (`ifVersion` 付きで書き、外れたら再試行)。

```ts
import { atom, read, update } from 'claude-code'
const count = atom({ plugin: 'counter', key: 'count' } as const, 0)
// 描画: const n = await read($, count)   押下: onPress={() => update($, count, n => n + 1)}
```

## 2026-10-14 時点の未確認

- `http.fetch` の `socketPath` の説明 "one per session, in a private directory" の意味 (任意の UDS に繋げるのか)
- state ライブラリが実行時に import できるか (型定義の冒頭は「実行時の `claude-code` の import は空」と書き、同じファイルの `atom` 等の説明は「plugin の環境で動く」と書く)
