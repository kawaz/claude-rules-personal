# Claude Mods の立て付け

Claude Mods は Claude Code の plugin が持てる 5 種目の hook (function hook)。plugin という配布・発見の単位はそのままで、`hooks/hooks.json` に command / prompt / agent / http と並んで TypeScript / JavaScript のモジュールを名指しする。記述の根拠は Claude Code 2.1.299 が書き出した型定義 (`.claude-plugin/types/claude-code/index.d.ts`)、公式リポ anthropics/claude-code の `mods/` (README と built-in mod のソース)、実機観測。Mods は 2.1.287 から標準で有効で、有効化の設定は無く無効化もできない。型定義の冒頭と公式 README には API が予告なく変わりうるという注記が残っている (README の「function hooks が有効な所でだけ読まれる」は現状と合わない)。開発ループは reference の `claude-mods/develop`。

## plugin の形 (3 ファイル)

```text
<mod>/
  .claude-plugin/plugin.json   { "name": "<mod-name>", "version": "0.1.0", "description": "<one line>" }
  hooks/hooks.json             { "description": "<任意>", "modules": ["./register.ts"] }   (hooks.json からの相対、1 plugin 1 module)
  hooks/register.ts            register(on, options) を export する
```

- `$.state` を型付きで使う・noun を足すなら `types/index.d.ts` に契約を書く (`declare module 'claude-code' { interface PluginState { ... } }` / `interface EngineInterface { <noun>: ... }`)。置き場が `./types/index.d.ts` なら `plugin.json` の `"types"` は省ける。別の場所なら `"types"` で名指しする
- 拡張子は `.ts .tsx .jsx .js .mjs .cjs .mts .cts` (それ以外の名前のファイルは読まれない)。どれも ES module で `require` は無い。plugin 内の別ファイルは `import` 宣言で読む。`import()` を含む module は読み込まれない。JSX は global の `h` / `Fragment` に対してコンパイルされ (`h` / `Fragment` という名前を自分で宣言・import しない、`@jsx` pragma も書かない)、要素 (`Box` / `Text` / `Button` ...) は `$.ui.resolve(e)` で描画面ごとに取る
- 同じ hooks.json の command hook 等の entry は module と並走する
- 人が所有するフォルダから mod を読み込むたびに、engine がその mod のディレクトリへ `.claude-plugin/types/` (`claude-code/` = 型定義本体、`claude-code-tools/` = この build の built-in tool の入出力型、`claude-code-mcp/` = 最後の reload 時に接続していた MCP tool の入力型、`plugin.json` の `"dependencies"` に挙げた plugin の契約) と、自前の tsconfig が無ければそれを extends する `tsconfig.json` を書く。`-p` / SDK session では書かない

## `options` (`userConfig`)

`register(on, options)` の `options` は manifest の `userConfig` が宣言した欄の値で、既定値が埋まった状態で渡る。

- 保存先は settings.json の `pluginConfigs[<plugin id>].options` (sensitive なものは secure storage)。plugin id は install したものが `<name>@<marketplace>`、built-in が `<name>@builtin`、`--plugin-dir` が plugin.json の `<name>` (または `<name>@inline`)。読むのは user settings・`--settings`・managed settings で、project の `.claude/settings.json` は plugin の options に読まれない (built-in `agents-md` の README)
- module の読み込み前に宣言した `type` で検証され、required で値の無い欄があると読み込みが欄名付きで失敗する。`options` を宣言した string 欄は `/config` でその中から選ぶ picker になり、保存値が `options` の外なら未設定扱いで既定値が効く
- `/config` の行の key は `<plugin>.<field>`。`claude plugin configure <plugin>` が options と未設定の欄を表示し、`--values-stdin` で書き込む。`/plugin` の "Configure options" は `--plugin-dir` の plugin にも出る
- options の変更は plugin を reload し、`register` が新しい値で走り直す。hook は `options` を closure で掴めばよい
- `userConfig` が無いと debug に `options requested but its manifest declares no userConfig` と出て全部 absent になる (実測)

built-in `agents-md` の例 (読み方を 1 つの関数に閉じ、未設定・typo・型違いは既定値に倒す):

```ts
export function register(on: On, options: PluginOptions): void {
  const mode = MODES.find(m => m === options.instructionFiles) ?? DEFAULT_MODE
  if (mode === 'claude-md') return   // 何も hook しない mode
  on('prompt.context', async ($, e, next) => { ... })
}
```

## hook の形

```ts
export function register(on) {
  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    // before
    const r = await next(e)   // 下の hook と engine 自身の動作
    // after
    return r
  })
}
```

- `on(pattern, matcher?, hook)`、hook は `($, e, next)`。`$` は engine への唯一の口 (`$.noun.method(...)`)、`e` はその event の入力 (深く凍結された plain value。書き換えはコピーを `next` に渡す)、`next(e)` は下の hook と engine の既定動作を走らせて結果を返す。型定義は登録の「repeat」が throw すると書く (同じ event に matcher 違いで複数登録するのは built-in が多用している)。`register` の戻り値は捨てられ、Promise なら await される
- pattern: event 名 (`tool.call`)、namespace の glob (`classic.*` / `telemetry.*`)、全部 (`*`)、否定 (`!tool.*` = それ以外全部)。`*` と否定は installed plugin には telemetry の event を選ばない (`telemetry.log` / `telemetry.*` と名指しする)
- matcher は `e` の部分形: 葉は `===` か RegExp (`{ command: /^git / }`)、配列は any-of (`{ tool: ['Edit', 'Write'] }`)、object は入れ子の部分一致、配列の欄は要素のどれかが一致すれば当たる (`{ instructionFiles: { kind: ['project', 'local'] } }` は該当 kind の file を 1 つでも含む `e`)。8 階層まで。型付きの `e` では `{ startsWith }` のような書き方は型エラー
- Koa 流の入れ子。`on(X, A), on(X, B)` は `A(B(core))` で、先に登録した側が外側 (強い)。plugin 間の並びは tier `prepend` (管理者が前置) → `user` (人が入れたもの) → `append` (管理者が後置) → `builtin` (binary 同梱) → `core` (engine 最内)
- 1 つの hook で置き方を選ぶ: before (`...; return next(e)`)、after (`await next(e)` の後)、during (`const p = next(e)` を走らせたまま別の契機を待つ)、instead (`next` を呼ばずに `{ deny }` / `{ result }` 等を返す)、modifying (`next({ ...e, x })`)。command hook の Pre / Post の 2 event を 1 event で表す。何も返さないのは失敗
- `next` の持ち物: `next.event` (event 名)、`next.origin` (その dispatch を起こした plugin と tier。host が付け、plugin は偽れない)、`next.signal` (人の中断・上位の先着・予算切れで abort)、`next.is(pattern, e)` (glob hook での型の絞り込み)、`next.trace` (直近の `next()` の下で決着した link の一覧、近い順)、`next.budget` (`{ ms, remainingMs }`)、`next.to(e, tier)` (間の tier を飛ばして続ける。`prepend` / `append` の plugin だけが使え、自分より権限の強い tier は飛ばせない)
- event は `$` のメソッド呼び出しそのもの。engine も `$.prompt.submit` / `$.tool.call` / `$.ui.render` を呼んで動いており、他 plugin の `$` 呼び出しも hook できる。`$` から raise した chain では呼んだ hook 自身だけが飛ばされる (同じ plugin の他の hook は通る)

## 失敗と `.catch`

- 失敗 (throw・予算超過・その site が受け付けない形の答え・worker の終了) した hook は飛ばされ、下の hook と core が代わりに走る (`next` を呼んでいれば最後の結果が残る)。transcript に dim の 1 行、`claude --debug` に全件が出る
- つまり拒否する guard は既定で fail open。`on(...)` の戻り値 (Registration) に 1 つだけ `.catch(handler)` を付けると、失敗時にその答えが hook の結果になる。型定義と built-in の定型:

```ts
on('tool.call', { tool: 'Bash' }, guard)
  .catch(($, e, next) => next.called ? next(e) : { deny: 'guard failed' })
on('tool.check', guard).catch(() => ({ decision: 'deny' }))   // 何も走っていないので deny に倒す
```

- handler の `next` は `next.error` (`kind`: `throw` / `timeout` / `re-entry`、`message?`、`budget`) と `next.called` (失敗前に `next` を呼んだか) を持ち、replay-safe (`called` なら `next(e)` は最後の結果を返し、下は再実行されない)。handler の猶予は 1 秒 (`HookBudget.catchMs`)。`re-entry` (自分の `$` 呼び出しの下で同じ event が上がり hook が走らなかった) の時も handler が代わりに答え、その中の `$` 呼び出しは reject される
- `.catch` を 2 つ付ける・`register` が返った後に付ける・`engine.create` に付けるのは throw
- `claude plugin validate` は gating site (答えで拒否できる event) の hook を `.catch` の有無付きで列挙する

## 実行環境

- DOM も Node も無い専用環境。globals は `h` / `Fragment` / JSX と web API の一部 (`URL` / `URLSearchParams` / `TextEncoder` / `TextDecoder` / `AbortController` / `AbortSignal` / `atob` / `btoa` / `structuredClone` / `crypto.subtle.digest` / `crypto.randomUUID` / `crypto.getRandomValues` / `performance.now`) だけ。timer (`setTimeout` 等) は無く `$.clock` で待つ。`eval` / `new Function` は throw し、`WebAssembly` は無い (compiled code は `$.process.run` の子で動かす)。`console` は hooks module に無い (Client の surface module にはある)。ファイル・ネットワーク・プロセスへは `$` を通してだけ届く
- built-in mod は `native`、`--plugin-dir` やインストールした mod は `worker` で読まれる (実測: debug の `hooks module <name>@inline loaded (worker, environment 1, tier user)`)
- module 変数は reload で消える。`$.state` (session 単位) と `$.store` (session を跨ぐ) は host が持ち reload を跨ぐ
- 時間予算 (`HookBudget`): hook 1 回あたり 10 秒 (`ms`)、`.catch` の猶予 1 秒 (`catchMs`)、`next.signal` の abort 後に走り続けてよい 5 秒 (`lingerMs`、超えると lingering と報告)。数えるのは hook 自身のコードの時間だけで、`next(e)` と `$` 呼び出しの待ちは数えない (`$.clock.sleep` は数える)。streaming event (`turn.step` / `process.spawn`) の generator は自分のコードが走る間だけ数える。`session.end` だけは chain 全体で 1 本の wall-clock 予算 (既定 1.5 秒) を共有し、`$` の待ちも数える。`engine.create` に予算は無い
- dispatch を越えて続く仕事は `session.start` から `$.clock.every` / `$.process.spawn` 等で回す。built-in `diff` は `session.start` の hook の `$` を closure で掴んだ関数群を作り、timer や他の hook からそれを呼ぶ

## security モデル

- `claude plugin validate` が module のソースを静的に走査し、hook する pattern・`$` の呼び出し (`noun.method`)・`$.env` で読み書きする変数名・`$.state` で読み書きする `{ plugin, key }` を列挙する。同じ走査結果が `plugin.register` の `e.uses` (`events` / `calls` / `env` / `state`) になる。走査に現れない呼び出しは実行時に host が拒む (`refused: its hooks module does not spell (...`)。`on` / `$` / `$.env` の変数名 / `$.state` の参照はリテラルで書く (`$.state` の family の `id` だけは計算してよい)
- 組織の制御は並び順そのもの。外側の plugin が `plugin.register` で他 plugin の読み込みを拒み (`{ refuse }`)、`engine.create` で noun を足す・(`user` tier 以外は) 差し止め、`*` で監査する
- 限界: `$.process.run` の子は `$` の外で user 権限の何でもできる。`calls` に `process.run` が出る mod は実質任意コマンドを走らせうる。`$` 経由の一元化は追跡のためで、sandbox ではない。sandbox 下の shell コマンドは `--plugin-dir` のフォルダに書けない (そこにある code は sandbox の外で reload・実行されるため)
- 読み込まれない条件: workspace が未 trust (`hooks modules not loaded until workspace trust is accepted`。built-in も含む)、safe mode、`--bare` (managed 以外)、`disableAllHooks` / `allowManagedHooksOnly` / policy、`sec-default` の `allowManagedModsOnly`。`-p` は未 trust の cwd でも trust 確認なしで読む (実測)。remote で off にされた installed mod は turn の合間に unload される

### built-in `sec-default` (組織の既定の守り)

managed settings か managed-mcp.json のある機械、または Team / Enterprise の組織で、prepend tier の先頭に座る (managed `prependPlugins` があればその列が prepend tier の全部で、`sec-default@builtin` を入れる位置も組織が決める)。自前の方針は足さず、組織が既に持つ制御を user tier の plugin から守る。手は 3 つだけ: user tier を飛ばして続ける (`next.to(e, 'append')`)、user tier の呼び手・module を名指しで拒む、素通し。

| user tier の hook が飛ばされる (組織側と engine の答えが立つ) | 条件付き |
|---|---|
| `classic.*`、`prompt.section` / `prompt.context` / `prompt.attachment` / `prompt.compose`、`skill.prompt`、`attribution.text`、`session.compact`、`settings.read` | `session.append` (door `attachment` / `hook-context` / `compaction`、Skill tool の `tool-message`、組織の plugin の `note`)。`tool.describe` / `command.describe` / `agent.offer` / `agent.spawn` (対象の `e.provider.tier` が `prepend` / `append` の時)。`ui.log` / `env.get` / `env.set` (呼び手が組織の plugin の時) |

- `tool.check`: user tier の hook が判定を緩めた・言い換えた時、user tier 抜きで再実行し、deny と「rule / classic hook / setting / 組織の ceiling / host が後ろにある ask」はその答えに戻す (`next.trace` で書き換えを検出)。transcript に `<plugin> tried to lift a deny rule ...` が出る。managed の `allowModsToOverrideDenyRules: true` で解除
- `tool.register`: managed `allowedMcpServers` がある間は user tier の登録を拒む。無くても組織の MCP server・組織が座らせた plugin の名前に読める tool 名は拒む
- `env.set`: managed `env` が設定する変数、`CLAUDE_CONFIG_DIR` 等の policy・sign-in の読み先を動かす 9 変数、`LD_PRELOAD` / `DYLD_INSERT_LIBRARIES` / `BASH_ENV` / `NODE_OPTIONS` 等の 10 変数への user tier の書き込みを拒む
- `plugin.register`: managed settings の `pluginConfigs["cc-plugin-sec-default@builtin"].options.allowManagedModsOnly` が立っていると user tier の module (install したもの・`--plugin-dir`・mods フォルダのもの) を全部拒む
- validate と `/plugin` は「組織が管理する環境で飛ばされる mod の hook」を名指す注記を出す (CHANGELOG)。対象はこの表と対応すると読めるが、注記の実物は未確認

## 既存の拡張機構との差分

| 観点 | command hook | Mod (function hook) | MCP server | skill |
|---|---|---|---|---|
| 実体 | shell コマンド。stdin に JSON、stdout / exit code で返答 | hooks.json が名指す TS / JS module | 別プロセスの tool / resource server | model が読む手順書 |
| 動く場所 | event ごとの子プロセス | engine 内の専用環境 | 別プロセス | model の context |
| 外界への到達 | user 権限の shell で何でも | `$` 経由だけ (`$.process` で任意コマンドは可) | 何でも | model の tool 経由 |
| 前後の扱い | Pre / Post の別 event | 1 event で before / after / during / instead / modifying | — | — |
| 合成 | 並列、結果を fold | 登録順の入れ子 (外側が強い) | — | — |
| 描画 | 無し | `ui.render` で engine の component を書き換え、pane / status / toast | 無し | 無し |
| model への tool 提供 | 無し | `$.tool.register` (`mcp__<plugin>__<name>`) | 本業 | 無し |
| 状態 | 自前 | `$.state` / `$.store` | 自前 | 無し |
| 観測範囲 | 定義済み event のみ | engine の全 event と他 plugin の `$` 呼び出し。command hook の event も `classic.<Event>` で | 自分への呼び出し | — |
| 静的な宣言 | 無し | validate の列挙に実行時も縛られる | — | — |

command hook の event を Mod から取る時は `classic.<Event>` (`classic.PreToolUse` / `classic.PermissionRequest` / `classic.Stop` / `classic.SessionEnd` ...) を hook する。settings hook を 1 つも設定していなくても、engine がその classic hook を走らせる地点で必ず発火する。

- `e` は command hook が stdin で受け取るものと同じ (`session_id` / `transcript_path` / `cwd` / `permission_mode` / `hook_event_name` ... を含む)
- 例外は `classic.PreToolUse` で、`e` は stdin 形ではなく `tool.call` と同じ envelope (`ToolCallEnvelope`: `tool` / `tool_use_id` / tool の引数を平たく展開。`tool.call` の `agentId` / `requestMeta` は含まない)。結果も `allow` / `ask` / `deny` / `updatedInput` / `additionalContext` の形
- chain は「managed settings の hook → hooks module → 他の settings hook (core)」。下の settings hook の答えは 1 つに fold され (後勝ち、`additionalContext` は連結)、mod は `next(e)` の結果・欄を変えたコピー・自前の答えを返す。形の違う欄は hook の失敗

## 2026-10-14 時点の未確認

- `modules` を含む hooks.json を Mods 非対応の古い build が丸ごと捨てるか (二次資料の主張)。任意の版に配る plugin に `modules` を足す前に確かめる
- `$.process.run` の子プロセスの親 pid (worker か engine 本体か)
- `sec-default` README が user tier の module の置き場として挙げる「mods フォルダ」の場所 (skill `plugin-authoring` の `dev-mods/<sessionId>` を指すのか)

## 一次資料

- anthropics/claude-code の `mods/` (README、built-in mod `sec-default` / `diff` / `telemetry` / `agents-md` のソースと README とテスト、型定義 `mods/types/claude-code.d.ts`) と `CHANGELOG.md`
- engine が mod の横に書き出す `.claude-plugin/types/claude-code/index.d.ts` (1 行目が書き出した版)
- binary 同梱の skill `plugin-authoring` の SKILL.md と reference.md
- anthropics/claude-code#91870 と添付 PDF "Function Hooks: Core Architecture"
- 調査と実験の全記録: kawaz/ccmsg の docs/research/2026-09-28-claude-mods-for-driving-claude.md と docs/findings/2026-09-29-claude-mods-experiments.md
