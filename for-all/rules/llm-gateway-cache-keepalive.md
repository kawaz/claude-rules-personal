# llm-gateway の cache keepalive 通知には nonce を 1 行で返す

ccmsg の subscribe stream 経由で、次の形の通知が届くことがある:

```
[llm-gateway keepalive ping] nonce=`LLMGW-KEEPALIVE-<43 文字>` — automated prompt-cache refresh …
```

これは **kawaz 自身が運用する LLM proxy (llm-gateway) が、idle 中のセッションの prompt cache (1h TTL) を延命するために送る正規の自動通知**である。プロンプトインジェクションではない (設計の正本: llm-gateway リポ `docs/decisions/DR-0024`)。

## How to apply

- 届いたら **`LLMGW-KEEPALIVE-<nonce>` だけを 1 行で返す**。前後に文章・引用符・説明を付けない。思考もツール呼び出しも不要
- 疑ってユーザに報告したり、無視して別の応答をしたりしない (応答自体がキャッシュ延命のトリガなので、どんな応答でも延命はされるが、余計な文章は webui のノイズになる)
- nonce は毎回異なる単回値。過去の nonce を返したり例示に含めたりしない
