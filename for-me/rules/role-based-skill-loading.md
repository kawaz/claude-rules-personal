# Role-based skill loading — 役割別必須スキルのロード

役割ごとに必要なルールを skill に切り出し、セッション開始時に role を判定して対応するローダーを invoke することで、role 別に必要なものだけロードする。

## セッション開始時の必須手順

セッション開始時 (or /clear 後) に、以下を最初に実行:

### 1. 自分の role を判定

- system prompt のモデル ID / effort / agent 定義 frontmatter (`~/.claude-personal/agents/*.md`) から自 role を判定
- 判定不能時は **`main`** を safe default (統括扱い、過剰ロードでも動作)

### 2. role 分類

| role | 該当ケース | ロード skill |
|---|---|---|
| `main` | フロントエンドで直接ユーザと会話する統括、任意のプロジェクトを指揮 | `load-role-main` |
| `worker` | Agent tool 経由の実作業サブエージェント (実装 / リサーチ / journal 執筆 等) | agent frontmatter で必要な skill を明示指定 |
| `reviewer` | Agent tool 経由の read-only 検査サブエージェント | agent frontmatter で必要な skill を明示指定 |

### 3. `load-role-{name}` を Skill tool で invoke

判定した role に対応する `load-role-{name}` を Skill tool で invoke。ロード後、そのスキルの本文に列挙された全 skill を Skill tool で順次 invoke する ([[role-main-context]] 等、3〜10 個の関連 skill が並ぶ)。Skill 内から別 Skill を自動ロードする機構は無いので、**AI が本文の指示を必ず履行する**。

## 命名規約

- **役割スキル本体**: `role-{name}-{suffix}` (例: `role-main-context`)
- **ローダースキル**: `load-role-{name}` (例: `load-role-main`)
