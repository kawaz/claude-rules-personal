# Claude Mods の有効化と開発ループ

mod を読ませる条件、一時読み込み、validate / test / hot-reload / 型定義の書き出し。Claude Code 2.1.283 の skill `plugin-authoring` と型定義、2.1.284 の実機による。隔離環境での起動手順は reference の `claude-mods/lab-setup`。

## 有効化

- built-in mod (`sec-default` / `diff` / `telemetry` / `agents-md`) は常に読まれる
- インストール物と `--plugin-dir` の module は、プロセス環境に `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` があるか、GrowthBook の `tengu_plugin_hooks_modules` が true の時だけ読まれる。flag なしでは debug に `hooks modules are not turned on for installed plugins in this process` と出る
- skill `plugin-authoring` も同じ判定で見える / 見えない
- 一時読み込み: `claude --plugin-dir <folder>` (session 限り、複数可、folder of plugins も可)、`CLAUDE_CODE_PLUGIN_DIRS` (プロセス環境か user settings の `env`)
- `claude plugin init` は command hook 型の雛形を作るもので、mod の雛形ではない

## 開発ループ

- `claude plugin validate <dir>`: flag 無しで動く。hook する event (matcher 付き)、`calls` (どの関数経由か付き)、env の読み書きを出す
- `claude plugin test [dir]`: `*.test.ts(x)` を engine 自身に対して走らせる (`import ... from 'claude-code/testing'`、`mock.clock` / `mock.store` / `mock.env`、`$.ui.mount`)。flag 必須の隠しサブコマンド
- hot-reload: `--plugin-dir` の folder は対話 session で watch され、保存で reload する (`reloaded in 5.7ms`)。watch は idle 時 30 秒、active 時 400ms の polling なので、idle 中の保存は反映まで最大 30 秒程度かかる。reload で `register` と `session.start` が再度走る。headless の長寿命 session は `CLAUDE_CODE_PLUGIN_DIR_WATCH=1`
- skill `plugin-authoring` 経由の開発では `$CLAUDE_CONFIG_DIR/dev-mods/<sessionId>` が作業場所になる (skill 本文の placeholder `${CLAUDE_DEV_MODS_DIR}` が置換される。環境変数ではない)。最初の書き込みで「Enable mod hot-reloading for this session?」を 1 度訊く。この同意は人だけが答え、permission mode・rule・hook では答えられない
- `/plugin-types [dir]` が型定義 (`claude-code.d.ts`、有効 plugin の契約、接続中 MCP tool の入力型) を書き出す
