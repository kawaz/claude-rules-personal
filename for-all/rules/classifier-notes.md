# auto mode classifier への環境説明の置き場

auto mode の classifier は Claude と同じ CLAUDE.md / `.claude/rules/` と、user settings の `autoMode` を読む。classifier に教える環境説明は **置き場を 2 つに固定**し、他の rule や CLAUDE.md に混ぜない (混ぜると Claude の行動規範と classifier 向けの「許可の説明」が同居して肥大し、worker が許可を広げる方向に書き換える口になる)。

- **面横断** (信頼リポ、secrets の置き場、XDG 配下の自作ツール、セッション間の協調): user settings の `autoMode` (`environment` / `allow` / `soft_deny` / `hard_deny`)
- **プロジェクト固有**: `.claude/rules/classifier.local.md` **1 ファイルだけ**。正本は privacy リポの `classifier/classifier-<repo>.md` で、プロジェクト側はそこへの symlink (`.gitignore` に `.claude/rules/*.local.md`)

## 禁則

- `classifier.local.md` と settings の `autoMode` は **kawaz の明示指示なしに編集しない** (soft_deny にも同じ文を入れて classifier 側でも止める)
- `classifier.local.md` を classifier 向け以外の指示に流用しない。書式は箇条書きのみ (冒頭 1 行の用途宣言 + 4 見出し)。散文の段落を書かない
- 個別列挙より状況の包括記述を優先する。個別に書くのは名前で同一性を判定するもの (host / remote / path の例外) と deny だけ。entries は毎 check で context に載るので rule と同じ省コンテキストの規律

書式・設置手順・`autoMode` の 4 区分の意味は reference の `agent-runtime/auto-mode-classifier` を読む。
