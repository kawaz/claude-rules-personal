# Claude Mods (function hooks)

Claude Code の plugin が持てる TypeScript / JavaScript の hook module。engine の event と描画を `($, e, next)` の middleware で書き換え、外界へは `$` を通して届く。

- [overview](overview.md) — plugin の 3 ファイル構成、`register(on, options)` と `userConfig`、pattern と matcher、tier の入れ子、`next` の持ち物、失敗と `.catch`、実行環境と時間予算、security モデルと built-in `sec-default`、command hook・MCP・skill との差分表。
  発火語: Claude Mods, function hooks, hooks module, register(on), ($, e, next), Koa, middleware, tier, prepend, append, next.to, next.trace, .catch, fail open, guard, matcher, on('!...'), classic.*, userConfig, pluginConfigs, options, worker, sandbox, sec-default, allowManagedModsOnly, command hook との違い, MCP との違い, classic.PreToolUse の e
- [develop](develop.md) — built-in mod の一覧、`--plugin-dir` 等の一時読み込み、validate / test (`claude-code/testing` と `mock`) / hot-reload / 型定義と tsconfig / noun の契約。
  発火語: --plugin-dir, CLAUDE_CODE_PLUGIN_DIRS, claude plugin validate, gatingHooks, claude plugin test, claude-code/testing, mock.clock, mock.session, tier(), hot-reload, reload されない, dev-mods, /plugin-types, tsconfig, noun の契約, dependencies, you-should-know
- [events](events.md) — hook できる event の全一覧 (engine / `$` の操作 / `classic.*`)、pattern での選び方、hook された時だけ上がる event、1 turn の実測時系列、対話と `-p` の差、`session.start` が `/clear` で起きない等の意味論。
  発火語: on('*'), event 一覧, 発火順, tool.call, tool.check, prompt.submit, prompt.autocomplete, prompt.compose, prompt.mention, session.append, session.receive, session.start, telemetry.log, ui.fault, origin.kind, composer, asUser, /clear を拾う, subagent の turn, -p で動かない, isInteractive
- [capabilities](capabilities.md) — event ごとの能力表 (`e` の主要欄、`next(e)` の結果、書き換えられる欄と配置、model に届く文脈を足す欄、pinned な欄、built-in mod の実例) と、model に文脈を渡す時の event の選び方。
  発火語: model に文脈を渡す, context を足す, additionalContext, reminder を足す, tool.call の context, skill.prompt, frontmatter, prompt.attachment, session.append の door, queue door, command.run の context が消える, after next() dropped, wrong shape, stop_hook_active, pinned, agentId で subagent, 書き換えられる欄, 組織管理下で効かない
- [dollar-api](dollar-api.md) — `$` の noun ごとのメソッドと制限 (4 MiB、HTTP のみ、stdin は 1 回、予算は `$` 待ちを数えない)、managed で install された mod だけの口、外部プロセスとつなぐ形、`$.session.send` の届く範囲、`$.store` の保存先、state ライブラリ。
  発火語: $.fs, $.http.fetch, socketPath, $.process.run, $.process.spawn, $.store, $.store の保存先, $.state, atom, $.clock.every, $.env.get, $.session.send, $.session.append, $.session.identity, $.prompt.media, $.mcp.connect, $.ui.notify, $.ui.selection, $.model.complete, prompt cache, $.telemetry, $.ui.status, HookBudget, 4 MiB
- [dialogs](dialogs.md) — permission / AskUserQuestion / Elicitation / engine 自身のダイアログで読めるもの・割り込める点・返せるもの、組織管理下で deny rule が mod の allow に勝つ仕組み、表示中のダイアログを閉じる during 配置、待つ形。
  発火語: permission ダイアログ, AskUserQuestion, $.ui.ask, classic.PermissionRequest, permission_suggestions, tool.check で allow, deny rule が効く, allowModsToOverrideDenyRules, ceiling, ダイアログを外から答える, Elicitation, trust ダイアログ, refusal dialog, CLAUDE_AFK_TIMEOUT_MS
- [prompt-injection](prompt-injection.md) — `$.prompt.submit` の `asUser` との使い分けと、`$.prompt.read` / `fill` と外部からの Enter で `composer` 刻印のユーザプロンプトを入れ、書きかけを退避・復元する手順。
  発火語: prompt を外から入れる, $.prompt.fill, $.prompt.read, $.prompt.submit, asUser, 人の入力として送る, 書きかけの退避, no_composer, origin composer
- [lab-setup](lab-setup.md) — 別 `CLAUDE_CONFIG_DIR` と `env -i` による隔離実験、起動・trust・debug log の見方、観測 mod (`on('*')` で JSONL) と peer socket への直接送信スクリプト。
  発火語: mod を試す, 隔離環境, 実験用 config home, env -i, --debug, 観測 mod, 全 event を記録, claude agents --json, sessions/<pid>.json, peerToken, uds-send
