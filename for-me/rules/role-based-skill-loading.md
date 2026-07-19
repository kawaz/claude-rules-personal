# Role-based skill loading — 常駐ルール最小化 + 役割別必須スキル自動ロード

**目的**: 常駐ルール (rules/*.md) が肥大すると全ロード必須の負担が増える。役割ごとに必要なルールを skill に切り出して、セッション開始時に role 判定して `load_{role}_skill` を invoke することで、role 別に必要なものだけロードする ([[main-context-role]] は統括メインでのみ必須、ワーカー / レビュワーには不要 等)。

## セッション開始時の必須手順

セッション開始時 (or /clear 後) に、以下を最初に実行:

### 1. 自分の role を判定

- system prompt のモデル ID / effort / agent 定義 frontmatter (`~/.claude-personal/agents/*.md`) から自 role を判定
- 判定不能時は **`main`** を safe default (統括扱い、過剰ロードでも動作)

### 2. 現状の role 分類 (v1)

| role | 該当ケース | ロード skill |
|---|---|---|
| `main` | フロントエンドで直接ユーザと会話する統括、任意のプロジェクトを指揮 | `load-role-main` |
| `worker` | Agent tool 経由の実作業サブエージェント (実装 / リサーチ / journal 執筆 等) | (現状無し、agent frontmatter で必要な skill を明示指定) |
| `reviewer` | Agent tool 経由の read-only 検査サブエージェント | (現状無し) |

## 命名規約 (kawaz mid=45)

role skill が複数 role に増えた時のソート順管理のため、prefix を統一:

- **役割スキル本体**: `role-{name}-{suffix}` (例: `role-main-context`、将来 `role-main-etiquette` 等)
- **ローダースキル**: `load-role-{name}` (例: `load-role-main`、将来 `load-role-worker` / `load-role-reviewer`)

これで全 role skill / loader が `role-*` / `load-role-*` prefix で始まる = ソート隣接で管理容易。

### 3. `load-role-{name}` を Skill tool で invoke

判定した role に対応する `load-role-{name}` を Skill tool で invoke。ロード後、そのスキルの本文に列挙された全 skill を Skill tool で順次 invoke する ([[role-main-context]] 等、statistically 3〜10 個の関連 skill が並ぶ)。

**例** (統括メイン開始時):
1. `Skill(skill: "load-role-main")` を呼ぶ
2. load-role-main の本文に「以下を Skill tool で全部 invoke: `role-main-context`, `personal-worker-fleet`, `personal-orchestrate`」と書いてある
3. AI が列挙された各 skill を Skill tool で順次 invoke

**強制力**: Claude Code 標準に「Skill 内から別 Skill を自動ロード」する機構は無い (2026-07-20 時点、`@ファイル名` の記法は本文の linkify 用途で、ロード命令ではない)。したがって本ルールは **AI の指示履行に依存**する。統括 role として動く AI は、load-main-skill 本文の指示を必ず履行する。

## 常駐ルール最小化の方針

- **常駐 (rules/*.md)** = 全 role で必須の絶対禁則・行動制約 (押しつぶし禁止・rm -rf 禁止・commit 前の path 指定 等)
- **role 固有スキル** = role で違う運用 (統括の worker 選定 / worker の実装規約 / reviewer の検査観点 等)
- 大きい常駐ルールから優先的に role 固有スキルへ移動、常駐は行動制約の骨格のみ

## 関連

- [[role-main-context]] — 統括メインの役割本体 (`load-role-main` から invoke される)
- `for-me/skills/load-role-main/SKILL.md` — 統括メインの必須 skill リストと invoke 指示
