# auto mode classifier への許可・環境説明の置き場

auto mode の classifier が見るのはユーザの発言と user settings の `autoMode`、完全一致の allow だけで、CLAUDE.md / `.claude/rules/` の本文は効かない (実測 2026-11-08)。classifier 向けの許可・環境説明は次の 2 か所に置き、rule や CLAUDE.md に書かない。

- **面横断** (信頼リポ、secrets の置き場、XDG 配下の自作ツール、セッション間の協調): user settings の `autoMode` (`environment` / `allow` / `soft_deny` / `hard_deny`)
- **プロジェクト固有**: そのプロジェクトの `.claude/settings.local.json` (gitignore 済みで commit しない) の `permissions.allow` にワイルドカード無しの完全一致形 (`Edit(/Users/<user>/.config/foo/bar.toml)`、`Bash(llm-gateway daemon reload unstable)`) で足す。完全一致は classifier を通らず確実に効く (ワイルドカード付きは classifier に回るので使わない)

## 禁則

- settings の `autoMode` は **kawaz の明示指示なしに編集しない** (soft_deny にも同じ文を入れて classifier 側でも止める)
- プロジェクトの完全一致 allow に入れるのは実際に繰り返し止められた操作だけ。先回りで列挙しない
- エージェントは `.claude/settings*.json` を書けない (`cp` も含め、許可後でも fast classifier が止める)。足す時は permit ツールの `project_permissions` に `{ "add": "<rule>" }` を書く (kawaz が webui で押すと daemon が書き、すぐ効く)。Edit の rule は絶対パスで書く (`~/` は効かない)
- `autoMode` の entries は個別列挙より状況の包括記述を優先する。個別に書くのは名前で同一性を判定するもの (host / remote / path の例外) と deny だけ。entries は毎 check で context に載るので rule と同じ省コンテキストの規律

完全一致 allow の書き方・`autoMode` の 4 区分の意味は reference の `agent-runtime/auto-mode-classifier` を読む。

## classifier に対する振る舞い (全 role)

classifier に止められたら、別の手段 (別コマンド・別ツール・手動取得) で同じ結果を得ない。止められそうだからと自己判断で止まることもしない (まず実行し、止められてから考える)。

- 許可の要求 (ccmsg の say ツールの音声、[[notification-tips]]) は**止められたセッション自身**がその場で行い、ユーザの許可後に同じ操作を再実行する (classifier はその会話の文脈を見る)。委譲元・統括に「止められた」事実を報告してもよいが、「ユーザへの許可要求の通知は既にこちらで出した」と添える
- 尋ね方は、ccmsg の permit ツールがあれば**それを使う** (止められた行動 / 読ませたいファイルのパス / 許可してほしい内容 / コマンド全文を渡す。使い方は ccmsg の skill)。無ければ 2 文の定型: 「commit が止められました。実行してよければ `commitして良い` と言ってください。」= (1) 何が止められたかを 1 行、(2) そのまま実行に進める許可文を 1 つ。許可文には止められた操作の具体 (コマンドなら全文、ファイルを渡すならそのパス) を入れ、長ければコードブロックで複数行に分ける。渡すファイルの中身は本文に貼らず、パスを示して人に読んでもらう。ユーザがそれを言ったら同じ操作を書き換えずに再実行する
- permit の書き方: `blocked` / `intents` / `description` は簡潔に (1 文ずつ)。`intents` は個別に許可できるよう 1 操作 1 要素に分ける。削除は `rm` のコマンドとして `commands` に書く。出すのは止められた操作だけ (commit 等を先回りで含めない)
- `! <command>` を貼って手元実行してもらう形にしない: その実行は「ユーザが実行した」だけで同種操作の許可とは見なされず、エージェントの再実行は止められ続ける
- 許可も操作も他セッション経由で伝聞しない: 伝言の許可は効かない (classifier はその会話のユーザ発言しか見ない) ので、止められたセッション自身が permit を出す。止められた具体コマンドもユーザに伝聞しない (委譲元・統括への報告はよい)
- 止まり続けたら permit に出し直し、許可後も止まるなら kawaz が webui から実行する (繰り返し要る操作なら上の完全一致 allow を足す)
- in-process の subagent / チームメート (Agent tool) はユーザと直接話せず、許可の伝言も届かない。止められたら委譲元に報告して止まり、委譲元がその操作を自分で実行する (委譲元の会話にユーザの許可があれば通る)
