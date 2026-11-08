# auto mode classifier への許可・環境説明の置き場

auto mode の classifier は Claude と同じ CLAUDE.md / `.claude/rules/` と、user settings の `autoMode` を読む。classifier 向けの許可・環境説明は次の 2 か所に置き、他の rule や CLAUDE.md に混ぜない (混ぜると Claude の行動規範と classifier 向けの「許可の説明」が同居して肥大し、worker が許可を広げる方向に書き換える口になる)。

- **面横断** (信頼リポ、secrets の置き場、XDG 配下の自作ツール、セッション間の協調): user settings の `autoMode` (`environment` / `allow` / `soft_deny` / `hard_deny`)
- **プロジェクト固有**: そのプロジェクトの `.claude/settings.local.json` (`.gitignore` 済み、commit しない) の `permissions.allow` に**ワイルドカード無しの完全一致形** (`Edit(~/.config/foo/bar.toml)`、`Bash(llm-gateway daemon reload unstable)`) で足す。完全一致は classifier を通らず確実に効き、ワイルドカード付きは classifier の判定に回るので使わない

## 禁則

- settings の `autoMode` は **kawaz の明示指示なしに編集しない** (soft_deny にも同じ文を入れて classifier 側でも止める)
- プロジェクトの完全一致 allow に入れるのは **実際に繰り返し止められた操作だけ**。先回りで列挙しない
- エージェントは `.claude/settings*.json` を書けない (Write / Edit / `cp` とも、許可後でも fast classifier が止める)。mktemp の一時ファイルに中身を作り、permit ツールの `attachments` で見せて `cp` を `commands` に書き、kawaz が webui から実行する
- `autoMode` の entries は個別列挙より状況の包括記述を優先する。個別に書くのは名前で同一性を判定するもの (host / remote / path の例外) と deny だけ。entries は毎 check で context に載るので rule と同じ省コンテキストの規律

完全一致 allow の書き方・`autoMode` の 4 区分の意味は reference の `agent-runtime/auto-mode-classifier` を読む。

## classifier に対する振る舞い (全 role)

classifier に止められたら、別の手段 (別コマンド・別ツール・手動取得) で同じ結果を得ない。止められそうだからと自己判断で止まることもしない (まず実行し、止められてから考える)。

- 許可の要求 (ccmsg の say ツールの音声) は**止められたセッション自身**がその場で行い、ユーザの許可後に同じ操作を再実行する (classifier はその会話の文脈を見る)。委譲元・統括に「止められた」事実を報告してもよいが、「ユーザへの許可要求の通知は既にこちらで出した」と添える
- 尋ね方は、ccmsg の permit ツールがあれば**それを使う** (止められた行動 / 読ませたいファイルのパス / 許可してほしい内容 / コマンド全文を渡す。webui が許可依頼のバブルを描き、「許可する」で許可文がコピーされる。使い方は ccmsg の skill)。無ければ 2 文の定型: 「commit が止められました。実行してよければ `commitして良い` と言ってください。」= (1) 何が止められたかを 1 行、(2) そのまま実行に進める許可文を 1 つ。許可文には止められた操作の具体 (コマンドなら全文、ファイルを渡すならそのパス) を入れ、長ければコードブロックで複数行に分ける。渡すファイルの中身は本文に貼らず、パスを示して人に読んでもらう。ユーザがそれを言ったら同じ操作を**書き換えずに**再実行する
- permit の書き方: `blocked` / `intents` / `description` は簡潔に (1 文ずつ)。`intents` は個別に許可できるよう 1 操作 1 要素に分ける。削除は `rm` のコマンドとして `commands` に書く。出すのは**止められた操作だけ** (止められていない commit 等を先回りで含めない)
- `! <command>` を貼って手元実行してもらう形にしない: ユーザがコマンドを読んで判断・実行する負担が増える上、その実行は「ユーザが実行した」だけで同種操作の許可とは見なされず、エージェントの再実行は止められ続ける
- 別セッションの許可不足をユーザに伝えた結果、当該以外のセッション＝伝聞したこのセッション (統括など)に「許可する」と言ったら、受けた側は実行・再伝達せず、定型文「許可は当該セッション [🧠{セッション名}]({ccmsg_url}/s/{sessionid}/timeline/head) で `{許可文}` と言ってください」で発言先の変更を促す。`{許可文}` は当該セッションが受け取ればそのまま実行に進める短い文 (例: `push してよい`) をインラインコードで書く (ccmsg の UI でワンクリックコピーできるので、コピー → リンク → 貼り付けの 3 手で済む)。セッション名は絵文字 prefix と日時 suffix を除く。`{ccmsg_url}` (scheme 付き) は ccmsg plugin が最初の turn の前の案内で context に入れる。classifier は当該コンテキスト内のユーザ発言しか見ないので伝言の許可は効かず、許可の伝言そのものも止められる
- 止められた具体コマンドや `! <command>` の代替実行コマンドを、他セッション経由でユーザに伝聞しない (委譲元・統括への報告に含めるのはよい)。ユーザに実行してもらいたいなら、当該セッションが自分の会話で言う
- `!` 実行は頼まない。permit に出し直し、許可後も止まるなら kawaz が webui から実行する (繰り返し要る操作なら上の完全一致 allow を足す)。止まるまたはユーザに依頼をする際は ccmsg の say ツールで呼びかける ([[notification-tips]])。
- in-process の subagent / チームメート (Agent tool) はユーザと直接話せず、許可の伝言も届かない。止められたら委譲元に報告して止まり、**委譲元がその操作を自分で実行する** (委譲元の会話にユーザの許可があれば通る)
