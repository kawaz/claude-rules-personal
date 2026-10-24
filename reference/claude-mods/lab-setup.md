# Claude Mods の隔離実験環境

普段使いの session・インストール済み plugin・常駐ツールを巻き込まずに mod を試す手順と、観測用のリソース。Claude Code 2.1.284 で実際に回した構成。

## 隔離の要点

- **別の `CLAUDE_CONFIG_DIR`** を作る (`/tmp/mods-lab/config-a` 等)。インストール済み plugin・settings の hook・session 一覧が普段の環境から切り離される。同じ config home の session 同士は SendMessage で届き合うので、送受信を試す時は 2 本目も同じ config home、届かないことを試す時は別の config home にする
- **既定の config home の場所をいじらない**。`~/.claude` を意図的に置き換えている環境 (regular file にしてある等) では、実験のためにディレクトリを作らない
- **`env -i` で最小の環境から起動する**。Claude Code の中から起動すると `CLAUDE_CODE_MESSAGING_SOCKET` / `CLAUDE_CODE_MESSAGING_TOKEN` / `CLAUDE_CODE_SESSION_ID` / `CLAUDECODE` が継承され、子の Claude Code が親の session を自分と取り違えうる
- **認証は起動コマンドの `--settings` に `apiKeyHelper` と `env.ANTHROPIC_BASE_URL` をセットで渡す**。ヘルパが返す鍵は gateway 用なので、BASE_URL も同じ gateway を指す必要がある。隔離 config の `settings.json` には認証の値を書かない。model の応答の中身が要らない実験は、下の「Messages API の代役」で認証そのものを使わずに回せる
- **messaging socket は隔離できない前提で扱う**。harness が作る socket は `/tmp/cc-socks/<pid>.sock` か `/tmp/cc-socks-<uid>/<pid>.sock` で、実セッションと同じ場所に並ぶ。2.1.299 の `env -i` 起動では `XDG_RUNTIME_DIR` / `CLAUDE_CODE_TMPDIR` / `TMPDIR` を作業ディレクトリに向けても `/tmp/cc-socks-<uid>/` に作られ、`TMPDIR` と `XDG_*_HOME` を向けた別の起動では `/tmp/cc-socks/` に作られた。どちらのディレクトリになるかの条件は切り分けていない。pid で区別できるので実害は無いが、後始末で消し忘れを探す時はこの 2 か所を見る。hyoui を使うなら `HYOUI_STATE_DIR` は作業ディレクトリに向ける
- **`--plugin-dir <mod>`** で mod を session 限りで読む
- **`--debug`** で `$CLAUDE_CONFIG_DIR/debug/<sessionId>.txt` に module の読み込み・reload・hook の所要時間が出る
- 安いモデル (`--model haiku`) で十分。ただし haiku は auto mode 非対応 (`auto mode disabled: model ... does not support auto mode`)

## 用意

```bash
LAB=/tmp/mods-lab
mkdir -p "$LAB/config-a" "$LAB/ws" && (cd "$LAB/ws" && git init -q)
cat > "$LAB/config-a/settings.json" <<'EOF'
{
  "crossSessionInbound": "accept"
}
EOF
chmod 600 "$LAB/config-a/settings.json"
cp -R <rules リポ>/reference/claude-mods/scripts/observe-mod "$LAB/mod"
claude plugin validate "$LAB/mod"
```

`crossSessionInbound: "accept"` は別 session からの配送を確認なしで受ける設定 (受信を試す時だけ要る)。認証は上記のとおり起動コマンドの `--settings` で渡す。

## 起動

対話 session は端末を操作できる道具の中で起動する (画面の dump とキー送出が要る)。hyoui でも tmux でも回る (tmux は 2.1.299 で実測)。tmux は `-S` で専用の socket を使い、普段の tmux server と分ける。

```bash
tmux -S /tmp/mods-lab/tmux.sock new-session -d -s mods-lab -x 160 -y 50 -c /tmp/mods-lab/ws \
  env -i HOME="$HOME" USER="$USER" PATH="$PATH" TERM=xterm-256color LANG=ja_JP.UTF-8 \
  CLAUDE_CONFIG_DIR=/tmp/mods-lab/config-a \
  MODS_LAB_DIR=/tmp/mods-lab/log \
  claude --plugin-dir /tmp/mods-lab/mod --debug --model haiku
tmux -S /tmp/mods-lab/tmux.sock capture-pane -p -t mods-lab              # 画面を見る
tmux -S /tmp/mods-lab/tmux.sock send-keys -t mods-lab -l "hello"         # 文を打つ
tmux -S /tmp/mods-lab/tmux.sock send-keys -t mods-lab Enter              # キーを送る
```

turn の終わりは、観測 mod の log に `turn.complete` の行が増えたことで待つ。

新しい config home の初回は、テーマ選択 (Enter)、Security notes (Enter)、workspace trust (既定選択は `No, exit` なので Down → Enter) の順にダイアログが出る。`hyoui input` で答える時、選択キーと Enter を同じ呼び出しで送ると確認画面で「No」が選ばれて終了することがある。選択を `hyoui screen dump` で確かめてから Enter を送る。

headless は同じ環境で `claude -p "<prompt>" --plugin-dir ... --debug --model haiku < /dev/null` を cwd で直接走らせる。stdin を `/dev/null` にしないと `no stdin data received in 3s` で 3 秒待つ。

## Messages API の代役

`ANTHROPIC_BASE_URL` を手元の小さな HTTP server に向けると、認証も model の応答も無しに turn と compaction が回り、「model に届いたか」を request の body に印の文字列があるかで判定できる (2.1.299 で実測した構成)。first-party の API に送る request と同じ形かは確かめていない。

- 起動時に来る request は `HEAD /api/hello`、`GET /v1/models?limit=1000`、`POST /v1/messages?beta=true` の 3 種。全 request の body を jsonl に記録する。`/v1/models` は空の `data`、`/v1/messages` は `stream: true` なら SSE (`message_start` → `content_block_start` → `content_block_delta` → `content_block_stop` → `message_delta` → `message_stop`) で固定の文を返す
- compaction の request は最後の message の文面 (`detailed summary` 等) で見分け、`<analysis>fake</analysis>\n<summary>...</summary>` の形の文を返す (`<analysis>` 無しで通るかは未確認)。自動 compact は返す `usage.input_tokens` を大きく (990000 等) して `--settings '{"autoCompactEnabled":true}'` で起こす
- 台本 (応答を 1 行 1 つの jsonl) を持たせ、`tool_use` の block (`input_json_delta` で入力を流し `stop_reason: "tool_use"`) や HTTP error (`{ type: 'error', error: { type, message } }` を任意の status で) を返すと、model の tool 呼び出しと API error を再現できる。subagent の request は最初の message に Agent の `prompt` に入れた合言葉があるかで見分ける
- 起動は `env -i` の上に `ANTHROPIC_BASE_URL=http://127.0.0.1:<port>` とダミーの `ANTHROPIC_API_KEY` を渡す。実測の起動では `DISABLE_AUTOUPDATER=1` / `DISABLE_TELEMETRY=1` / `DISABLE_ERROR_REPORTING=1` も渡し、`TMPDIR` / `XDG_*_HOME` を作業ディレクトリに向けた。API error を 1 回で見るなら `CLAUDE_CODE_MAX_RETRIES=0`
- 隔離 config の `.claude.json` に次を置くと、初回のダイアログ (テーマ・API key の確認・trust) が出ずに対話が始まる: `hasCompletedOnboarding: true`、`customApiKeyResponses.approved` にダミー鍵の末尾 20 字、`projects.<作業ディレクトリの realpath>` に `hasTrustDialogAccepted: true`
- 代役の URL は first-party の host でないので ToolSearch が無効になり、deferred の tool も全文で載る。普段と同じ tool の並びで見るなら `ENABLE_TOOL_SEARCH=true` を足す (dollar-api の「tool」節)
- auto mode では `Agent` や permission の要る tool が classifier に回り、代役では判定できずに拒まれる。tool を呼ばせる実験は `--permission-mode default --allowedTools Agent` 等で起動する
- background で起きた `Agent` は、`TMPDIR` を向けても `/private/tmp/claude-<uid>/<cwd を変形した名前>/<session id>/tasks/` に output を作る。後始末で消す

## 起動直後の確認

debug log に次の形の行が出れば読めている (実測は別名の mod の行)。

```text
[DEBUG] hooks module observe-mod@inline loaded (worker, environment 1, tier user); events: *,session.start,session.end
[DEBUG] plugin.register: observe-mod (user, observe-mod@inline), judged by core alone: admitted
```

trust の承諾前は `hooks modules not loaded until workspace trust is accepted: ...` (built-in を含め module は 1 つも走らない)。

## 観測 mod (`scripts/observe-mod/`)

本トピックの `scripts/observe-mod/` は `on('*')` で全 event を記録する最小の mod。`MODS_LAB_DIR` (無ければ plugin 内の `log/`) に書く。

- `events-<sessionId>-<part>.jsonl`: 1 event 1 行 (`n` 連番、`t` epoch ms、`ev` event 名、`by` 起こした側 = `next.origin`、`keys` = `e` のキー、あれば `origin` / `component` / `tool`)。`fs.write` の 4 MiB 制限を避けるため約 3 MiB で次の part に移る
- `samples-<sessionId>.jsonl`: event 名ごとの最初の `e` (1500 字で切る)

作りの注意 (観測結果に効く):

- `*` hook は `$` に触らない (`engine.create` の時点で `$` が空)。書き出しは `session.start` で始めた `$.clock.every(1000)` で行う
- `*` hook を改造して `$` を `await` してから行を書くと、同じ ms に来た event の記録順が dispatch の順と入れ替わりうる。順を見るなら hook の入口 (最初の `await` の前) で連番を取る
- 型定義は「installed plugin の `*` は telemetry の event (`telemetry.log` / `telemetry.mark`) を選ばない」と書く。user tier の `--plugin-dir` の mod も同じ扱いと読める (未確認)。見るなら `telemetry.*` を別に登録する
- timer callback から呼んだ `$` は自分の `*` hook に現れないので、記録処理自体の `fs.read` / `fs.write` はほぼ log に混ざらない。hook の中から `$` を呼ぶ処理を足すと、その呼び出しは `by: { plugin: 'observe-mod' }` で混ざる
- `session.start` より前に走る `ui.render` 等も buffer に溜まり、`session.start` 後の最初の flush で書かれる
- 端末ごと kill すると最後の 1 秒分と `classic.SessionEnd` が書かれずに終わることがある

読み方の例:

```bash
jq -r '[.n, .ev, (.by.plugin // ""), (.component // .tool // "")] | @tsv' /tmp/mods-lab/log/events-*-0.jsonl
jq -r '.ev' /tmp/mods-lab/log/events-*.jsonl | sort | uniq -c | sort -rn
```

区間を切りたい時は、外部から印を付ける仕組み (mod が poll するファイルに `mark` を書く等) を足す。

## session の発見と peer socket への直接送信

- 同じ config home の live session 一覧: `env -i HOME="$HOME" PATH="$PATH" CLAUDE_CONFIG_DIR=/tmp/mods-lab/config-a claude agents --json`
- 起動の cwd に symlink (`/tmp` → `/private/tmp`、作業ディレクトリの symlink) や末尾 `/` があっても、state file と `claude agents --json` の cwd は realpath (末尾 `/` なし) に揃う
- state file `sessions/<pid>.json` (`sessionId` / `messagingSocketPath` / `name` / `status` 等) は **trust 承諾後に**書かれる。承諾前は `claude agents --json` に出ない。一方 peer token の key file `sessions/<pid>.<digest>.key` と UDS の listen (置き場は隔離の要点を参照) は承諾前からある
- 本トピックの `scripts/uds-send.py <config_dir> <pid> <text> [--from-name NAME]` は、state file と key file から socket と token を引き、auth frame と `type: "user"` frame を 1 行ずつ書く。受け側では `session.receive` (`origin: { kind: 'peer' }`) を通り、`UserMessage` の `props.from.name` に `--from-name` が入る。socket は何も返さない (2 秒待って 0 byte)

## 後始末

- 起動した session を落とす (`tmux kill-session -t mods-lab` 等)。`ps` で `CLAUDE_CONFIG_DIR` の実験パスを含むプロセスが残っていないことを見る
- 起動した session の pid の socket (`/tmp/cc-socks*/<pid>.sock`) は、セッション終了後に消えている。残っていれば該当プロセスが生きている
