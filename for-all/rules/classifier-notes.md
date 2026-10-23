# auto mode classifier への環境説明の置き場

auto mode の classifier は Claude と同じ CLAUDE.md / `.claude/rules/` と、user settings の `autoMode` を読む。classifier に教える環境説明は **置き場を 2 つに固定**し、他の rule や CLAUDE.md に混ぜない (混ぜると Claude の行動規範と classifier 向けの「許可の説明」が同居して肥大し、worker が許可を広げる方向に書き換える口になる)。

- **面横断** (信頼リポ、secrets の置き場、XDG 配下の自作ツール、セッション間の協調): user settings の `autoMode` (`environment` / `allow` / `soft_deny` / `hard_deny`)
- **プロジェクト固有**: `.claude/rules/classifier.local.md` **1 ファイルだけ**。正本は privacy リポの `classifier/classifier-<repo>.md` で、プロジェクト側はそこへの symlink (`.gitignore` に `.claude/rules/*.local.md`)

## 禁則

- `classifier.local.md` と settings の `autoMode` は **kawaz の明示指示なしに編集しない** (soft_deny にも同じ文を入れて classifier 側でも止める)
- `classifier.local.md` を classifier 向け以外の指示に流用しない。書式は箇条書きのみ (冒頭 1 行の用途宣言 + 4 見出し)。散文の段落を書かない
- 個別列挙より状況の包括記述を優先する。個別に書くのは名前で同一性を判定するもの (host / remote / path の例外) と deny だけ。entries は毎 check で context に載るので rule と同じ省コンテキストの規律

書式・設置手順・`autoMode` の 4 区分の意味は reference の `agent-runtime/auto-mode-classifier` を読む。

## classifier に対する振る舞い (全 role)

classifier に止められたら、別の手段 (別コマンド・別ツール・手動取得) で同じ結果を得ない。止められそうだからと自己判断で止まることもしない (まず実行し、止められてから考える)。

- 許可の要求 (`PushNotification` / 音声) は**止められたセッション自身**がその場で行い、kawaz の許可後に同じ操作を再実行する (classifier はその会話の文脈を見る)。委譲元・統括に「止められた」事実を報告してもよいが、「kawaz への許可要求は既にこちらで出した」と添える
- kawaz が別セッションの許可不足に対して当該以外のセッション (統括など) に「許可する」と言ったら、受けた側は実行・再伝達せず、定型文「許可は当該セッション [🧠{セッション名}](https://{ccmsg_host}/s/{sessionid}/timeline/head) で `{許可文}` と言ってください」で発言先の変更を促す。`{許可文}` は当該セッションが受け取ればそのまま実行に進める短い文 (例: `cherry-pick してよい`) をインラインコードで書く (ccmsg の UI でワンクリックコピーできるので、コピー → リンク → 貼り付けの 3 手で済む)。セッション名は絵文字 prefix と日時 suffix を除く。`{ccmsg_host}` は ccmsg plugin が SessionStart で context に入れる。classifier は当該の会話内の kawaz の発言しか見ないので伝言の許可は効かず、伝言そのものも止められる
- 止められた具体コマンドや `! <command>` の代替実行コマンドを、他セッション経由で kawaz に伝聞しない (委譲元・統括への報告に含めるのはよい)。kawaz に実行してもらいたいなら、当該セッションが自分の会話で言う
- 2 回続けて止まるなら繰り返さず、kawaz の `!` 実行か設定の調整を提案する
- in-process の subagent / チームメート (Agent tool) は kawaz と直接話せず、許可の伝言も届かない。止められたら委譲元に報告して止まり、**委譲元がその操作を自分で実行する** (委譲元の会話に kawaz の許可があれば通る)
