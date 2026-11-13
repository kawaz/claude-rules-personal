# Claude Mods の開発ループ

一時読み込み、validate / test / hot-reload / 型定義の書き出し。Claude Code 2.1.299 の型定義と公式リポの `mods/` (README と built-in mod のテスト)、skill `plugin-authoring`、実機による (読み込み・hot-reload の mode ごとの挙動は 2.1.321)。隔離環境での起動手順は reference の `claude-mods/lab-setup`。

## 読み込み

- built-in mod: `sec-default` (組織の機械でだけ最外に座る。reference の `claude-mods/overview`)、`diff` (`/diff` の pane)、`telemetry` (built-in plugin の analytics。analytics が有効な build だけ)、`agents-md` (`AGENTS.md` を instruction file として読む。option `instructionFiles`)、`cc-plugin-you-should-know` (side agent が見落としを指摘する。`/plugin enable cc-plugin-you-should-know@builtin`、first-party でかつ telemetry 有効の session)。ソースは anthropics/claude-code の `mods/` に build と同じ形で公開されていて、`claude --plugin-dir mods/diff` でソースから読める
- skills-dir: project の `.claude/skills/<name>/` か user の `$CLAUDE_CONFIG_DIR/skills/<name>/` に `.claude-plugin/plugin.json` と hooks module を置くと `<name>@skills-dir` として読まれる (debug log `Loaded 1 skills-as-plugins`)。project の分は未 trust の cwd では `-p` でも読まれない (2.1.321 で 1 回)
- 一時読み込み: `claude --plugin-dir <folder>` (session 限り、複数可、folder of plugins も可)、`CLAUDE_CODE_PLUGIN_DIRS` (プロセス環境か user settings の `env`)。読めなかった `--plugin-dir` は stream-json の `system/init` の `plugin_errors` に `path` 付きで出る
- `claude plugin init` は command hook 型の雛形を作るもので、mod の雛形ではない
- `plugin.json` の `engines["claude-code"]` (版の範囲) が効くのは cache に複製して install する経路 (git の url source 等) だけ (2.1.323 で実測):
  - 範囲外の install は止まる (rc=1、`"<name>" was not installed: it needs Claude Code >=9.0.0, this is 2.1.323.` に続けて、下限で外れた時は `claude update` を、上限で外れた時は `A newer version of the plugin may fit.` を促す)
  - 範囲外になった install 済みの plugin は読まれず、`claude plugin list` に `Status: ⚠ not loaded` と `Error: Plugin "<name>" not loaded: needs Claude Code ...`、`-p` の `system/init` の `plugin_errors` に `{"type": "engine-range-unsatisfied", ...}` が出る
  - local folder の marketplace からの install は範囲外でも成功して読まれる (install 時と `claude plugin list` に `Note: "<name>" needs Claude Code >=9.0.0, this is 2.1.323, but loads anyway because it's read from a local folder`)
  - `--plugin-dir` は範囲外・不正な範囲でも黙って読む (debug log・`plugin_errors`・stderr に何も出ない)

## validate

`claude plugin validate <dir>` は manifest と hooks module のソースを engine と同じ読み方で読み、session に読み込む前に次を出す。

- hook する pattern (matcher 付き)、`calls` (`noun.method`、どの関数経由か付き)、`$.env` の読み書き、`$.state` の読み書き
- gating site (答えで拒否できる event) の hook ごとの `.catch` の有無 (`--json` では `gatingHooks`)
- 組織が管理する環境で飛ばされる hook の注記 (`/plugin` にも出る)
- engine が拒むもの全部。拒否理由は行と原因と直し方を名指す (例: top-level の `var` を再宣言・再代入して `$.state` の参照を読んでいる module、`PluginState` に宣言していない `$.state` の key、matcher なしの同じ pattern の重複登録、`$` を top-level 以外の関数へ引数で渡す module。後の 3 つの文言は reference の `claude-mods/overview`)
- README に install の 1 行が無い時は貼る行を助言する。exit code は変えない (`--strict` でも)
- `.ts` の module を `claude-code` の型で検査し、型エラーを警告で出す (`line 4, column 7: error TS2322: Type 'string' is not assignable to type 'number'.`。`$` の method の引数の型違い (`TS2345`) や `e` に無い欄 (`TS2339`) も型名付きで出る)。警告だけなら rc=0 で、`--strict` で rc=1。`--json` では `contents[]` の module の `warnings` に `{ path: "line 8, column 14", message: "error TS2345: ...", code: null }` で入り `success: true`。mod 側に tsconfig も `.claude-plugin/types/` も無くても型は解決され、validate は mod のフォルダにファイルを書かない。`.js` の module は JSDoc で型を付けても検査されない (2.1.323 で実測)
- `engine.create` の hook ごとに `$` へ何をするかを列挙する: `adds to $: <noun>` / `withholds from $: <noun>` / `replaces on $: <noun>`。user tier で core の noun を差し止める・置き換えるものには `(the fold refuses this and unloads the module)` が付く。hook が validate の受け付ける形 (reference の `claude-mods/capabilities` の `engine.create` 行) を外れると `this engine.create hook is outside its form: ...` (`clock both withheld and written`、`a return that is not the one last statement of the hook's body`、`bound with let or var (const only)`、`the value of next(e) at engine.create is passed as an argument` 等) で失敗する。validate で落ちても読み込みは止まらない (最後以外の `return` を持つ hook は `--plugin-dir` でも git の marketplace からの install でも読まれ、noun が足された)。`*` / `engine.*` の hook には `adds to $` が出ない (2.1.323 で実測)
- `plugin.json` の `engines: { "claude-code": "<範囲>" }` は、範囲の書式だけを検査する (範囲外でも何も言わない。`"not a range"` は error `Must be a version range such as ">=2.1.0"; ...`、rc=1)。効き方は下の「読み込み」 (2.1.323 で実測)

## test

`claude plugin test [dir]` は plugin の `*.test.ts(x)` を、hooks と同じ種類の環境 (fs・network・process 無し) で engine 自身の host に plugin を読ませて走らせる。

```ts
import { describe, expect, mock, test, tier } from 'claude-code/testing'

tier('builtin')   // 読み込む tier。省略は user

describe('register', () => {
  test('outside a git repository /diff says so', async ($, on) => {
    mock.clock(on)
    on('process.run', () => ({ value: { exitCode: 128, stdout: '', stderr: 'fatal: not a git repository' } }))
    await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' })
    const { text } = await $.command.run({ command: 'diff', args: '', origin: { kind: 'composer' } })
    expect(text).toContain("isn't in a git repository")
  })
})
```

- `$` は engine 自身のもので、呼び出しは出荷時の形で読まれた mod の全 hook を通る。test の `on` で登録した hook は全 plugin の下 (外界の位置) に座り、その下には何も無い。誰も答えない呼び出しは event 名付きで throw する。test は最初の `$` 呼び出しの前に hook を登録する
- `$.session.start(...)` を呼ぶ test は、test の側で `on('session.start', ($, e) => ({ cwd: e.cwd }))` を登録して core の代わりに答えさせる。無いと `HooksError: no implementation for session.start` で失敗する (実測: 2.1.308 / 2.1.309)
- `mock` は外界を noun ごとに memory で答える: `mock.clock(on)` (`advance(ms)` / `set(ms)` / `settle()` / `sleep(ms)`。待ちは時計が越えた時だけ解ける)、`mock.store(on, entries)`、`mock.env(on, variables)`、`mock.session(on)` (`$.session.append` された行を `appended()` で読む)
- `test(name, { plugins, timeoutMs, options }, body)`: `plugins` は inline plugin を横に読む (他 mod の noun の provider 等)、`timeoutMs` の既定は 5000、`options` は対象 plugin の `userConfig` の値 (省略は manifest の既定値)
- `$.ui.mount({ plugin, surface, ... })` は component を指定 surface で描き、要素の検索・press・input・key・pointer を key で行う。`$.ui.press({ plugin, key })` は描いた `Button` を押す。`$.classic.<Event>(fields)` は classic event を上げる (`classic.PreToolUse` は `$.tool.call` の中で上がる)
- test が失敗になるもの: hook の中で失敗した `expect`、engine が拒む stub の答え、10 秒以内に答えない served `$` method (plugin が足した noun の method)
- `ui.render` の tree は各 mod の Box / Text の root に `part: { plugin }` を持つ。tree 全体を `toEqual` で比べる時はそれも含める
- 公式リポの慣習: test file は `hooks/` の対象と同名 (`register.test.ts` ↔ `hooks/register.ts`)、1 file に `tier` と 1 つの `describe`、共有物は `tests/fixtures/` に 1 export 1 file。`tsc -p mods/tsconfig.json` で hooks と tests を型検査する

## hot-reload

- `--plugin-dir` の folder は対話 session で watch され、保存で reload する (実測 `reloaded in 5.7ms`)。中身が変わらない保存では reload しない。reload で `register` と `session.start` が再度走り、`$.state` は残る (reference の `claude-mods/events`)。headless の長寿命 session では `--plugin-dir` は watch されず、`CLAUDE_CODE_PLUGIN_DIR_WATCH=1` で watch する。skills-dir の mod (上の「読み込み」) は headless でも既定で watch され、保存の 1〜3 秒後に reload する (`<name>@skills-dir reloaded in ...`)。`=0` で止まる (2.1.321 で実測)
- watch は idle 時 30 秒、active 時 400ms の polling なので、idle 中の保存は反映まで最大 30 秒程度かかる (実測)
- skill `plugin-authoring` 経由の開発では `$CLAUDE_CONFIG_DIR/dev-mods/<sessionId>` が作業場所になる (skill 本文の placeholder `${CLAUDE_DEV_MODS_DIR}` が置換される。環境変数ではない)。mod を有効にするかは permission mode で決まる (2.1.321 で実測): bypassPermissions と auto では訊かずに有効になり (`Mods: In this permission mode the mods Claude writes turn on without asking.`、turn の終わりに読まれ、読み込みの通知で model がもう 1 turn 応える)、dontAsk では有効にならない (debug log `dev mods: mod hot-reloading is off here (dont_ask)`)。それ以外の mode は最初の書き込みで `Mods` の質問「Turn on the mods Claude writes in this session?」(How does this work? / Turn them on / Not now) を 1 度訊き、人だけが答えられる (rule・hook では答えられない。default で訊くことはコードの読み取りで、2.1.321 の実機では未確認)。SDK host が答える前に閉じた場合は 3 回まで訊き直す。起動時にそのフォルダに既に置いてある mod は、同じ session id で起動すると訊かずに読まれる (dontAsk を除く)。accept-edits mode でも、この mods フォルダに mod を作る Write / Edit は確認を挟む
- skill `plugin-authoring` は作った mod を他人が install する 1 行のコマンドを示して README の install 節に書き、共有時は public / private を訊いてファイルを確かめてから GitHub リポを作る

## 型定義

- engine は人が所有するフォルダから mod を読み込むたびに `.claude-plugin/types/` と tsconfig を書く (中身は reference の `claude-mods/overview`)。`/plugin-types [dir]` でも書き出せる
- 自前で tsconfig を書くなら型定義冒頭の推奨: `"target": "es2023", "lib": ["es2023"], "types": [], "module": "esnext", "moduleResolution": "bundler", "strict": true, "noUncheckedIndexedAccess": true, "noEmit": true, "skipLibCheck": true, "jsx": "react", "jsxFactory": "h", "jsxFragmentFactory": "Fragment"`、`"include": [".claude-plugin/types", "hooks", "types", "tests"]`。`lib` に DOM を入れない (DOM の `Text` が要素の `Text` を隠す)
- `.js` module の型付けは `/** @type {import('claude-code').Register} */ export const register = (on, options) => { ... }`

## noun の契約 (mod 同士の合成)

- `engine.create` で `$` に noun を足す mod は、その型を `types/index.d.ts` 1 か所に持つ: import の無い宣言ファイルで、noun 名 (PascalCase) で始まる型を export し、`declare module 'claude-code' { interface EngineInterface { <noun>: <Type> } }` で宣言する。自分の hooks はそこから import し、`engine.create` が返す noun の値は `EngineInterface['<noun>']` で検査される。hook は `on('engine.create', ...)` と名前で書き、`const { ...beneath } = await next(e)` → return しない文 → 最後の 1 文で `return { ...beneath, <noun>: ... }` の形にする (validate が受け付ける唯一の形。reference の `claude-mods/capabilities` の `engine.create` 行)
- 他 mod の noun を呼ぶ mod は契約を写さず読む: `plugin.json` の `"dependencies"` に挙げると engine がその契約を `.claude-plugin/types/` に置く (公式リポでは `mods/tsconfig.json` の include で読む)
- noun を呼ぶ mod の test は provider (`engine.create` で noun を足す inline plugin) を `plugins` で座らせ、`on('<noun>.<method>', ...)` で答える。provider が無いと `$` の build が「誰も提供しない noun」を名指して hook を拒む
- served `$` method (plugin が足した noun の method) は、呼んだ agent の cwd で走る
