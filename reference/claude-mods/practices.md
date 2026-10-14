# Claude Mods を書く時の選び方

mod を設計する時の判断軸。事実 (event の欄、`$` の制限) は reference の `claude-mods/capabilities` / `dollar-api` が正本。2026-10-14 に Claude Code 2.1.299 で書いた。Mods の API は版が進むと変わるので、この日付と版からの経過が鮮度の目安。

## リクエストの単位

- Claude Code の動作は「context を全部送る → response が返る」の繰り返し。この 1 往復が `turn.step` で、全部拾える
- `tool.call` / `prompt.submit` / `turn.complete` / `classic.*` 等は、その往復の一部や前後を選ぶためのもの。選び方は `capabilities`

## main と subagent の見分け

- subagent (worker) の往復にも main と同じ event が起きる
- `e.agentId` が無ければ main、あれば subagent。main だけ見るなら `e.agentId === undefined` で絞る
- `$.session.append` 等に `agentId` を渡すと、その subagent の会話が対象になる

## model に文脈を足す

- `$.session.append({ message: { type: 'user', content: [{ type: 'text', text }] } })` で会話に 1 行足す。mod の中なら好きなタイミングで呼べ、以後のリクエストに乗り続ける
- `type: 'system'` は人向けの画面通知で、model は読まない
- event の結果欄 (`tool.call` の `context` 等) は、その event の文脈に結び付けたい時だけ使う。一覧は `capabilities` の末尾
- append した行は model にユーザのメッセージとして見える。通知なら `[plugin名]` の接頭辞で出所を示す

## 状態の置き場

| 置き場 | 書くのは | 寿命 |
|---|---|---|
| `$.state` | plugin | session の間 (hot reload は跨ぐ。`/clear`・resume・終了で消える) |
| `$.store` | plugin | config home 単位で永続。同じ config home の全 session で共有 |
| plugin data dir | 利用者 | plugin の update を跨ぐ。利用者がエディタで直すファイル |

- `$.store` で session 別に持つものはキーに session id を含め、古いキーは掃除する (全体 4 MiB)
- project ディレクトリは境界に無い。分けたいならキーに含める
- `--plugin-dir` の開発版と install 版は plugin id が違い、`$.store` も data dir も別になる
- data dir を mod から知る正規の口は無い。`$.plugin.root` が `<plugins>/cache/<marketplace>/<plugin>/<version>` なら `<plugins>/data/<plugin>-<marketplace>` (install 経路で実測一致)。engine の配置規則への依存なので Design rationale に書く

## skill と tool の分担

- 決定的な処理 (検証、変換、状態の読み出し) は `$.tool.register` の tool に。判断や分岐が要る流れは skill md に
- tool の入力は `inputSchema` (JSON Schema) で型が付く。出力に schema を付ける口は無い
- skill から使う tool は、手順に完全名 `mcp__<plugin>__<name>` で書く。ToolSearch は名前の分かっている tool の schema を後から引く仕組みで、使う tool の見当は付けてくれない
- `description` は「何をするか」の 1 文。使い所は skill 側に書く
- `isDeferred: true` で schema は呼ばれた時だけ context に載る

## npm パッケージと bundle

- module は相対 import と `"claude-code"` しか読めない (bare specifier は validate が拒む)。npm パッケージは plugin 内に置いて相対 import する (dist を直接置いて動くことは実測済み)
- 依存が多いなら bundler で 1 ファイルに畳む。validate は `on(...)` の pattern、`$.noun.method`、`$.env` の変数名、`$.state` の参照を静的に走査し、実行時はその列挙にあるものしか通さないので、minify で呼び出しの形やリテラルが崩れると実行時に拒まれる。識別子の短縮・空白の削除は影響しない。文字列の変数への括り出し、`$.store` 等の別名化、event 名の定数化は不可 (未確認: bundle + minify の実機確認はしていない。bundle 後に `claude plugin validate` を回し、`calls` / `env` / `state` の列挙が bundle 前と一致することを見る)
- parse する形が少ないなら同梱せず、境界 (設定ファイル、`$.store` の読み戻し) に手書きの parse を 1 か所ずつ置き、`Design rationale:` で同梱しない理由を書く

## 実機で確かめる

- 「届くか」「残るか」は型定義だけでは分からない。隔離環境 (`lab-setup`) で、合言葉を注入して復唱させる・transcript を読む・`--debug` の log を見る
- `-p` と対話で挙動が違う event がある (`events`)
- 型定義や公式 README の文言が実装より古いことがある (例: "EARLY ACCESS" と有効化の条件。実装は標準で有効)
