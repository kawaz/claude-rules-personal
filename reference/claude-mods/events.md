# Claude Mods の event と発火順

hook できる event の一覧、1 turn の実測時系列、対話と `-p` の差、意味論の注意。一覧は Claude Code 2.1.283 の型定義 (`EngineEventOf` / `OpEventOf` / `ClassicEventOf`)、時系列と差分は 2.1.284 の実機で `on('*')` を置いて採ったもの。

## event の 3 系統

### engine が起こす event

| 区分 | event |
|---|---|
| tool | `tool.call`, `tool.check`, `tool.describe` |
| 描画・操作 | `ui.render`, `ui.resolve`, `ui.press`, `ui.input`, `ui.select`, `ui.message`, `ui.scroll`, `ui.focus` |
| agent | `agent.offer`, `agent.spawn` |
| prompt | `prompt.submit`, `prompt.fill`, `prompt.suggest`, `prompt.edit`, `prompt.section`, `prompt.context`, `prompt.attachment` |
| command / config / skill | `command.run`, `command.describe`, `config.set`, `config.describe`, `skill.prompt`, `attribution.text` |
| session | `session.start`, `session.receive`, `session.send`, `session.compact`, `session.attach`, `session.detach`, `session.measure`, `session.end` |
| 読み込み | `plugin.register`, `engine.create` |
| turn | `turn.start`, `turn.step` (stream), `turn.complete` |

### `$` の操作 (op event)

plugin (engine 自身や built-in も含む) の `$` 呼び出しがそのまま event になる: `fs.read`, `fs.write`, `http.fetch`, `process.run`, `process.spawn` (stream), `env.get`, `settings.read`, `clock.after`, `session.id`, `ui.log`, `ui.status`, `command.register`, `state.get` / `state.set` ... 。hook すれば他 plugin の呼び出しを書き換え・拒否・監査できる。

### command hook の event (`classic.*`)

`classic.SessionStart`, `classic.UserPromptSubmit`, `classic.PreToolUse`, `classic.PermissionRequest`, `classic.PermissionDenied`, `classic.PostToolUse`, `classic.PostToolBatch`, `classic.MessageDisplay`, `classic.Stop`, `classic.Notification`, `classic.SessionEnd`, `classic.Elicitation`, `classic.ElicitationResult` 等。`e` は command hook の stdin と同じ JSON。classic の chain は「managed settings の hook → hooks module → 他の settings hook (core)」の順。

## 1 turn の実測時系列 (対話、prompt → Bash 1 回 → 応答)

Bash は `echo` で engine が allow したためダイアログ無し。`ui.render` の括弧は component。mod 自身の log 処理が起こした `ui.log` / `fs.read` / `fs.write` は省いた。

| 経過 ms | event | 補足 |
|---|---|---|
| 2483 | `prompt.edit` | 入力 1 回。`origin: composer` |
| 2486 | `ui.render` (PromptHint) | |
| 2916 | `agent.offer` ×6 | Enter の後、利用可能な agent ごと |
| 2917 | `prompt.submit` | `origin: composer` |
| 2921 | `ui.render` (UserMessage / Spinner / AbovePrompt / PromptHint) | |
| 2923 | `classic.UserPromptSubmit` | |
| 2925 | `turn.start` | |
| 2927 | `attribution.text` ×2 | commit / PR 用の Co-Authored-By 等 |
| 2929 | `turn.step` (index 0) | |
| 2930 | `prompt.attachment` | environment 等。`origin: engine` |
| 4335 | `ui.render` (ToolUse / Spinner) | model の tool_use が stream で見えた時点 |
| 4759 | `tool.call` | |
| 4768 | `classic.PreToolUse` | |
| 4770 | `tool.check` | ask ならこの後に `classic.PermissionRequest` → ダイアログ |
| 4906 | `classic.PostToolUse` | |
| 4909 | `classic.PostToolBatch` | |
| 4913 | `ui.render` (ToolUse / ToolResult) | |
| 4914 | `agent.offer` ×6 → `attribution.text` ×2 → `turn.step` (index 1) → `prompt.attachment` | 2 回目の model 呼び出し |
| 5976 | `ui.render` (AssistantMessage) | |
| 5994 | `classic.MessageDisplay` | |
| 5996 | `classic.Stop` | |
| 6001 | `turn.complete` | `answer`, `durationMs`, `reason`, `usage` |
| 6002 | `session.measure` | context tokens / window / percent、cost |
| 6006 | `ui.render` (TurnDuration / AbovePrompt / PromptHint) | |
| 66003 | `classic.Notification` | 応答完了の 60 秒後、`notification_type: idle_prompt` |

1 turn の件数は 72 件で、そのうち `ui.render` が 30 件 (Spinner 9、PromptHint 6、ToolUse 4 ...)、`agent.offer` が 12 件を占める。`ui.render` を無条件に hook すると頻度が高いので、matcher (`{ component: 'UserMessage' }` 等) で絞る。

起動フェーズ (最初の prompt より前) は `engine.create → command.describe → ui.render → session.start → classic.SessionStart → ...` の順で約 270 件。`command.describe` が約 90 件、built-in の `telemetry` の `env.get` が約 140 件出る。`prompt.section` (system prompt の各節) と `tool.describe` の大半は最初の prompt の処理中に出る。

## 主な event の `e` の例

| event | `e` |
|---|---|
| `session.start` | `{ cwd, surface: 'terminal', isInteractive: true }` |
| `prompt.edit` | `{ origin: { kind: 'composer' }, text, cursor, start, end, inputText }` |
| `prompt.submit` | `{ text, wait: false, origin: { kind: 'composer' } }` |
| `turn.start` | `{ text, turnId }` |
| `turn.step` | `{ turnId, index, model, messageCount }` |
| `tool.call` | `{ tool: 'Bash', tool_use_id, command, description }` (tool の引数が平たく入る) |
| `tool.check` | `{ tool: 'Bash', input: { command, description }, tool_use_id }` |
| `turn.complete` | `{ answer, durationMs, isAborted, turnId, reason: 'answer', usage }` |
| `session.measure` | `{ context: { tokens, window, percent }, rateLimits, cost: { usd }, changed }` |
| `session.receive` | `{ origin: { kind: 'peer', plugin? }, text: '<cross-session-message ...>...' }` |
| `session.send` | `{ to, text, origin: { kind: 'model' } }` |
| `engine.create` | `{ plugins: [...] }` (この時点の `$` は空なので `*` hook から `$` に触らない) |

## 対話と `-p` の差

| 項目 | 対話 | `-p` |
|---|---|---|
| module の読み込み | `worker` | 同じ |
| `session.start` の `e` | `surface: 'terminal', isInteractive: true` | `surface: null, isInteractive: false` |
| `prompt.submit` の `origin` | `composer` | `sdk` |
| `$.prompt.read()` | composer の中身 | `{ text: '', cursor: 0 }` |
| `$.prompt.fill()` | `isFilled: true` | `{ isFilled: false, refusal: 'no_composer' }` |
| `$.ui.ask()` | ダイアログ | reject (`no tool named "AskUserQuestion" in this session`) |
| `ui.render` / `prompt.edit` / `classic.Notification` / `session.authorize` | 出る | 出ない |
| `session.end` | 出る | 出る。`reason: 'other'` |
| tool の流れ | `tool.call → PreToolUse → tool.check → PostToolUse → PostToolBatch` | 同じ |
| 未 trust の cwd | trust 承諾まで module を読まない | trust 確認なしで読む |

## 意味論の注意

- `session.start` は「プロセスごと・plugin の読み込みごとに 1 回」。`/clear` では起きない (`session.end` が `reason: 'clear'` で起き、その後の `session.start` は無い)。hot-reload では再度起きる
- 起動直後と reload 直後は `session.start` より先に `ui.render` hook が走る (reload では既存の全 UserMessage が再 render される)。`session.start` で初期化する module 変数は、`ui.render` hook では初期値のままのことがある
- `session.end` は exit / `/clear` / resume / logout / signal / `-p` の完了で起き、既定 1.5 秒の予算。`kill -9` では起きない。端末ごと kill した時の `reason` は `other`
- `prompt.submit` の `next(e)` は model の応答を待たず、prompt が session に入り turn が始まった時点 (数 ms) で resolve する
- `prompt.submit` の `e.origin.kind` は閉じた集合 (`composer` / `bridge` / `sdk` / `task-notification` / `scheduled-trigger` / `peer` / `peer-send-message` / `projects-relay` / `channel` / `coordinator` / `observer` / `plugin` / `unclassified` 等)。plugin がこれを刻むことはできない (`$.prompt.submit` は `{ kind: 'plugin', name }` になる)
- 別セッションからの配送は `session.receive` を queue の前に通る。`next({ ...e, text })` で書き換え、`{ consumed: reason }` で握りつぶせる (model にも画面にも出ない)。同じ config home の SendMessage も、UDS に直接書いた frame も `origin: { kind: 'peer' }` になり、送り手の `$.session.send` だと `plugin` が付く。続く `prompt.submit` は `peer` (plugin は落ちる)
- `ui.render` の `UserMessage` は `props.from.name` に envelope の `from-name`、`props.text` に envelope を剥がした本文を持つ
- `*` hook から見える自 plugin の `$` 呼び出しは、hook の中から呼んだものだけ。`$.clock.every` 等の timer callback から呼んだものは見えない
- plugin 自身の `$.session.send` は自 plugin の `session.send` hook を通らない (`skipped: re-entry`)
- 対話 session は応答完了の 60 秒後に `classic.Notification` (`idle_prompt`) を出す
