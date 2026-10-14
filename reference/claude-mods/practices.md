# Claude Mods を書く時の選び方

mod を設計する時に迷う点の判断軸。事実 (event の欄、`$` の制限) は reference の `claude-mods/capabilities` / `dollar-api` が正本で、ここは「どれを選ぶか」だけを書く。根拠は型定義 (Claude Code 2.1.299) と、kawaz/claude-context-notify の Mods 化 (2026-10-14) での実測。

## 計測は response ごと、単位は turn でも tool でもない

Claude Code は「context を全部送る → response が返る」の繰り返しで、使用量はその response の `usage` に入っている。response ごとに発火するのは `turn.step` で、tool を呼ぶたびの変化もここで拾える。「tool を呼んだ時」(`tool.call`) や「turn の終わり」(`turn.complete` / `classic.Stop`) を計測の契機にすると、契機の種類ごとに処理が分かれて増える。main loop だけ見るなら `e.agentId === undefined` で絞る。

## model に文脈を足すなら、まず `$.session.append`

event の結果欄 (`tool.call` の `context`、`prompt.submit` の `e.context`、`classic.*` の `additionalContext`) は、その event が起きた時にしか使えない。「次のリクエストがどの種類でも必ず届く」口は event 側には無く、口を増やすと例外の扱いが口ごとに要る。event を待たずに会話へ 1 行足す `$.session.append({ message: { type: 'user', content: [{ type: 'text', text }] } })` なら、好きなタイミングで 1 か所から足せる。人には見えず model が読む行として保存され (transcript では `type: user`, `isMeta: true`)、以後のリクエストに乗り続ける。

event の結果欄を選ぶのは、その event の文脈に結び付けたい時だけ (tool の結果に添える、skill の展開に差し込む等)。選び方の表は `capabilities` の末尾。

model は append された行を「ユーザのメッセージ」として読む (user role のため)。通知なら `[plugin名]` のような接頭辞を付けて出所を示す。

## 状態の置き場は「誰が書くか」と「寿命」で決める

| 置き場 | 書くのは | 寿命 | 向くもの |
|---|---|---|---|
| `$.state` | plugin | session の間 (hot reload は跨ぐ。`/clear`・resume・プロセス終了で消える) | 描画の購読、turn をまたぐ一時値 |
| `$.store` | plugin | config home 単位で永続 (session・プロセスを跨ぐ、同じ config home の全 session で共有) | latch、カウンタ、plugin だけが触る記録 |
| plugin data dir | 利用者 | plugin の update を跨ぐ | 利用者がエディタで直す設定ファイル |

`$.store` は session を跨いで 1 つなので、session 別に持つものはキーに session id を含め、古いキーを掃除する (全体 4 MiB)。project ディレクトリは境界に無い (分けたいならキーに含める)。`--plugin-dir` の開発版と install 版は plugin id が違い、store も data dir も別になる。

plugin data dir を mod から知る正規の口は無い (`$.plugin` は `name` / `root` だけ、`$.env.get("CLAUDE_PLUGIN_DATA")` は undefined)。`$.plugin.root` が `<plugins>/cache/<marketplace>/<plugin>/<version>` の形なら `<plugins>/data/<plugin>-<marketplace>` で、install 経路では command hook の `CLAUDE_PLUGIN_DATA` と一致する (実測)。これは engine の配置規則への依存なので、使うなら Design rationale に書く。

## skill と tool の分担

決定的な処理 (検証、変換、状態の読み出し) は `$.tool.register` の tool に切り出し、判断や分岐が要る流れは skill md に残す。tool は `description` + `inputSchema` (JSON Schema) で入力に型が付き、長い手順を model に読ませずに済む。出力側に schema を付ける口は無い。

skill から使わせる tool は、skill md の手順に完全名 (`mcp__<plugin>__<name>`) で書く。ToolSearch は「名前が分かっている tool の schema を後から引く」仕組みで、model が使う tool の見当を付けてくれるものではない。`description` は「何をするか」の 1 文にとどめ、使い所の説明は skill 側に寄せる。`isDeferred: true` で schema は呼ばれた時だけ載る (入力が空で description が短い tool なら `false` でも消費は小さい)。

## 外から来るデータは境界 1 か所で parse する

mod の module は相対 import と `"claude-code"` しか読めず、npm パッケージを使うには plugin 内に同梱するしかない。parse する形が少ないなら手書きの parse を境界 (設定ファイルの読み取り、`$.store` の値の読み戻し) に 1 か所ずつ置き、`Design rationale:` で同梱しない理由を書く。

## 実機で確かめてから書く

型定義の doc は正確だが、「届くか」「残るか」は実機でないと分からない。隔離環境 (reference の `claude-mods/lab-setup`) で、合言葉を注入して model に復唱させる、transcript を読む、`--debug` の log を見る、の 3 点で確認する。`-p` と対話で挙動が違う event がある (`events`)。今日の時点で型定義と実装がずれていた例: 型定義と公式 README の "EARLY ACCESS" / 有効化の条件の記述 (実装は標準で有効)。
