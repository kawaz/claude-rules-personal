# local-translate — 英文をローカルの翻訳サーバで日本語にする

自作ツール・webui・Claude のスクリプトから、クラウドを使わずに英文を日本語に訳す手順。経路は kawaz/translate-server (PLaMo 3 Translate 0.8B を llama.cpp の `llama-server` で動かす) で、caddy-app-proxy が最初のアクセスで起動する。設計は translate-server の `docs/DESIGN.md`。

## 送信

```sh
curl -sL https://translate.kawaz-mbp.kawaz.jp/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"plamo-3-translate","messages":[{"role":"user","content":"The helper reads stdin line by line."}],"chat_template_kwargs":{"target_lang":"ja","form":"plain"},"temperature":0,"max_tokens":1024}' \
  | jq -r '.choices[0].message.content'
```

- 常に **FQDN 経由** (tailnet 内のみ到達可)。`127.0.0.1:8087` 直結は on-demand 起動が効かない
- サーバは常駐せず cold start では **302 が返る** (caddy-app-proxy が起動してから同じ URL へ戻す)。`curl -L` か 1 回リトライで吸収する。初回は 2〜7 秒かかる
- API は llama-server の OpenAI 互換 API そのもの。`model` は `plamo-3-translate` 固定、`temperature: 0` で決定的 (同じ入力は同じ訳文なので呼び出し側でキャッシュできる)
- `max_tokens` は訳文の長さ分 (入出力合計の上限は 32,768 トークン)
- 並列は 4 本まで同時 decode。1 段落 0.2 秒、16 段落を 4 並列で 1.4 秒

## パラメータ (`chat_template_kwargs`)

モデルの chat template が解釈する。

| key | 内容 |
|---|---|
| `target_lang` | 訳先。`ja` |
| `source_lang` | 省略すると自動判定。英語と分かっていれば `en` |
| `form` | `plain` (常体、〜だ / 〜である) か `polite` (敬体、〜です / 〜ます)。日本語訳のみ |
| `glossary` | `[{"source":"serial","target":"直列"}]` の配列。英語のまま残したい語は `source` と `target` を同じにする |
| `context` | 内容理解のヒント (分野、周辺の文章)。文体の指示としては効かない |

直前の原文・訳文ペアを `messages` に `user` / `assistant` で積むと、その続きとして一貫した訳になる (history)。

## 入力の与え方

- **段落単位 (空行区切り) で 1 段落 1 リクエスト**が基本。並列が効き、段落ごとに逐次表示できる。文単位に分けると原文と訳文の 1:1 対応が得られる (変更箇所の色分け等に使える)
- 数千トークンまでなら md 文書を丸ごと 1 リクエストでも段落の脱落・結合は起きない (見出し・表・リスト・コードブロックは保たれる)。ただし全文が返るまで最初の 1 文字も出ない
- 日英混在のまま渡してよい。日本語のみの段落は無傷で返る。日本語比率で翻訳の要否を判定する前処理は要らない
- バッククォート内・パス・コマンドは保持される。既存の日本語文は意味を変えずに言い換えられることがある (完全に守りたければ文単位に分け、ラテン文字を含まない文は送らない)
- 英数字と和文の間の空白は入らない。必要なら呼び出し側で後処理する

## 起動・運用

- 起動スクリプト: translate-server の `bin/translate-server --port 8087` (フォアグラウンド)。モデル (0.57 GB) は `${XDG_CACHE_HOME:-~/.cache}/translate-server/` に無ければ自動取得
- 依存は Homebrew の `llama.cpp` だけ。セットアップは `just setup`、疎通は `just smoke`
- ログ: `${XDG_STATE_HOME:-~/.local/state}/translate-server/server.log`
- 止める: `pkill -f 'llama-server.*8087'`。次のアクセスで caddy が起動し直す
- 健康確認: `curl -sL https://translate.kawaz-mbp.kawaz.jp/health` → `{"status":"ok"}`
