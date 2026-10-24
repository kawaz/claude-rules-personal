# Claude Mods の開発ループ

一時読み込み、validate / test / hot-reload / 型定義の書き出し。Claude Code 2.1.299 の型定義と公式リポの `mods/` (README と built-in mod のテスト)、skill `plugin-authoring`、実機による。隔離環境での起動手順は reference の `claude-mods/lab-setup`。

## 読み込み

- built-in mod: `sec-default` (組織の機械でだけ最外に座る。reference の `claude-mods/overview`)、`diff` (`/diff` の pane)、`telemetry` (built-in plugin の analytics。analytics が有効な build だけ)、`agents-md` (`AGENTS.md` を instruction file として読む。option `instructionFiles`)、`cc-plugin-you-should-know` (side agent が見落としを指摘する。`/plugin enable cc-plugin-you-should-know@builtin`、first-party でかつ telemetry 有効の session)。ソースは anthropics/claude-code の `mods/` に build と同じ形で公開されていて、`claude --plugin-dir mods/diff` でソースから読める
- 一時読み込み: `claude --plugin-dir <folder>` (session 限り、複数可、folder of plugins も可)、`CLAUDE_CODE_PLUGIN_DIRS` (プロセス環境か user settings の `env`)。読めなかった `--plugin-dir` は stream-json の `system/init` の `plugin_errors` に `path` 付きで出る
- `claude plugin init` は command hook 型の雛形を作るもので、mod の雛形ではない

## validate

`claude plugin validate <dir>` は manifest と hooks module のソースを engine と同じ読み方で読み、session に読み込む前に次を出す。

- hook する pattern (matcher 付き)、`calls` (`noun.method`、どの関数経由か付き)、`$.env` の読み書き、`$.state` の読み書き
- gating site (答えで拒否できる event) の hook ごとの `.catch` の有無 (`--json` では `gatingHooks`)
- 組織が管理する環境で飛ばされる hook の注記 (`/plugin` にも出る)
- engine が拒むもの全部。拒否理由は行と原因と直し方を名指す (例: top-level の `var` を再宣言・再代入して `$.state` の参照を読んでいる module、`PluginState` に宣言していない `$.state` の key、matcher なしの同じ pattern の重複登録、`$` を top-level 以外の関数へ引数で渡す module。後の 3 つの文言は reference の `claude-mods/overview`)
- README に install の 1 行が無い時は貼る行を助言する。exit code は変えない (`--strict` でも)

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

- `--plugin-dir` の folder は対話 session で watch され、保存で reload する (実測 `reloaded in 5.7ms`)。中身が変わらない保存では reload しない。reload で `register` と `session.start` が再度走り、`$.state` は残る (reference の `claude-mods/events`)。headless の長寿命 session は `CLAUDE_CODE_PLUGIN_DIR_WATCH=1`
- watch は idle 時 30 秒、active 時 400ms の polling なので、idle 中の保存は反映まで最大 30 秒程度かかる (実測)
- skill `plugin-authoring` 経由の開発では `$CLAUDE_CONFIG_DIR/dev-mods/<sessionId>` が作業場所になる (skill 本文の placeholder `${CLAUDE_DEV_MODS_DIR}` が置換される。環境変数ではない)。最初の書き込みで「Enable mod hot-reloading for this session?」を 1 度訊く。この同意は人だけが答え、permission mode・rule・hook では答えられない。SDK host が答える前に閉じた場合は 3 回まで訊き直す。accept-edits mode でも、この mods フォルダに mod を作る Write / Edit は確認を挟む
- skill `plugin-authoring` は作った mod を他人が install する 1 行のコマンドを示して README の install 節に書き、共有時は public / private を訊いてファイルを確かめてから GitHub リポを作る

## 型定義

- engine は人が所有するフォルダから mod を読み込むたびに `.claude-plugin/types/` と tsconfig を書く (中身は reference の `claude-mods/overview`)。`/plugin-types [dir]` でも書き出せる
- 自前で tsconfig を書くなら型定義冒頭の推奨: `"target": "es2023", "lib": ["es2023"], "types": [], "module": "esnext", "moduleResolution": "bundler", "strict": true, "noUncheckedIndexedAccess": true, "noEmit": true, "skipLibCheck": true, "jsx": "react", "jsxFactory": "h", "jsxFragmentFactory": "Fragment"`、`"include": [".claude-plugin/types", "hooks", "types", "tests"]`。`lib` に DOM を入れない (DOM の `Text` が要素の `Text` を隠す)
- `.js` module の型付けは `/** @type {import('claude-code').Register} */ export const register = (on, options) => { ... }`

## noun の契約 (mod 同士の合成)

- `engine.create` で `$` に noun を足す mod は、その型を `types/index.d.ts` 1 か所に持つ: import の無い宣言ファイルで、noun 名 (PascalCase) で始まる型を export し、`declare module 'claude-code' { interface EngineInterface { <noun>: <Type> } }` で宣言する。自分の hooks はそこから import し、`engine.create` が返す値は `EngineInterface['<noun>']` で検査される
- 他 mod の noun を呼ぶ mod は契約を写さず読む: `plugin.json` の `"dependencies"` に挙げると engine がその契約を `.claude-plugin/types/` に置く (公式リポでは `mods/tsconfig.json` の include で読む)
- noun を呼ぶ mod の test は provider (`engine.create` で noun を足す inline plugin) を `plugins` で座らせ、`on('<noun>.<method>', ...)` で答える。provider が無いと `$` の build が「誰も提供しない noun」を名指して hook を拒む
- served `$` method (plugin が足した noun の method) は、呼んだ agent の cwd で走る
