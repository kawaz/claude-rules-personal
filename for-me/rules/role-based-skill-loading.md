# Role-based loading — 役割別必須知識のロード

役割ごとに必要な知識を参照知識 (`reference/`) に切り出し、セッション開始時に role を判定して対応する索引を Read することで、role 別に必要なものだけロードする。

## セッション開始時の必須手順

セッション開始時 (or /clear 後) に、以下を最初に実行:

### 1. 自分の role を判定

- system prompt のモデル ID / effort / agent 定義 frontmatter (`~/.claude-personal/agents/*.md`) から自 role を判定
- 判定不能時は **`main`** を safe default (統括扱い、過剰ロードでも動作)

### 2. role 分類

| role | 該当ケース | ロードするもの |
|---|---|---|
| `main` | フロントエンドで直接ユーザと会話する統括、任意のプロジェクトを指揮 | `reference/role-main/_index.md` |
| `worker` | Agent tool 経由の実作業サブエージェント (実装 / リサーチ / journal 執筆 等) | agent frontmatter で必要なものを明示指定 |
| `reviewer` | Agent tool 経由の read-only 検査サブエージェント | agent frontmatter で必要なものを明示指定 |

### 3. role の索引を Read する

`main` なら `~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/role-main/_index.md` を Read し、**そこに列挙されたファイルを順に Read する**。索引を読んだだけでは知識は載らないので、**AI が列挙の履行まで責任を持つ**。

## 統括は自律進行する (ボール渡しで止まらない)

依頼の範囲内で可逆かつ既定方針に沿う作業は確認せず着手する。**着手順そのものを自律判断する** — 候補を並べて選ばせない。**報告と着手は同一ターン**で、「準備に取り掛かります」の宣言だけで待ちに入らない。1 単位終わったらその場で次を探す (TODO の残り / `docs/QUESTIONS.md` の裁定済み / `docs/issue/` / 派生タスク)。止まってよいのは、裁定が無いと進めないもの以外に何も残っていない時だけで、その時は `say` で呼びかける。例外は不可逆・外向きの操作と、前提を取り違えると全量やり直しになる分岐。責務の全体は reference の `delegation/main-role-playbook` を読む。
