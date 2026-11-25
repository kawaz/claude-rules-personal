# agy を非対話で使う (`-p` と stream-json)

`agy` は Google の Antigravity の CLI で、Gemini と、同じ口から Claude 等のモデルを呼べる。Claude Code のセッションから別のモデルに仕事を出す時に、非対話で使う。

確かめた版: 1.5.13〜1.5.15 (macOS、2026-11-21〜25)。「未確認」と書いた項目は、help やドキュメントの記述だけが根拠。

## 基本の形

```bash
agy -p "<依頼の本文>" --model gemini-4-carbon-high --output-format json
```

- カレントディレクトリが、モデルから見える作業ディレクトリになる。`--add-dir <ディレクトリ>` で足せる (何度も書ける)
- 依頼の本文は引数で渡す。長い本文はファイルに書き、`"$(cat prompt.md)"` で渡す
- 最小の依頼でも入力は 9,000 トークン前後になる (agy のシステムプロンプトの分)
- 小さなファイルを 1 つ読ませて答えさせるだけなら、30〜40 秒で返る。数百 KB の文書を全部読んで報告を書かせる依頼は、1 回で 10〜50 分かかった

## モデル

`agy models` で一覧が出る。名前は `<系列>-<強さ>` の形。

| 系列 | 名前 |
|---|---|
| Gemini 4 Neon | `gemini-4-neon-low` / `-medium` / `-high` / `-xhigh` |
| Gemini 4 Carbon | `gemini-4-carbon-low` / `-medium` / `-high` |
| Gemini 4 Argon | `gemini-4-argon-low` / `-medium` / `-high` |
| Gemini 4 Hydrogen | `gemini-4-hydrogen-low` / `-medium` / `-high` / `-xhigh` |
| Orchestrator | `gemini-pro-orchestrator` (Carbon) / `-neon` / `-argon` |
| Gemini 3.8 Flash | `gemini-3.8-flash-low` / `-medium` / `-high` |
| Claude | `claude-opus-5-5-low` 〜 `-high`、`claude-sonnet-5-5-low` 〜 `-high` |
| GPT-OSS | `gpt-oss-120b-medium` |

- `--effort` (low|medium|high|xhigh|max) は `--model` と併せて指定できる。`--model gemini-3.8-flash-low --effort low` は約 3 秒、思考 0 トークンで返った
- `--model` を省いた時に使われるモデルは、出力に出ない
- サインインしていないと `agy models` は `Please sign in to view available models` で失敗し、`-p` は認証の入力待ちのまま 60 秒で失敗する。サインインは人が引数なしの `agy` を端末で 1 回起動して行う

## 出力の形

| `--output-format` | 中身 |
|---|---|
| `text` (既定) | 応答の本文だけ |
| `json` | 1 個の JSON。`conversation_id`、`status` (`SUCCESS` / `ERROR`)、`response`、`duration_seconds`、`num_turns`、`usage` (入力・出力・思考・cache の各トークン)。失敗時は `error` と `finished_reason`、拒否された道具があれば `denied_actions` |
| `stream-json` | 1 行 1 イベントの NDJSON。最初に `init` (作業ディレクトリ、使える道具の一覧、`permission_mode`)、途中は `step_update` (`text_delta` で応答の断片)、最後に `result` (`json` と同じ中身) |

`--json-schema <JSON の文字列か、ファイルのパス>` を付けると、応答がスキーマに沿い、`json` の出力に `structured_output` の欄が足される。

```bash
agy -p 'Give the capital of Japan and France.' \
  --json-schema '{"type":"object","properties":{"japan":{"type":"string"},"france":{"type":"string"}},"required":["japan","france"]}' \
  --output-format json
# → "structured_output":{"france":"Paris","japan":"Tokyo"}
```

## 会話を続ける

1 回目の `json` の出力にある `conversation_id` を、次の回に `--conversation <ID>` で渡すと、同じ会話の続きになる (前の回の内容を覚えている)。`-c` / `--continue` は直前の会話を続ける。

- ID は agy が発行する。自分で作った uuid を `--conversation` に渡すと `conversation "…" not found` と警告し、別の ID で新しい会話を始める (Claude の `--session-id` のように先に決めることはできない)

## 1 つのプロセスに何回も流す (stream-json の入力)

```bash
agy --input-format stream-json --output-format stream-json < in.jsonl
```

`in.jsonl` は 1 行 1 依頼で、形は次のとおり (`event` が無いと `stream input message is missing the "event" field` で終わる)。

```json
{"event":"user","message":{"content":"Remember 7733. Reply only: OK"}}
{"event":"user","message":{"content":"What number did I ask you to remember? Reply only the number."}}
```

- 1 行ごとに 1 回の応答が走り、それぞれ `result` が出る。`init` は最初の 1 回だけで、`conversation_id` も 1 つ。2 回目の依頼で 7733 と答えた (文脈は続く)
- 起動が 1 回で済むので、`--conversation` で毎回起動するより速い。2 回目以降は cache が効き、入力が 2,000 トークン前後に減った
- 次の依頼は、今の回の `result` を受け取ってから書く。標準入力を閉じると、今の回を終えてから正常に終わる
- この形では `-p` の本文は捨てられる。`--input-format stream-json` には `--output-format stream-json` が必須

## 失敗の見分け方

終了コードだけでは成功したかが分からない。`json` / `stream-json` の `status` と、標準出力の文を見る。

| 起きる事 | 見え方 |
|---|---|
| 権限の無い道具 (シェル等) を使おうとした | `jetski: no output produced — a tool required the "command" permission …`。終了コード 0、`status` は `SUCCESS` のまま `response` が空。`denied_actions` に載る |
| 利用枠が尽きた | `Individual quota reached … Resets in <時間>` と `AGY_ERROR: {…"error_code":429…}`。終了コード 3 |
| `--print-timeout` の時間切れ | `AGY_ERROR` に `"status":"DEADLINE_EXCEEDED"`、`"reason":"print_timeout"`。終了コード 3。途中までの応答は返らない |
| `--agent` に無い名前を渡した | `unknown agent "<名前>"`。終了コード 1 |
| 依頼した報告のファイルが書かれていない | 何も出ない。終わった後に自分で確かめ、無ければ標準出力を報告の代わりに残す |

- 利用枠は Gemini のモデル全体で 1 つに数えられる。既定のモデルで尽きた時、`gemini-3.8-flash-medium` も同じ残り時間で 429 になり、`claude-sonnet-5-5-low` は通った (2026-11-25)。同じモデルに重い依頼を 4 つ並行で流すと、1 時間ほどで尽きた
- `--print-timeout <時間>` (例: `5400s`) で 1 回の上限を決める。既定の 0 は終わるまで待つ

## ログ

- 実行ごとに `~/.gemini/antigravity-cli/log/cli-<開始の日時>.log` に残る。`--log-file <パス>` で出力先を変えられる
- 道具の呼び出しごとに `Monitor agy_tool_safety FINISHED: triggered=…, reason="…"` の行が出る。`triggered=true` は打ち切りの印ではない (ファイルの編集のたびに `reason="unsupported_tool: edit_file"` として出るが、編集は通っている)
- 作業ディレクトリの中の rule やメモリに当たるファイルを編集すると、別の検査 (`sir_flash_lite`) が `Risk Signal B` (エージェントが自分の指示を編集している) と印を付ける。それで編集が止められるかは未確認
