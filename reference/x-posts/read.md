# X（Twitter）の投稿を読む

特定の投稿の**原文・投稿者・メディア URL**は FxTwitter の JSON API、X 上で最近話題のことや**動画・画像の中身**は xAI Grok の `x_search` を使う。対象は気になる投稿 1 件、または数時間〜数日の話題を調べる単発の利用。X のログインは不要。

## URL を指定して原文を読む（FxTwitter）

```bash
bash ~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/x-posts/scripts/fx.sh --help
```

以下の例は `reference/x-posts/` に移動済みの場合。

```bash
bash scripts/fx.sh 'https://x.com/NASA/status/2119136607009734978'
bash scripts/fx.sh 'https://x.com/NASA/status/2119136607009734978' --json
```

`fx.sh` は投稿 URL の数値 ID を抽出して `https://api.fxtwitter.com/2/status/<id>` に GET する。URL のユーザー名には依存しない。公開投稿ではトップレベルに `code`, `status`, `thread` があり、`status` に `text`, `author.name`, `author.screen_name`, `created_at`, `media.all[]`, `quote`, `replying_to` が入る。`--json` はサービスの JSON 全体をそのまま表示する。メディアの `url` は画像または動画の直接 URL で、`altText`、動画の `thumbnail_url`、`formats[]` などは `--json` で確認できる。**動画 URL が分かっても、その映像で何が起きるかは本文からは分からない。**

2026-11-08 の実測では、NASA の動画投稿 `2119136607009734978` に本文、投稿日時、`media.all[0].type: "video"`、mp4 URL、長さ 63.463 秒が返った。同じ会話の返信投稿 `2119143141450428828` には `replying_to.status: "2119136825927430570"` と親投稿 URL が入り、単独取得の `thread` は空配列だった。`/2/thread/2119143141450428828` では親から返信までの 3 投稿が `thread[]` に返り、`/2/conversation/2119143141450428828` では返信も含め `thread[]` 3 件、`replies[]` 3 件が返った。会話をたどる場合は `--json` の `replying_to.url` を見るか、必要な投稿 ID で次を叩く。

```bash
curl -fsS 'https://api.fxtwitter.com/2/thread/2119143141450428828' | jq -r '.thread[] | [.url, .text] | @tsv'
curl -fsS 'https://api.fxtwitter.com/2/conversation/2119143141450428828' | jq '{thread: [.thread[].url], replies: [.replies[].url]}'
```

単独取得は他人の返信を網羅しない。`quote` には引用投稿そのもの、または見られない引用の tombstone が入る場合がある（引用ありの実データは未検証）。FxTwitter API に話題全体の検索機能はない。非公式の外部サービスなので応答・提供が変わりうる。公式 [FxTwitter API 仕様](https://docs.fxembed.com/api/introduction) の v2 は IP ごとに毎分 1000 リクエストの制限を記載しているが、本用途では連続取得しない。

## X で最近の話題や投稿の動画・画像の中身を調べる（Grok）

```bash
bash scripts/x-search.sh 'X でここ24時間の Grok 4.7 について、具体的な投稿を挙げて何が話題ですか？' --unit unstable
bash scripts/x-search.sh 'この動画では何が起きていますか？ 投稿本文からの推測と区別してください' --url 'https://x.com/NASA/status/2119136607009734978' --unit unstable
bash scripts/x-search.sh '直近1週間の話題を教えて' --since 7d --model grok-4.7
```

`--unit stable`（既定）は `http://127.0.0.1:11302/ns-personal/api.x.ai/v1/responses`、`--unit unstable` はポート `11301` に送る。認証は `llm-gateway auth token --config ~/.config/llm-gateway/config-11302-stable.toml --ns personal --sub x-search` と同様にスクリプト内で短命 token を取得し、レスポンス表示後に捨てる。gateway は上流 xAI の認証に差し替える。利用者が token や xAI key を渡す必要はない。依存は macOS の `date`、`curl`、`jq`、`llm-gateway`。サーバーが稼働し、ns personal にアクセスできる必要がある。

[xAI の X Search 仕様](https://docs.x.ai/developers/tools/x-search) の Responses API は `tools: [{"type":"x_search"}]` を用い、`grok-4.7` の例を提示している。投稿者に絞るには `allowed_x_handles: ["NASA"]`（`@` は付けない、最大 20 件）、期間は `from_date` と**排他的**な `to_date`（UTC の `YYYY-MM-DD`）をツールに指定する。スクリプトの `--since 24h|7d` は日付で対象を広めに絞り、正確な時刻の範囲は質問にも付記する。日付・投稿者フィルターは keyword/semantic search に効くが thread fetch には効かない。`--url` を渡した場合、`enable_image_understanding` と `enable_video_understanding` を有効にしてその投稿を質問に添える。画像・動画は追加の image tokens として課金される。検索は `max_turns: 2` に制限している。

2026-11-08 に `grok-4.7` を unstable 経由で実行した検索・動画理解の両方で、Responses の `status` は `completed`、`output[]` には `reasoning` / `custom_tool_call` / `message` が入り、回答本文は `message.content[]` の `output_text.text`、引用元は同じブロックの `annotations[]` に `type: "url_citation"` と `url` で返った。検索では `x_keyword_search` と `x_semantic_search` の tool call が計 7 回、42 投稿を取得し、30 件の citation が `https://x.com/i/status/<id>` 形式で付いた。動画では `x_thread_fetch` 1 回と `view_x_video` 2 回の tool call、4 投稿の取得、対象投稿の citation 1 件が返り、モデルは約 63 秒の動画から複数時点のフレームを記述した。一方、音声の書き起こしはツールから返らず、発話内容は確認できなかった。[xAI の citations 仕様](https://docs.x.ai/developers/tools/citations) では回答本文の `[[N]](URL)` も引用の形式。スクリプトは本文に続けて citations の URL 一覧を表示する。**回答はモデルの要約・解釈であり、生の投稿全文の構造化レスポンスではない。** 原文が必要なら「投稿の原文をそのまま引用して、投稿 URL を付けて」と頼み、結果を `fx.sh` で照合する。動画・画像の描写はツールが対象を取得できた場合に限り確認できる。

### 料金の見方

[xAI の X Search 料金](https://docs.x.ai/developers/tools/x-search) は取得した X 投稿 1000 件あたり **$5**（1 件あたり $0.005）、ユーザープロフィール 1000 件あたり **$10**（1 件あたり $0.01）にトークン料金を加算する。重複取得の投稿は取得回数だけ数えられ、thread fetch では親・引用・返信も計上される。`usage.server_side_tool_usage_details.x_posts_fetched`、`x_users_fetched`、`usage.input_tokens`、`usage.input_tokens_details.cached_tokens`、`usage.output_tokens` から見積もる。[モデル料金](https://docs.x.ai/developers/models/grok-4.7) の `grok-4.7` は 20 万 prompt tokens 未満なら入力 $2/100 万 tokens、出力 $6/100 万 tokens（cached input $0.50/100 万 tokens）。20 万以上の prompt では入力 $4、出力 $12/100 万 tokens。画像・動画理解には image tokens が加わる。

2026-11-08 の実測（unstable、`grok-4.7`、`max_turns: 2`）では、直近の話題検索が入力 46,164 tokens（うち cached 28,032）、出力 4,486 tokens、42 投稿で **$0.287196**。指定投稿の動画理解が入力 25,908 tokens（うち cached 9,600）、出力 2,948 tokens、4 投稿で **$0.075104**。それぞれ `usage.cost_in_usd_ticks` は `2871960000`、`751040000` で、上記の公式単価による内訳は検索がトークン $0.077196 + 投稿 $0.21、動画がトークン $0.055104 + 投稿 $0.02。両実測とも `cost_in_usd_ticks / 10^10` がこの金額と厳密に一致した。ただし **ticks の換算係数そのものを定義した公式文書は未確認**なので、別条件のリクエストへ換算式を一般化する前に公式情報を確認する。検索の取得件数・モデルの出力長によって 1 回あたりの金額は変わる。

## FxTwitter が取得できないとき

X 公式の [oEmbed](https://publish.twitter.com/oembed?url=https%3A%2F%2Fx.com%2Fjack%2Fstatus%2F20) を単発で試す。投稿 URL の query encoding は `curl -G --data-urlencode` に任せる。

```bash
curl -fsSLG 'https://publish.twitter.com/oembed' --data-urlencode 'url=https://x.com/jack/status/20' | jq -r '.html'
```

`oEmbed` は 2026-11-08 に `jack/status/20` と NASA の動画投稿で確認した。両方とも最初に HTTP 301 を返すため `curl -L` でリダイレクトを追うと、`html` に投稿の本文と埋め込み用のマークアップが入る。画像・動画の実体や会話全文は含まれない。取得できなければ `x-search.sh` に投稿 URL を指定して内容を尋ね、原文とモデル要約を区別する。
