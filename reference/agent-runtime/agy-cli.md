# agy (Antigravity の CLI) を非対話で使う

`agy` は Google の Antigravity の CLI で、Gemini と、同じ口から Claude 等のモデルを呼べる。Claude Code のセッションから別のモデルに仕事を出す時に、`agy -p` (1 回の依頼を流して応答を受け取る) で使う。

確かめた版: 1.5.15 (macOS、2026-11-25)。「未確認」と書いた項目は、help の表示だけが根拠。

## 基本の形

```bash
agy -p "<依頼の本文>" --model gemini-4-carbon-high
```

- カレントディレクトリが、モデルから見える作業ディレクトリになる
- 応答は標準出力に text で出る (`--output-format` の既定)
- 依頼の本文は引数で渡す。長い本文はファイルに書き、`"$(cat prompt.md)"` で渡す
- 小さなファイルを 1 つ読ませて答えさせるだけなら、30〜40 秒で返る

## モデル

`agy models` で一覧が出る。名前は `<系列>-<強さ>` の形。

| 系列 | 名前の例 |
|---|---|
| Gemini 4 Carbon | `gemini-4-carbon-low` / `-medium` / `-high` |
| Gemini 4 Neon | `gemini-4-neon-low` / `-medium` / `-high` / `-xhigh` |
| Gemini 4 Argon、Hydrogen | 同じ形 |
| Claude | `claude-opus-5-5-high`、`claude-sonnet-5-5-high` 等 |

`--effort` (low|medium|high|xhigh|max) というオプションもある。モデルの名前の強さとの関係は未確認。

## 道具と権限

非対話 (`-p`) では、権限を人に聞けない。聞く必要がある道具を使おうとすると、その場で拒否される。

| したい事 | 付ける物 | 確かめた事 |
|---|---|---|
| ファイルを読む | 何も要らない | そのまま動く |
| 別のディレクトリにも書く | `--add-dir <ディレクトリ>` と `--mode accept-edits` | 動く。`--add-dir` は何度も書ける |
| シェルのコマンドを使う | 設定で許可するか、`--dangerously-skip-permissions` | 許可が無いと、何も出力せずに終わる (下の「落とし穴」) |

- `--mode` は `accept-edits`・`auto`・`plan` の 3 つ。`auto` と `plan` の振る舞いは未確認
- `--settings` に JSON かファイルのパスを渡すと、その回だけの設定を足せる。help の案内では、コマンドの許可は `permissions.allow` に `command(<対象>)` の形で書く。効くかは未確認
- `--sandbox` は「terminal restrictions enabled」とだけ説明されている。何が縛られるかは未確認
- 依頼の本文に「シェルのコマンドは使えない。ファイルを読む・探す・書く道具だけを使う」と書くと、多くの場合は守られる。守られずにコマンドを使おうとして、何も書かずに終わる事もある

## 落とし穴

終了コードと標準出力だけでは、成功したかが分からない。

| 起きる事 | 見え方 | 見分け方 |
|---|---|---|
| 権限の無い道具 (シェル等) を使おうとした | 標準出力に `jetski: no output produced — a tool required the "command" permission …`。終了コードは 0 の事がある | 標準出力の文 |
| 非対話で使えない道具 (`run_workflow`) を使おうとした | 会話ごと打ち切られる。終了コードは 0 で、標準出力には途中の 1 行しか残らない | ログに `CancelCascadeInvocation` がある |
| 利用枠が尽きた | 標準出力に `Individual quota reached … Resets in <時間>` と `AGY_ERROR: {…"error_code":429…}`。終了コードは 3 | 標準出力の文と終了コード。戻るまでの時間が書いてある |

- 利用枠はモデルの系列ごとに尽きる。同じモデルに重い依頼を 4 つ並行で流すと、1 時間ほどで尽きた。長い依頼は並行の数を抑える
- 仕事を分ける道具 (`invoke_subagent`・`manage_subagents`・`send_message`) は、非対話では使えない。使おうとしても、打ち切られずに 1 人で続ける事が多い。打ち切られたのは `run_workflow` の時だった
- 依頼した報告のファイルが書かれたかは、終わった後に自分で確かめる。書かれていなければ、標準出力を報告の代わりに残す

## ログ

- 実行ごとに `~/.gemini/antigravity-cli/log/cli-<開始の日時>.log` に残る。`--log-file <パス>` で出力先を変えられる
- 道具の呼び出しごとに `Monitor agy_tool_safety FINISHED: triggered=…, reason="…"` の行が出る
- `triggered=true` は、打ち切りの印ではない。ファイルの編集のたびに `reason="unsupported_tool: edit_file"` として出るが、編集は通っている
- 作業ディレクトリの中の rule やメモリに当たるファイルを編集すると、別の検査 (`sir_flash_lite`) が `Risk Signal B` (エージェントが自分の指示を編集している) と印を付ける。それで編集が止められるかは未確認

## 時間の制限

`--print-timeout <時間>` (例: `5400s`) で、1 回の依頼の上限を決める。既定の 0 は、終わるまで待つ。数百 KB の文書を全部読んで報告を書かせる依頼は、1 回で 10〜50 分かかった。

## JSON の入出力 (未確認)

help に載っているが、まだ試していない。別の道具から呼んで結果を機械で読む時は、ここを使う事になる。

| オプション | help の説明 |
|---|---|
| `--output-format json` | 応答を JSON で出す |
| `--output-format stream-json` | 途中の経過を NDJSON で流す |
| `--input-format stream-json` | 標準入力から NDJSON を 1 行ずつ読み、1 行ごとに 1 回の応答を返す。`--output-format stream-json` と組で使う |
| `--json-schema <スキーマ>` | 応答をスキーマに合わせる。JSON の文字列か、スキーマのファイルのパスを渡す |
| `-c` / `--conversation <ID>` | 直前の会話、または ID で指定した会話を続ける |

確かめる事: JSON に入る項目 (応答の本文、使った道具、終了の理由、会話の ID、利用枠のエラー)、打ち切りや権限の拒否が JSON の上でどう見えるか、`--conversation` で前の回の続きを流せるか。

## 広い権限で流す時の囲い方 (案。未検証)

シェルを使えないと、ファイルの検索・リネーム・削除・検査のコマンドの実行ができず、頼める仕事が狭くなる。広い権限 (`--dangerously-skip-permissions`) で流すなら、書ける範囲を外から囲う。

- コンテナに、必要なディレクトリだけをマウントする。読むだけの物は読み取り専用、書かせる物だけ書き込み可にする
- 確かめる事: Linux 版の `agy` がコンテナで動くか、ログインの資格情報をどう渡すか。資格情報を中に置くと、広い権限のエージェントはそれも読める。API のためにネットワークは開けるので、中で読める物は外に出せる前提で、見せる物を選ぶ
- `--sandbox` で足りるかは、何が縛られるかを確かめてから決める

## 入力を守る

元のリポを直接見せない。写し (`git archive` の展開か clone) を作って、そこで作業させる。

- 読ませるだけの時は、写しを書き込み禁止 (`chmod -R a-w`) にする
- 直させる時は、clone の push 先を外しておく。結果は clone の中のコミットとして受け取り、採る物だけを元のリポに入れる
- 送った中身は、外のサービスに出る。個人情報や業務の情報を含むリポを渡す時は、持ち主の明示の指示がある時だけにする
