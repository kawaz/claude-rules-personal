# Claude Mods とダイアログ

permission の確認・AskUserQuestion・MCP Elicitation・engine 自身のダイアログについて、mod から何が読めて、どこで割り込めて、何を返せるか。Claude Code 2.1.283 の型定義と 2.1.284 の実機 (default permission mode) による。

## 要点

- **出る前に決める**のが基本。permission は `tool.check` か `classic.PermissionRequest` で答えればダイアログは出ない
- **表示中のダイアログを閉じる**ことは `tool.call` の during 配置でできる。AskUserQuestion は答え (`{ result }`) を返せる。permission は `{ deny }` だけ (許可側は tool の実行結果を作れないので、出る前に決める)
- **engine が描いたダイアログのボタンを押す API は無い**。`ui.press` / `ui.input` / `ui.select` の対象は plugin 自身が描いた要素だけ
- **描き換えられるダイアログは AskUserQuestion だけ**。permission のダイアログは engine だけが描く (mod は `$.ui.notice(tool_use_id, text)` で下に 1 行足せる)
- **engine 自身のダイアログ** (workspace trust / hot-reload の同意 / update / login / `/config` / cross-session 受信の保留確認 / survey) には event も component も無く、触れない。trust の前は module 自体が読まれない

## permission の時系列

1. `tool.call` — ダイアログは `next(e)` の内側にある。`{ deny }` / `{ result }` を返せば出ない。引数は書き換え可 (`tool` / `tool_use_id` / `agentId` は不可)。managed settings の hook が先に走る
2. `classic.PreToolUse` — `tool.call` の core の中。`allow` / `ask: string` / `deny: string` / `updatedInput` / `additionalContext`
3. `tool.check` — mode が ask を決着させる前。`next(e)` が engine の判定 (rules / mode / tool 自身の check / PreToolUse) を返し、hook はどちら向きにも覆せる。返すのは `{ decision: 'allow' | 'ask' | 'deny', reason?, rule? }`
4. ask の決着 — mode の decider (ダイアログ / auto mode の classifier / headless host)。classifier が拒むと `classic.PermissionDenied` (`retry` を返せる)
5. `classic.PermissionRequest` — ダイアログの直前。`{ decision: { behavior: 'allow', updatedInput?, updatedPermissions? } }` か `{ decision: { behavior: 'deny', message?, interrupt? } }`
6. ダイアログ — engine だけが描く
7. 人の応答 — 拒否は `ToolUse` の `isErrored`、許可なら tool が走り `tool.call` の `next(e)` が `{ ref, result, text, isReadOnly? }` で resolve

`$.tool.check({ tool, input })` は同じ判定を問い合わせだけで走らせる (何も実行せず、ダイアログも PreToolUse も classifier も無い)。「この呼び出しはダイアログになるか」を事前に知る手段。

## 実測

| やったこと | 結果 |
|---|---|
| `tool.check` で `{ decision: 'allow' }` (engine が ask にする `touch`) | ダイアログ無しで実行。`classic.PermissionRequest` も出ない |
| `tool.check` で `{ decision: 'ask', reason }` (engine が allow にする `echo`) | ダイアログになり `Hook tool.check requires confirmation for this command: <reason> [plugin:<name>]` と出る。選択肢は Yes / No だけ |
| `classic.PermissionRequest` で `{ decision: { behavior: 'allow' } }` | ダイアログ無しで実行、tool 行に `Allowed by PermissionRequest hook` |
| `tool.call` を during 配置にし、ダイアログ表示後に外部契機で `{ deny }` | 表示中の permission ダイアログが閉じ、model は `Error: <deny の文>`。tool は走らない |
| `tool.call` で AskUserQuestion に `next` を呼ばず `{ result: { questions, answers } }` | ダイアログは出ず、`tool.check` / `PermissionRequest` も出ない。model が読む `tool_result` は人が答えた時と同文 (transcript の `toolUseResult` に `annotations: {}` が無い点だけ違う) |
| 同じく during 配置で、表示中に外部から答え | ダイアログが閉じる (7 秒後・21 秒後とも)。debug は `Aborting: tool=AskUserQuestion` → `resolved by a hooks module (result)`。人が先に答えれば `next(e)` 側が勝つ |
| `tool.check` 内で `$.process.run(['sleep','20'])` | 予算超過なし。画面は tool 行 `Waiting…` と spinner、フッタ `esc to interrupt` |
| 上の待ち中に Esc | `$.process.run` が `aborted` で reject、tool は `Interrupted`、transcript に `tool.check hook skipped: threw ...` |
| `tool.check` 内で `$.ui.ask` | AskUserQuestion ダイアログ (header `Plugin`) が出て、答えを decision にできる。デッドロック無し。呼んだ hook 自身は入れ子の `tool.check` に呼ばれない |
| AskUserQuestion の permission | engine の `tool.check` 判定は `{ decision: 'ask', reason: 'Answer questions?' }` で、`classic.PermissionRequest` も出る |

`classic.PermissionRequest` の `e` のキーは `session_id, transcript_path, cwd, prompt_id, permission_mode, hook_event_name, tool_name, tool_input, permission_suggestions?`。`tool_use_id` は無い (`tool.call` / `tool.check` 側にはある)。`permission_suggestions` はダイアログの「今後聞かない」系の選択肢に対応する (例: `Yes, and always allow access to <dir> from this project` に `[{ type: 'addDirectories', directories: [cwd], destination: 'session' }, { type: 'setMode', mode: 'acceptEdits', destination: 'session' }]`)。mod 由来の ask と AskUserQuestion の時は key 自体が無い。

## AskUserQuestion の構造

- `tool.call` の入力: `questions` (1〜4 件、各 `question` / `header` / `options` (2〜4 件、`label` / `description`) / `multiSelect`)、`title?`、`annotations?`、`metadata.source?`
- 出力 (`result`): `{ questions, answers: { <質問文>: <ラベル> }, annotations?, afkTimeoutMs? }`。multi-select はカンマ区切り。`result` は tool の出力 schema で検証される
- `ui.render` (`component: 'AskUserQuestion'`) の `props` は `{ tool, questions, metadataSource? }`、`requestId` は tool_use_id。`next({ ...e, props })` で questions を書き換えられる (schema に合わなければ原本が描かれる)。focus 位置・選択中の option・"Other" への入力途中は読めない
- `$.ui.ask(question, options)` は header `Plugin`、`tool_use_id` が `toolu_plugin_...` の AskUserQuestion を出し、選ばれたラベル (複数はカンマ連結、"Other" は自由文) を返す。dismiss と `-p` では reject
- 放置時の自動解決: 既定では約 6 分放置しても解決しない。環境変数 `CLAUDE_AFK_TIMEOUT_MS` を与えると、ダイアログ下に `auto-continue in Ns · any key to stay` が出て、その時間で `answers: {}` と `afkTimeoutMs` を返す (model には `No response after Ns — the user may be away from keyboard. ...`)

## MCP Elicitation

`classic.Elicitation` (ダイアログ前、`{ mcp_server_name, message, mode?, url?, elicitation_id?, requested_schema? }`) と `classic.ElicitationResult` (応答後、`action: 'accept' | 'decline' | 'cancel'`, `content?`)。mod の型で返せるのは `block` / `preventContinuation` / `stopReason` だけで、実質 decline しかできない (command hook の `hookSpecificOutput` にある accept と `content` は mod の型に無い)。

## ダイアログ中の間接的な信号

- `$.prompt.fill` が `{ isFilled: false, refusal: 'dialog' }` を返す (型定義はダイアログ全般と書く。実測は AskUserQuestion 表示中)
- `$.prompt.suggest` はダイアログが box を返すまで待たされる
- pane の focus 取得は拒まれ、キーボード無しで開く。Button の `action` (keybinding) も効かない
- survey が出ている間は `AbovePrompt` の `props.hasSurvey` が true

## 待つ形

| 形 | 仕組み | 確度 |
|---|---|---|
| 先に決める | `tool.check` / `classic.PermissionRequest` で方針から即答 | 実測済み |
| 出る前に外へ訊いて待つ | `tool.check` の中で `$.process.run` / `$.http.fetch` で外部に訊き、答えを `{ decision }` で返す。時間切れなら `next(e)` に委ねてダイアログを出す | 実測済み (予算・見え方・Esc) |
| 出しつつ外からも答える | `tool.call` で `const p = next(e)` を走らせたまま外部の答えと race。AskUserQuestion は `{ result }`、permission は `{ deny }` だけ | 実測済み |
| mod が人に訊く | `$.ui.ask` (`$` 呼び出しなので予算を消費しない) | 実測済み |
| 自前の承認 UI | `$.state` に pending を置き Pane / AbovePrompt に描く。押下を module 内 Promise で待つと予算を消費するので、先に deny して押下後に再実行させる設計になる | 推測 |

## 2026-09-29 時点の未確認

- auto mode で `classic.PermissionRequest` が起きるか (haiku は auto mode 非対応で試せていない)
- `classic.Elicitation` に型に無い `action` / `content` を返した時の runtime の扱い
- AskUserQuestion の入力 schema が 2 系統 (`kind` 付きと無し) あり、既定でどちらが model に出ているか
- AFK 自動解決の既定値の出所と、during 配置の hook が `hasExternalRacer` に当たるか
