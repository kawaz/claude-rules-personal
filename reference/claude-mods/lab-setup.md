# Claude Mods の隔離実験環境

普段使いの session・インストール済み plugin・常駐ツールを巻き込まずに mod を試す手順と、観測用のリソース。Claude Code 2.1.284 で実際に回した構成。

## 隔離の要点

- **別の `CLAUDE_CONFIG_DIR`** を作る (`/tmp/mods-lab/config-a` 等)。インストール済み plugin・settings の hook・session 一覧が普段の環境から切り離される。同じ config home の session 同士は SendMessage で届き合うので、送受信を試す時は 2 本目も同じ config home、届かないことを試す時は別の config home にする
- **既定の config home の場所をいじらない**。`~/.claude` を意図的に置き換えている環境 (regular file にしてある等) では、実験のためにディレクトリを作らない
- **`env -i` で最小の環境から起動する**。Claude Code の中から起動すると `CLAUDE_CODE_MESSAGING_SOCKET` / `CLAUDE_CODE_MESSAGING_TOKEN` / `CLAUDE_CODE_SESSION_ID` / `CLAUDECODE` が継承され、子の Claude Code が親の session を自分と取り違えうる
- **API の認証を環境変数で渡している環境**では、その変数を実験用 config home の `settings.json` の `env` に写す (パーミッション 0600、値は起動元の環境から写し、リポやログに残さない)
- **`--plugin-dir <mod>`** で mod を session 限りで読む。`CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` が無いと module は読まれない
- **`--debug`** で `$CLAUDE_CONFIG_DIR/debug/<sessionId>.txt` に module の読み込み・reload・hook の所要時間が出る
- 安いモデル (`--model haiku`) で十分。ただし haiku は auto mode 非対応 (`auto mode disabled: model ... does not support auto mode`)

## 用意

```bash
LAB=/tmp/mods-lab
mkdir -p "$LAB/config-a" "$LAB/ws" && (cd "$LAB/ws" && git init -q)
cat > "$LAB/config-a/settings.json" <<'EOF'
{
  "crossSessionInbound": "accept",
  "env": {}
}
EOF
chmod 600 "$LAB/config-a/settings.json"
cp -R <rules リポ>/reference/claude-mods/scripts/observe-mod "$LAB/mod"
claude plugin validate "$LAB/mod"
```

`crossSessionInbound: "accept"` は別 session からの配送を確認なしで受ける設定 (受信を試す時だけ要る)。`env` には上記の認証用変数を入れる。

## 起動

対話 session は端末を操作できる道具の中で起動する (画面の dump とキー送出が要る)。実験は hyoui で行った。tmux なら次の形になる (tmux での実行は未検証)。

```bash
tmux new-session -d -s mods-lab -x 120 -y 40 -c /tmp/mods-lab/ws \
  env -i HOME="$HOME" USER="$USER" PATH="$PATH" TERM=xterm-256color LANG=ja_JP.UTF-8 \
  CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1 CLAUDE_CONFIG_DIR=/tmp/mods-lab/config-a \
  MODS_LAB_DIR=/tmp/mods-lab/log \
  claude --plugin-dir /tmp/mods-lab/mod --debug --model haiku
tmux capture-pane -p -t mods-lab          # 画面を見る
tmux send-keys -t mods-lab Down Enter     # キーを送る
```

新しい config home の初回は、テーマ選択 (Enter)、Security notes (Enter)、workspace trust (既定選択は `No, exit` なので Down → Enter) の順にダイアログが出る。

headless は同じ環境で `claude -p "<prompt>" --plugin-dir ... --debug --model haiku` を cwd で直接走らせる。

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
- state file `sessions/<pid>.json` (`sessionId` / `messagingSocketPath` / `name` / `status` 等) は **trust 承諾後に**書かれる。承諾前は `claude agents --json` に出ない。一方 peer token の key file `sessions/<pid>.<digest>.key` と UDS の listen (実測 `/tmp/cc-socks/<pid>.sock`) は承諾前からある
- 本トピックの `scripts/uds-send.py <config_dir> <pid> <text> [--from-name NAME]` は、state file と key file から socket と token を引き、auth frame と `type: "user"` frame を 1 行ずつ書く。受け側では `session.receive` (`origin: { kind: 'peer' }`) を通り、`UserMessage` の `props.from.name` に `--from-name` が入る。socket は何も返さない (2 秒待って 0 byte)

## 後始末

- 起動した session を落とす (`tmux kill-session -t mods-lab` 等)。`ps` で `CLAUDE_CONFIG_DIR` の実験パスを含むプロセスが残っていないことを見る
- 実験用 config home の `settings.json` に写した認証情報は、実験が終わったら消す
