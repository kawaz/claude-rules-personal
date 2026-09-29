# Claude Mods の立て付け

Claude Mods は Claude Code の plugin が持てる 5 種目の hook (function hook)。plugin という配布・発見の単位はそのままで、`hooks/hooks.json` に command / prompt / agent / http と並んで TypeScript / JavaScript のモジュールを名指しする。記述の根拠は Claude Code 2.1.283 同梱の skill `plugin-authoring` と型定義 `claude-code.d.ts`、2.1.284 での実機観測。early access で、版が進むと変わりうる。読ませる条件と開発ループは reference の `claude-mods/develop`。

## plugin の形 (3 ファイル)

```text
<mod>/
  .claude-plugin/plugin.json   { "name": "<mod-name>", "version": "0.1.0", "description": "<one line>" }
  hooks/hooks.json             { "modules": ["./register.ts"] }   (hooks.json からの相対、1 plugin 1 module)
  hooks/register.ts            register(on, options) を export する
```

- `$.state` を型付きで使うなら `types/index.d.ts` に `interface PluginState` を宣言し、`plugin.json` の `"types"` で名指しする
- 拡張子は `.ts .tsx .jsx .js .mjs .cjs .mts .cts`。どれも ES module で `require` は無い。JSX は global の `h` / `Fragment` に対してコンパイルされ、要素 (`Box` / `Text` / `Button` ...) は `$.ui.resolve(e)` で描画面ごとに取る
- `options` は manifest の `userConfig` の値。`userConfig` が無いと debug に `options requested but its manifest declares no userConfig` と出て全部 absent になる
- 同じ hooks.json の command hook 等の entry は module と並走する
- 読み込み時に engine が mod のディレクトリへ `.claude-plugin/types/` と `tsconfig.json` を書く (型の置き場)

## hook の形

```ts
export function register(on) {
  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    // before
    const r = await next(e)   // 下の plugin と engine 自身の動作
    // after
    return r
  })
}
```

- `on(event, matcher?, hook)`、hook は `($, e, next)`。`$` は engine への唯一の口 (`$.noun.method(...)`)、`e` はその event の入力 (凍結された plain value)、`next(e)` は下の hook と engine の既定動作を走らせて結果を返す
- Koa 流の入れ子。`on(X, A), on(X, B)` は `A(B(core))` で、先に登録した側が外側 (強い)。plugin 間の並びは tier `prepend` (管理者) → `user` (人が入れたもの) → `builtin` → `append` (管理者) → `core` (engine 最内)
- 1 つの hook で置き方を選ぶ: before (`...; return next(e)`)、after (`await next(e)` の後)、during (`const p = next(e)` を走らせたまま別の契機を待つ)、instead (`next` を呼ばずに `{ deny }` / `{ result }` 等を返す)、modifying (`next({ ...e, x })`)。command hook の Pre / Post の 2 event を 1 event で表す
- `next` は `next.event` (event 名)、`next.origin` (その event を起こした plugin と tier)、`next.signal` (人の中断・上位の先着・予算切れで abort)、`next.is(type, e)` を持つ
- event は `$` のメソッド呼び出しそのもの。engine も `$.prompt.submit` / `$.tool.call` / `$.ui.render` を呼んで動いており、他 plugin の `$` 呼び出しも hook できる。`on('*')` は全 event を見る (自分のフレームには再入しない)
- 失敗した hook は飛ばされ chain は続く。transcript に dim の 1 行、`claude --debug` に全件が出る

## 実行環境

- DOM も Node も無い専用環境。globals は web API (`URL` / `TextEncoder` / `AbortController` / `crypto.subtle` ...) と `h` / `Fragment`。ファイル・ネットワーク・プロセスへは `$` を通してだけ届く
- built-in mod は `native`、`--plugin-dir` やインストールした mod は `worker` で読まれる (debug の `hooks module <name>@inline loaded (worker, environment 1, tier user)`)
- module 変数は reload で消える。`$.state` (session 単位) と `$.store` (session を跨ぐ) は host が持ち reload を跨ぐ
- 時間予算は hook 1 回あたり 10 秒 (`HookBudget`)。数えるのは hook 自身のコードの時間だけで、`next(e)` と `$` 呼び出しの待ちは数えない (`$.clock.sleep` は数える)。dispatch を越えて続く仕事は `session.start` から `$.clock.every` / `$.process.spawn` 等で回す

## security モデル

- `claude plugin validate` が module のソースを静的に走査し、hook する event・`$` の呼び出し・`$.env` で読み書きする変数名を列挙する。走査に現れない呼び出しは実行時に host が拒む (`refused: its hooks module does not spell (...`)。`$.env` の変数名と `$.state` の `plugin` / `key` は文字列リテラル必須
- 組織の制御は並び順そのもの。最外の plugin が `plugin.register` で他 plugin の読み込みを拒み、`engine.create` で noun を絞り、`*` で監査する。built-in の `sec-default` が managed settings のある機械で最外に座る
- 限界: `$.process.run` の子は `$` の外で user 権限の何でもできる。`calls` に `process.run` が出る mod は実質任意コマンドを走らせうる。`$` 経由の一元化は追跡のためで、sandbox ではない
- 読み込まれない条件: workspace が未 trust (`hooks modules not loaded until workspace trust is accepted`。built-in も含む)、safe mode、`--bare` (managed 以外)、`disableAllHooks` / `allowManagedHooksOnly` / policy。`-p` は未 trust の cwd でも trust 確認なしで読む

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
| 有効化 | 常時 | built-in は常時、他は flag か rollout | 常時 | 常時 |

command hook の event を Mod から取る時は `classic.<Event>` (`classic.PreToolUse` / `classic.PermissionRequest` / `classic.Stop` / `classic.SessionEnd` ...) を hook する。`e` は command hook が stdin で受け取るものと同じ (`session_id` / `transcript_path` / `cwd` / `permission_mode` / `hook_event_name` ... を含む)。

## 2026-09-29 時点の未確認

- `modules` を含む hooks.json を Mods 非対応の古い build が丸ごと捨てるか (二次資料の主張)。任意の版に配る plugin に `modules` を足す前に確かめる
- 1 plugin が command hook と module を併せ持つ時、flag なしの環境で command hook 側が変わらず動くか
- `$.store` の保存先が `CLAUDE_CONFIG_DIR` に従うか (型定義は「user の Claude Code 設定ディレクトリの下の JSON」、二次資料は `~/.claude/plugins/store/`)
- `$.process.run` の子プロセスの親 pid (worker か engine 本体か)
- flag 不要化 (正式出荷) の時期と、その時点の API 差分

## 一次資料

- anthropics/claude-code#91870 と添付 PDF "Function Hooks: Core Architecture"
- anthropics/claude-code の `mods/` (README と built-in mod のソース、型定義 `mods/types/claude-code.d.ts`)
- binary 同梱の skill `plugin-authoring` の SKILL.md と reference.md、型定義 (`strings` と binary 内 zstd frame の展開で取れる)
- 調査と実験の全記録: kawaz/ccmsg の docs/research/2026-09-28-claude-mods-for-driving-claude.md と docs/findings/2026-09-29-claude-mods-experiments.md
