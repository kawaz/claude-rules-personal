# Claude Mods (function hooks)

Claude Code の plugin が持てる TypeScript / JavaScript の hook module。engine の event と描画を `($, e, next)` の middleware で書き換え、外界へは `$` を通して届く。early access (インストール物は `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` か rollout で有効)。

- [overview](overview.md) — plugin の 3 ファイル構成、`register(on, options)` と入れ子の順序、実行環境と時間予算、security モデル、command hook・MCP・skill との差分表。
  発火語: Claude Mods, function hooks, hooks module, register(on), ($, e, next), Koa, middleware, worker, sandbox, command hook との違い, MCP との違い, plugin との違い, sec-default
- [develop](develop.md) — mod が読まれる条件 (flag / rollout / built-in)、`--plugin-dir` 等の一時読み込み、validate / test / hot-reload / 型定義の書き出し。
  発火語: CLAUDE_CODE_ENABLE_FUNCTION_HOOKS, hooks modules are not turned on, --plugin-dir, CLAUDE_CODE_PLUGIN_DIRS, claude plugin validate, claude plugin test, hot-reload, reload されない, dev-mods, /plugin-types
- [events](events.md) — hook できる event の全一覧 (engine / `$` の操作 / `classic.*`)、1 turn の実測時系列、対話と `-p` の差、`session.start` が `/clear` で起きない等の意味論。
  発火語: on('*'), event 一覧, 発火順, tool.call, tool.check, prompt.submit, session.receive, session.start, classic.PreToolUse, origin.kind, composer, -p で動かない, isInteractive
- [dollar-api](dollar-api.md) — `$` の noun ごとのメソッドと制限 (4 MiB、HTTP のみ、stdin は 1 回、予算は `$` 待ちを数えない)、外部プロセスとつなぐ形、`$.session.send` の届く範囲。
  発火語: $.fs, $.http.fetch, socketPath, $.process.run, $.process.spawn, $.store, $.state, $.clock.every, $.env.get, $.session.send, $.ui.status, HookBudget, 4 MiB
- [dialogs](dialogs.md) — permission / AskUserQuestion / Elicitation / engine 自身のダイアログで読めるもの・割り込める点・返せるもの、表示中のダイアログを閉じる during 配置、待つ形。
  発火語: permission ダイアログ, AskUserQuestion, $.ui.ask, classic.PermissionRequest, permission_suggestions, tool.check で allow, ダイアログを外から答える, Elicitation, trust ダイアログ, refusal dialog, CLAUDE_AFK_TIMEOUT_MS
- [prompt-injection](prompt-injection.md) — `$.prompt.read` / `fill` と外部からの Enter で、`composer` 刻印のユーザプロンプトを入れ、書きかけを退避・復元する手順。
  発火語: prompt を外から入れる, $.prompt.fill, $.prompt.read, $.prompt.submit, 人の入力として送る, 書きかけの退避, no_composer, origin composer
- [lab-setup](lab-setup.md) — 別 `CLAUDE_CONFIG_DIR` と `env -i` による隔離実験、起動・trust・debug log の見方、観測 mod (`on('*')` で JSONL) と peer socket への直接送信スクリプト。
  発火語: mod を試す, 隔離環境, 実験用 config home, env -i, --debug, 観測 mod, 全 event を記録, claude agents --json, sessions/<pid>.json, peerToken, uds-send
