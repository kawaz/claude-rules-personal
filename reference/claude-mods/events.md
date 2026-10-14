# Claude Mods の event と発火順

hook できる event の一覧、1 turn の実測時系列、対話と `-p` の差、意味論の注意。一覧と意味論は Claude Code 2.1.299 の型定義 (`EngineEventOf` / `OpEventOf` / `ClassicEventOf`)、時系列と対話 / `-p` の差は 2.1.284 の実機で `on('*')` を置いて採ったもの。event ごとの `e` / 結果 / 書き換えられる欄は reference の `claude-mods/capabilities`。

## event の 3 系統

### engine が起こす event

| 区分 | event |
|---|---|
| tool | `tool.call`, `tool.check`, `tool.describe` |
| 描画・操作 | `ui.render`, `ui.resolve`, `ui.press`, `ui.input`, `ui.select`, `ui.message`, `ui.fault`, `ui.scroll`, `ui.focus` |
| agent | `agent.offer`, `agent.spawn` |
| prompt | `prompt.submit`, `prompt.fill`, `prompt.suggest`, `prompt.edit`, `prompt.autocomplete`, `prompt.section`, `prompt.context`, `prompt.compose`, `prompt.attachment`, `prompt.mention` |
| command / config / skill | `command.run`, `command.describe`, `config.set`, `config.describe`, `skill.prompt`, `attribution.text` |
| telemetry | `telemetry.log`, `telemetry.mark` |
| session | `session.start`, `session.receive`, `session.append`, `session.send`, `session.compact`, `session.attach`, `session.detach`, `session.measure`, `session.end` |
| 読み込み | `plugin.register`, `engine.create` |
| turn | `turn.start`, `turn.step` (stream), `turn.complete` |

このうち `tool.call` / `tool.check` / `prompt.submit` / `prompt.fill` / `prompt.suggest` / `prompt.compose` / `command.run` / `config.set` / `agent.spawn` / `session.send` / `session.compact` / `session.append` / `telemetry.log` / `telemetry.mark` / `ui.scroll` / `ui.focus` は plugin も `$` から呼べ、engine 自身の呼び出しと同じ chain を通る (呼んだ hook だけ飛ばされる)。

### `$` の操作 (op event)

plugin (engine 自身や built-in も含む) の `$` 呼び出しがそのまま event になる。hook すれば他 plugin の呼び出しを書き換え・拒否・代答・監査できる。

| noun | event |
|---|---|
| model / audio / mcp | `model.complete`, `model.classify`, `model.fork`, `audio.play`, `audio.speak`, `mcp.call`, `mcp.connect` |
| session / turn / prompt | `session.cwd`, `session.root`, `session.model`, `session.turns`, `session.id`, `session.messages`, `session.repo`, `session.surface`, `session.surfaces`, `session.authorize`, `session.identity`, `session.usage`, `session.version`, `turn.abort`, `prompt.read` |
| tool / command / config / agent | `tool.list`, `tool.register`, `command.list`, `command.register`, `config.list`, `agent.list`, `agent.register` |
| ui | `ui.toast`, `ui.status`, `ui.log`, `ui.notice`, `ui.invalidate`, `ui.open`, `ui.close`, `ui.panes`, `ui.selection`, `ui.copy`, `ui.notify`, `ui.blit` |
| fs / store / state | `fs.read`, `fs.write`, `fs.list`, `fs.exists`, `fs.stat`, `fs.ancestors`, `store.get`, `store.set`, `store.delete`, `store.keys`, `state.get`, `state.set` |
| clock / http / process / settings / env | `clock.now`, `clock.sleep`, `clock.after`, `clock.every`, `http.fetch`, `process.run`, `process.spawn` (stream), `settings.read`, `env.get`, `env.set` |

plugin が `engine.create` で足した noun の method も `<noun>.<method>` の event になる (結果は `{ value }` / `{ deny }`)。

### command hook の event (`classic.*`)

`classic.PreToolUse`, `classic.PostToolUse`, `classic.PostToolUseFailure`, `classic.PostToolBatch`, `classic.PermissionRequest`, `classic.PermissionDenied`, `classic.UserPromptSubmit`, `classic.UserPromptExpansion`, `classic.SessionStart`, `classic.SessionEnd`, `classic.Setup`, `classic.Stop`, `classic.StopFailure`, `classic.SubagentStart`, `classic.SubagentStop`, `classic.PreCompact`, `classic.PostCompact`, `classic.PreModelSwitch`, `classic.PostModelSwitch`, `classic.Notification`, `classic.MessageDisplay`, `classic.Elicitation`, `classic.ElicitationResult`, `classic.TeammateIdle`, `classic.TaskCreated`, `classic.TaskCompleted`, `classic.ConfigChange`, `classic.InstructionsLoaded`, `classic.WorktreeCreate`, `classic.WorktreeRemove`, `classic.CwdChanged`, `classic.FileChanged`, `classic.DirectoryAdded`。

- engine がその classic hook を走らせる地点で、settings hook の有無に関係なく発火する
- `e` は command hook の stdin と同じ JSON。`classic.PreToolUse` だけは `tool.call` と同じ envelope (`tool` / `tool_use_id` / 引数を平たく)
- chain は「managed settings の hook → hooks module → 他の settings hook (core)」の順で、managed の block は全 module より上で chain を終える

### pattern での選び方

- `on('*')` は全 event (plugin の noun の event も含む) を見る。自分のフレームには再入しない
- `on('classic.*')` のように namespace で選べる。`on('!tool.*')` は否定
- installed plugin では `*` と否定は telemetry の event を選ばない。`telemetry.log` か `telemetry.*` と名指しする
- `tool.check` / `prompt.compose` / `prompt.autocomplete` は、読み込まれた plugin のどれかが hook している時だけ engine が上げる。hook を足すと、その event が全 tool call・全 system prompt の描画で走るようになる

## 1 turn の実測時系列 (対話、prompt → Bash 1 回 → 応答)

Bash は `echo` で engine が allow したためダイアログ無し。`ui.render` の括弧は component。mod 自身の log 処理が起こした `ui.log` / `fs.read` / `fs.write` は省いた。読み込んでいた mod は built-in と `on('*')` の観測 mod。

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

1 turn の件数は 72 件で、そのうち `ui.render` が 30 件 (Spinner 9、PromptHint 6、ToolUse 4 ...)、`agent.offer` が 12 件を占める。`ui.render` を無条件に hook すると頻度が高いので、matcher (`{ component: 'UserMessage' }` 等) で絞る。component は `AskUserQuestion` / `UserMessage` / `AssistantMessage` / `ToolUse` / `ToolResult` / `ToolGroup` / `ToolProgress` / `CommandOutput` / `Spinner` / `TurnDuration` / `InfoNotice` / `SessionMode` / `PromptHint` / `AbovePrompt` / `Pane`。

起動フェーズ (最初の prompt より前) は `engine.create → command.describe → ui.render → session.start → classic.SessionStart → ...` の順で約 270 件。`command.describe` が約 90 件、built-in の `telemetry` の `env.get` が約 140 件出る。`prompt.section` (system prompt の各節) と `tool.describe` の大半は最初の prompt の処理中に出る。

## 主な event の `e` の例

| event | `e` |
|---|---|
| `session.start` | `{ cwd, surface: 'terminal', isInteractive: true }` |
| `prompt.edit` | `{ origin: { kind: 'composer' }, key?, text, cursor, start, end, inputText }` |
| `prompt.submit` | `{ text, wait: false, origin: { kind: 'composer' }, command?, isMeta?, attachments?, context?, turnId? }` |
| `turn.start` | `{ text, turnId, agentId? }` (`agentId` は subagent / teammate の turn だけ) |
| `turn.step` | `{ turnId, index, model, effort?, messageCount, agentId? }` |
| `tool.call` | `{ tool: 'Bash', tool_use_id, command, description, agentId?, requestMeta? }` (tool の引数が平たく入る) |
| `tool.check` | `{ tool: 'Bash', input: { command, description }, tool_use_id?, agentId?, ceiling? }` |
| `turn.complete` | `{ answer, durationMs, isAborted, turnId, agentId?, reason: 'answer', usage }` |
| `session.measure` | `{ context: { tokens, window, percent }, rateLimits, cost: { usd }, changed }` |
| `session.receive` | `{ origin: { kind: 'peer', plugin? }, text: '<cross-session-message ...>...' }` |
| `session.send` | `{ to, text, origin: { kind: 'model' }, agentId? }` |
| `session.append` | `{ message: { type, name?, role?, isMeta?, content }, door, origin, uuid, agentId? }` |
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

- `session.start` は「プロセスごと・plugin の読み込みごとに 1 回」で、最初の 1 回は await される (ここでの `$.tool.register` は turn 1 に間に合う)。後の回 (enable・worker の再起動・hot-reload) はその plugin の hook だけが走る。reload では変わった module だけ (どれかが `engine.create` / `plugin.register` を hook していれば全部)
- `/clear` では `session.start` は起きない (`session.end` が `reason: 'clear'` で起き、process は新しい session id で続く)。`/clear` と `/resume` を拾うには `session.end` の `reason` か、`command.run` を `{ command: ['clear', 'resume'] }` で hook して `await next(e)` の後に状態を捨てる (built-in `diff` の形)
- 起動直後と reload 直後は `session.start` より先に `ui.render` hook が走る (reload では既存の全 UserMessage が再 render される)。`session.start` で初期化する module 変数は、`ui.render` hook では初期値のままのことがある (実測)
- `session.end` の `reason` は `prompt_input_exit` (/exit・ctrl+c・ctrl+d) / `clear` / `resume` / `logout` / `other` (`-p` の完了・SIGINT / SIGTERM / SIGHUP)。予算は chain 全体で既定 1.5 秒。`kill -9` では起きない (実測)
- `turn.start` / `turn.step` / `turn.complete` は main loop と subagent・teammate の turn の両方で起きる。区別は `e.agentId` (main では無い)。agent の spawn の内側にいた hook はその agent の `turn.start` / `turn.step` を聞かないが、`turn.complete` は spawner を含む全 hook が聞く
- `prompt.submit` の `next(e)` は model の応答を待たず、prompt が session に入り turn が始まった時点 (実測で数 ms)、または実行中の turn の後ろに queue された時点で resolve する
- `prompt.submit` の `e.origin.kind` は閉じた集合: `composer` / `bridge` / `sdk` / `task-notification` / `scheduled-trigger` / `peer` / `peer-send-message` / `projects-relay` / `channel` (`server` 付き) / `coordinator` / `observer` / `observer-activity` / `auto-continuation` / `unclassified` / `slack-ping` / `plugin` (`name`、`asUser?`)。hook は origin を設定できない (`$.prompt.submit` は `{ kind: 'plugin', name }` になる)
- 別セッションからの配送は `session.receive` を queue の前に通る。`next({ ...e, text })` で書き換え、`{ consumed: reason }` で握りつぶせる (model にも画面にも出ない)。同じ config home の SendMessage も、UDS に直接書いた frame も `origin: { kind: 'peer' }` になり、送り手の `$.session.send` だと `plugin` が付く (送り手の自己申告で、guard の鍵にしない)。agent team の mailbox 経由は `teammate` (送り手の名前) と `isVerified` が付く。続く `prompt.submit` は `peer` (plugin は落ちる、実測)
- `ui.render` の `UserMessage` は `props.from.name` に envelope の `from-name`、`props.text` に envelope を剥がした本文を持つ (実測)
- `*` hook から見える自 plugin の `$` 呼び出しは、hook の中から呼んだものだけ。`$.clock.every` 等の timer callback から呼んだものは見えない (実測)
- plugin 自身の `$.session.send` は自 plugin の `session.send` hook を通らない (`skipped: re-entry`)
- `$.ui.notify` の通知は `ui.notify` と `classic.Notification` の両方で聞こえる。聞いて timer から通知し直す mod 同士は無限に反響し、engine は止めない
- 対話 session は応答完了の 60 秒後に `classic.Notification` (`idle_prompt`) を出す (実測)

## 2026-10-14 時点の未確認

- 「hook している plugin がある時だけ上がる」event (`tool.check` / `prompt.compose` / `prompt.autocomplete`) に対して `on('*')` や glob の登録が「hook している」に数えられるか (時系列の実測では `*` だけの観測 mod で `tool.check` が出ていた)
