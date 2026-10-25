# Claude Mods を書く時の選び方

mod を設計する時の判断軸。事実 (event の欄、`$` の制限) は reference の `claude-mods/capabilities` / `dollar-api` が正本。2026-10-14 に Claude Code 2.1.299 で書いた。Mods の API は版が進むと変わるので、この日付と版からの経過が鮮度の目安。

## リクエストの単位

- Claude Code の動作は「context を全部送る → response が返る」の繰り返し。この 1 往復が `turn.step` で、全部拾える
- `tool.call` / `prompt.submit` / `turn.complete` / `classic.*` 等は、その往復の一部や前後を選ぶためのもの。選び方は `capabilities`
- `turn.step` は stream の event で、hook は `async function*` で書き `const r = yield* next(e)` で chunk を素通しにする。`.catch` の handler も `async function* ($, e, next) { return yield* next(e) }` の形にする。普通の関数で `next(e)` を返すのは型エラー (型定義)

## main と subagent の見分け

- subagent (worker) の往復にも main と同じ event が起きる
- `e.agentId` が無ければ main、あれば subagent。main だけ見るなら `e.agentId === undefined` で絞る
- `$.session.append` 等に `agentId` を渡すと、その subagent の会話が対象になる。届くのは走行中の subagent だけで、終わった後は reject される (`dollar-api`)
- `$.tool.register` した tool の handler では `$.session.id()` が subagent からの呼び出しでも main の id になるので、呼び手は `e.agentId` で見分ける

## model に文脈を足す

- `$.session.append({ message: { type: 'user', content: [{ type: 'text', text }] } })` で会話に 1 行足す。足した行は以後のリクエストに乗るが、compaction で要約に置き換わる。compaction の chain の中で足した行は消え、`turn.start` で足した行はその turn の最初のリクエストに間に合わない (`dollar-api`)
- `type: 'system'` は人向けの画面通知で、model は読まない
- event の結果欄 (`tool.call` の `context` 等) は、その event の文脈に結び付けたい時だけ使う。一覧は `capabilities` の末尾
- append した行は model にユーザのメッセージとして見える。通知なら `[plugin名]` の接頭辞で出所を示す
- session の最初の request に文脈を載せるなら、`prompt.submit` の before で `$.state` の印が無ければ `$.session.append` して印を置く。加えて `session.compact` の after で「compact 済み」の印を置き、次の `prompt.submit` で足し直す。実測: 対話と `-p`、startup / resume / continue / `/clear` / compact のすべてで次の request に載り、人の prompt と同じ user message の prompt の直前に並ぶ (2.1.299。届いたかと位置は代役の API に向けた request の body で見た。`lab-setup`)
  - `/clear` と `--resume` / `--continue` では `$.state` が空になるので印は自然に消えて足し直され、hot reload では残るので二重にならない
  - resume のたびに 1 つずつ増える (前に足した行も残る)
  - 自動 compact は turn の途中 (`turn.start` の後) に起きるので、足し直しはその次の turn の request からになる
  - `session.start` で足す形は `/clear` と compact の後に載らず hot reload で重複し、`prompt.context` の独自 block は resume で作り直されない (`capabilities`)

## 状態の置き場

| 置き場 | 書くのは | 寿命 |
|---|---|---|
| `$.state` | plugin | session の間 (compact と hot reload は跨ぐ。`/clear`・`--resume` / `--continue`・終了で消える。session 内の `/resume <sid>` は未観測) |
| `$.store` | plugin | config home 単位で永続。同じ config home の全 session で共有 |
| plugin data dir | 利用者 | plugin の update を跨ぐ。利用者がエディタで直すファイル |

- 実測: `/clear` の後、`classic.SessionStart (clear)` の hook の入口ではまだ前の session の `$.state` の一部が読めることがあり、次の `prompt.submit` の時点では全部消えている (2.1.299)。「この session で済ませた」の印は `prompt.submit` 以降で読む
- `$.store` で session 別に持つものはキーに session id を含め、古いキーは掃除する (全体 4 MiB)
- project ディレクトリは境界に無い。分けたいならキーに含める
- `--plugin-dir` の開発版と install 版は plugin id が違い、`$.store` も data dir も別になる
- data dir を mod から知る正規の口は無い。`$.plugin.root` が `<plugins>/cache/<marketplace>/<plugin>/<version>` なら `<plugins>/data/<plugin>-<marketplace>` (install 経路で実測一致)。engine の配置規則への依存なので Design rationale に書く

## skill と tool の分担

- 決定的な処理 (検証、変換、状態の読み出し) は `$.tool.register` の tool に。判断や分岐が要る流れは skill md に
- tool の入力は `inputSchema` (JSON Schema) で model に示す。engine はこれで入力を検査しないので、handler の入口で parse する (`dollar-api` の「tool」節)。出力に schema を付ける口は無い
- skill から使う tool は、手順に完全名 `mcp__<plugin>__<name>` で書く。ToolSearch は名前の分かっている tool の schema を後から引く仕組みで、使う tool の見当は付けてくれない
- tool の description と inputSchema は context を食う。plugin 専用の tool (発見性が要らない、skill が完全名で使い方を書く) は **型と制御性のためだけ** に tool にする: description は無しか 3 語程度、field の description は名前で中身が決まらないもの (`resume` が session id を指す等) だけに 3 語程度、型は `string` / `boolean` / enum と `required` だけで `minLength` / `pattern` / `format` 等の細則は書かない (`required` を見れば省略可は分かる)。細則は handler 側の schema で検査し、外れたら簡潔なエラー文で言い直させる。model に渡す JSON Schema は handler の schema から導き、その変換で細則を落とす (別 schema を手書きしない)。汎用ツールとして配る plugin なら tool 自体の説明は適度に持ってよいが、「言わなくても分かる」規則を書かない点は同じ (kawaz 2026-10-25)
- `isDeferred: true` で schema は呼ばれた時だけ context に載る。ToolSearch が無効な環境 (`ANTHROPIC_BASE_URL` が first-party でない等) では全文で載る (`dollar-api` の「tool」節)

## npm パッケージと bundle

- module は相対 import と `"claude-code"` しか読めない (bare specifier は validate が拒む)。npm パッケージは plugin 内に置いて相対 import する (dist を直接置いて動くことは実測済み)
- 依存が多いなら bundler で 1 ファイルに畳む。validate は `on(...)` の pattern、`$.noun.method`、`$.env` の変数名、`$.state` の参照を静的に走査し、実行時はその列挙にあるものしか通さないので、minify で呼び出しの形やリテラルが崩れると実行時に拒まれる。識別子の短縮・空白の削除は影響しない。文字列の変数への括り出し、`$.store` 等の別名化、event 名の定数化は不可 (未確認: bundle + minify の実機確認はしていない。bundle 後に `claude plugin validate` を回し、`calls` / `env` / `state` の列挙が bundle 前と一致することを見る)
- parse する形が少ないなら同梱せず、境界 (設定ファイル、`$.store` の読み戻し) に手書きの parse を 1 か所ずつ置き、`Design rationale:` で同梱しない理由を書く

## 実機で確かめる

- 「届くか」「残るか」は型定義だけでは分からない。隔離環境 (`lab-setup`) で、合言葉を注入して復唱させる・transcript を読む・`--debug` の log を見る
- `-p` と対話で挙動が違う event がある (`events`)
- 型定義や公式 README の文言が実装より古いことがある (例: "EARLY ACCESS" と有効化の条件。実装は標準で有効)
