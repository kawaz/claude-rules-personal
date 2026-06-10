# 既存ルール狭スコープ過剰特化 audit (2026-05-28)

## 要約

- 監査対象: `claude-rules-personal` の `for-all/rules/` 20 件 + `for-me/rules/` 13 件 = 33 件 (Phase 1 新規 5 件は対象外)
- 過剰特化疑い (高): 4 件
- 軽微な改善余地: 4 件
- memory (hyoui project): 7 件 (= 汎用化候補の指摘のみ、修正は別 task)
- **修正は本 task では行わず、本 findings に記録のみ**

## 監査結果

### ❌ 過剰特化疑い (= 高優先で見直し候補)

| ファイル | 観点 | 該当箇所 | 改善案 |
|---|---|---|---|
| `for-all/rules/jj-rebase-options-reference.md` | 狭スコープ前提 (jj 専用) + 大量 (164 行) | ファイル全体 | for-me/rules/ へ移設 (jj は kawaz 個人運用)。常時読み込み対象から外す |
| `for-all/rules/release-flow-awareness.md` | kawaz 個人ワークフロー強依存 (pkf / bump-semver / kawaz リポ前提) | 「kawaz リポでは」「canonical 実装: kawaz/bump-semver」等 | for-me/rules/ へ移設、または汎用部分 (= 「tag は CI/CD が打つ、人が tag を扱わない」原則) と kawaz 固有手順を分離 |
| `for-all/rules/playwright-cli-chrome-beta-multi-profile.md` | 狭スコープ (playwright-cli 利用時のみ) + 大量 (144 行) | ファイル全体 | for-me/rules/ へ移設、または「使うときだけ参照する reference」として lazy 化を検討 |
| `for-all/rules/agent-browser-session-isolation.md` | 狭スコープ (agent-browser 利用時のみ) | ファイル全体 | for-me/rules/ へ移設、または使用時のみ読み込まれる構造にする |

### ⚠️ 軽微な改善余地

| ファイル | 観点 | 改善案 |
|---|---|---|
| `for-all/rules/claude-config-dir-isolation.md` | kawaz 環境固有の `~/.claude-*` 運用前提 (139 行) | 概念 (走査汚染対策) と kawaz 固有運用を分離。前者を for-all、後者を for-me に |
| `for-all/rules/release-flow-awareness.md` | 上記とは別観点で、関連 rule ([[feedback_tag_release_boundary]]) への参照が auto-memory 経由で外部依存 | 汎用原則は self-contained にする |
| `for-me/rules/docs-structure.md` (166 行) | kawaz 個人 docs/ 規約として正しいが、参考実装リストが大量 (= kawaz/bump-semver, kuu.mbt 等 7+ リポ列挙) | 参考実装リストは別ファイル化、本体は規約のみに圧縮 |
| `for-me/rules/jj-workflow.md` (288 行) + `jj-tips.md` (380 行) | 適切なスコープだが合計 668 行と大量 | 内容は良質、ただし for-me でも常時読み込みなのでさらなる圧縮余地はある |

### ✅ 適切な抽象化 (= 抜粋、全部は列挙しない)

- `for-all/rules/design-thinking.md` — 抽象的、汎用的に妥当
- `for-all/rules/design-priority.md` — 原則のみで具体例最小限
- `for-all/rules/feedback-evaluation.md` — 構造化された汎用ルール
- `for-all/rules/research-documentation.md` — 汎用ワークフロー
- `for-all/rules/sanitize-work-identifiers.md` — overlay 連携前提だが概念は汎用化済み
- `for-all/rules/rule-writing-guidelines.md` — メタルールとして適切
- `for-me/rules/work-principles.md` — 個人原則として適切

## memory (hyoui project) の汎用化候補

memory はプロジェクト固有が本来役割だが、以下は他リポでも遭遇する pkf / jj の知見:

| ファイル | 汎用化候補性 | 提案 |
|---|---|---|
| `feedback_pkf_push_at_minus_pitfall.md` | 高 | pkf を使う全リポで同じ罠が出る → for-me/rules/push-workflow.md に追記候補 |
| `feedback_jj_worktree_shim_no_track.md` | 高 | jj-worktree shim を使う全リポで該当 → for-me/rules/jj-workflow.md に追記候補 |
| `feedback_other_repo_commit_linear_on_main.md` | 中 | 他リポへの貢献パターン → for-me/rules/ に新規 rule 候補 |
| `feedback_github_issue_vs_local_docs_issue.md` | 中 | docs-knowledge-flow.md と関連 |

(= 実際の汎用化は memory の本文確認が必要、本 task では指摘のみ)

## 改善 task の優先順 (= 別 task で対応)

1. **高**: jj-rebase-options-reference.md を for-me に移設 (= context 削減効果最大)
2. **高**: release-flow-awareness.md を for-me に移設 or 汎用部分を抽出
3. **中**: playwright-cli-chrome-beta-multi-profile.md を for-me に移設
4. **中**: agent-browser-session-isolation.md を for-me に移設
5. **中**: claude-config-dir-isolation.md を概念部分と kawaz 固有部分に分離
6. **低**: docs-structure.md の参考実装リスト分離
7. **低**: memory の汎用化候補を該当 rule に昇格

## 更新 (2026-05-28 後): jj 関連 3 件は skill 化で対応

優先順 1 (jj-rebase-options-reference) + jj-workflow.md / jj-tips.md (合計 668 行) は **常時読み込み rule から Claude Code Skill (frontmatter trigger) に移行** で context 削減を達成:

- `for-me/skills/jj-workflow/SKILL.md`
- `for-me/skills/jj-tips/SKILL.md`
- `for-me/skills/jj-rebase-options-reference/SKILL.md`

frontmatter の `description` で発火条件 (= jj リポでの作業、`jj <command>` を使う文脈) を絞り、jj を使わない作業中は load されない。元 rule .md は削除済み。

## 更新 (2026-05-28 後): agent-browser-session-isolation も skill 化で対応

優先順 4 (agent-browser-session-isolation) も **常時読み込み rule から Claude Code Skill (frontmatter trigger) に移行**:

- `for-me/skills/agent-browser-session-isolation/SKILL.md` 新設
- 元 `for-all/rules/agent-browser-session-isolation.md` 削除
- 参照側 `for-all/rules/playwright-cli-chrome-beta-multi-profile.md` の文中・関連リンクを skill 化済みである旨に更新

frontmatter の `description` で発火条件 (= `agent-browser` CLI 利用、または playwright-cli の session 命名規約参照) を絞り、無関係な作業中は load されない。

## 更新 (2026-05-28 後): docs-structure も skill 化 + テンプレ embed で対応

優先順 6 (docs-structure.md の参考実装リスト分離) は **常時読み込み rule から Claude Code Skill (frontmatter trigger) に移行 + テンプレファイルを skill ディレクトリ内に embed** で対応:

- `for-me/skills/docs-structure/SKILL.md` 新設 (= 元 rule の判断ロジックを保持)
- `for-me/skills/docs-structure/templates/` 配下にテンプレファイル一式を embed (README{,-ja} / DESIGN{,-ja} / STRUCTURE / ROADMAP / MANUAL{,-ja} / decisions/{DR-NNNN, INDEX} / issue / journal / findings / runbooks / research / knowledge / design)
- 元 `for-me/rules/docs-structure.md` 削除
- 参照側 `for-me/rules/docs-knowledge-flow.md` の文中・関連リンクを skill 化済みである旨に更新

project type 別 subdir 分離は **見送り** (= docs/ 構造自体は言語非依存。言語固有要素は Taskfile.pkl 側で吸収する設計なので、テンプレも全 project type 共通で OK)。

frontmatter の `description` で発火条件 (= docs/ 配下のファイル作成・編集、DR 起票、README/DESIGN 更新等) を絞り、docs 作業以外では load されない。テンプレ embed により「新規ファイル作成時の起点」が skill 内で完結し、毎回手書きで boilerplate を書かずに済む。

## 更新 (2026-06-10): playwright-cli profile + config-dir-isolation を skill 化 / 概念分離で対応

優先順 3 (playwright-cli-chrome-beta-multi-profile) と優先順 5 (claude-config-dir-isolation) を消化:

- **playwright-cli-chrome-beta-multi-profile**: `for-all/rules/playwright-cli-chrome-beta-multi-profile.md` を
  `for-all/skills/playwright-cli-chrome-beta-multi-profile/SKILL.md` に skill 化 (= 元 rule .md 削除)。
  frontmatter の `description` で発火条件 (= playwright-cli を Chrome Beta プロファイルで attach、
  `PLAYWRIGHT_MCP_EXTENSION_TOKEN` を扱う) を絞り + 負条件 (= playwright-cli を使わない作業では load 不要) を明記。
  slug は維持したので overlay の `[[playwright-cli-chrome-beta-multi-profile]]` 参照はそのまま解決する。
- **claude-config-dir-isolation**: `for-all/rules/claude-config-dir-isolation.md` は概念部分のみに縮小
  (= `~/.claude` regular file 化の理由 / 禁止事項 / 環境対応表 / overlay 一覧 / 越境の一般形)。
  「SSH 認証の切替メカニズム」の長い手順 (経路 A/B、`SSH_AUTH_SOCK` 一時切替、`signing.key` repo-local
  override) は `for-me/skills/cross-env-ssh-signing/SKILL.md` に分離 (= 越境 push/signing 時のみ必要)。
  rule 側は「SSH 認証の切替メカニズム」section 見出しを残し概念だけ書いて skill を指す形にしたので、
  emeradaco overlay の `[[claude-config-dir-isolation]]` の同名 section 参照は壊れない。

これで findings の改善 task は優先順 1〜6 が消化済み (= 残りは優先順 7 = memory 汎用化のみ)。

## 注

本 audit は「過剰特化していないか」のみを観点とし、内容の正しさ / 有用性は評価していない。
過剰特化と判定されたファイルも内容自体は有用 — 配置場所 / スコープの問題。
