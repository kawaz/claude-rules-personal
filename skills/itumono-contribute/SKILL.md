---
name: itumono-contribute
description: 他者リポジトリへのコントリビューション（調査→実装→PR提出）
---

引数: upstream リポジトリURL（例: moonbitlang/moon）、修正内容の概要

# コントリビューションワークフロー

他者の公開リポジトリに対してパッチを作成し、PR を提出するまでの定型フロー。

## 自分用ファイルの命名規約

検討 WS に作成する自分用ファイルは、upstream のファイルと明確に区別するため **`.{user}-contrib/` ディレクトリ** に格納する（`{user}` は fork した GitHub ユーザー名）。このディレクトリは `.gitignore` に追加するか、コミット対象外とする。

```
{feature-name}/
  .{user}-contrib/             ← 自分用（PR に含めない）
    NOTES.md                   ← 検討ノート
    UPSTREAM_RULES.md          ← upstream のルール・慣習まとめ
    ISSUE_DRAFT.md              ← Issue 下書き
    SESSION_PROMPT.md          ← 別セッション引き継ぎ用プロンプト
  (upstream のソースコード)     ← リポジトリ本来のファイル
```

## フェーズ0: リポジトリセットアップ

### 0.1 Fork & Clone

jj-workflow.md の「git bare + jj workspace 方式（fork して clone）」に従ってセットアップ。

### 0.2 ワークスペース構成

main WS に加えて、検討用と実装用のワークスペースを作成:

| WS | 用途 |
|---|---|
| `main/` | upstream 追従・CI トリガー用 |
| `{feature-name}/` | コントリビューション検討・コンテキスト管理 |
| `{feature-name}-impl/` | 実装用 |

```bash
jj workspace add ../{feature-name} --name {feature-name} -r main@upstream
jj workspace add ../{feature-name}-impl --name {feature-name}-impl -r main@upstream
```

## フェーズ1: コミュニティ・リポジトリ調査（必須）

**upstream のルール・慣習を把握してから動く。** 調査結果は全て `.{user}-contrib/UPSTREAM_RULES.md` に記録する。

### 1.1 コントリビューションドキュメント

以下を全てチェックし、存在するものを読む:
- `README.md` — 開発者向けセクション
- `CONTRIBUTING.md` / `CONTRIBUTING`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`
- `docs/dev/` や `docs/contributing/` 配下
- `DEVELOPMENT.md` / `HACKING.md`
- ライセンス（`LICENSE` / `LICENSE.md`）— CLA 要求の有無

### 1.2 GitHub テンプレート・設定

```bash
# Issue テンプレート
ls .github/ISSUE_TEMPLATE/ 2>/dev/null
cat .github/ISSUE_TEMPLATE/*.md .github/ISSUE_TEMPLATE/*.yml 2>/dev/null

# PR テンプレート
cat .github/PULL_REQUEST_TEMPLATE.md .github/pull_request_template.md 2>/dev/null

# GitHub Actions ワークフロー（CI/CD 構成）
ls .github/workflows/
# 各ワークフローのトリガー条件・ジョブ構成を把握
```

### 1.3 GitHub 機能の利用状況

```bash
# Wiki の有無
gh api repos/{owner}/{repo} --jq '.has_wiki'

# Discussions の有無
gh api repos/{owner}/{repo} --jq '.has_discussions'

# 最近の PR のマージ方式（squash? merge? rebase?）を確認
gh pr list --repo {owner}/{repo} --state merged --limit 5 --json number,title,mergeCommit
```

### 1.4 コミュニティの慣習

```bash
# 最近マージされた PR のパターンを確認（タイトル規約、レビュー体制、CI 要件）
gh pr list --repo {owner}/{repo} --state merged --limit 10 --json number,title,labels,reviewDecision

# Issue の運用（ラベル、テンプレート使用率）
gh issue list --repo {owner}/{repo} --limit 10 --json number,title,labels
```

### 1.5 `.{user}-contrib/UPSTREAM_RULES.md` の作成

```markdown
# Upstream ルール・慣習

## コントリビューションガイド
{CONTRIBUTING.md の要約、CLA の有無、コード規約}

## Issue/PR テンプレート
{テンプレートの有無と内容要約}

## CI/CD
{ワークフロー構成、必須チェック、トリガー条件}

## マージ戦略
{squash/merge/rebase、ブランチ規約}

## コミットメッセージ規約
{conventional commits? 自由形式? 例}

## レビュー体制
{必須レビュアー数、CODEOWNERS の有無}

## 遵守事項チェックリスト
- [ ] ...
```

## フェーズ1.5: 検討 WS の初期ファイル作成

`.{user}-contrib/NOTES.md` — 検討ノート。冒頭に必ず以下を記載:

```markdown
## 必読
このWSで作業する際は、必ず先に `.{user}-contrib/UPSTREAM_RULES.md` を読み、
リポジトリオーナーのルール・コミュニティ慣習に則って行動すること。

## ワークスペース構成
...
## 問題の概要と背景
...
## 技術調査の結果
...
## Discussion Points
...
```

## フェーズ2: 既存コード調査

### 2.1 コードの理解
- upstream のアーキテクチャ、テスト方式を把握
- **全バックエンド・全ターゲットでの既存機能を体系的に理解する**（一部だけ見て進めない）
- 関連する Issue や PR を確認

### 2.2 影響範囲の特定
- 変更が必要なファイルを特定
- 既存テストの確認
- 既存の類似機能があれば設計パターンを参考にする

### 2.3 調査結果を `.{user}-contrib/NOTES.md` に記録

## フェーズ3: Issue Draft 作成

PR の前に Issue で設計を議論する場合（推奨）:

`.{user}-contrib/ISSUE_DRAFT.md` を作成:
- Motivation
- Proposed Design（設定例・コード例を含む）
- Implementation Overview（fork へのリンク）
- Known Limitations
- Discussion Points

**Issue テンプレートがある場合はそれに従う。**

## フェーズ4: 実装

`{feature-name}-impl/` ワークスペースで `/itumono-full-loop` を実行。

注意:
- **`.{user}-contrib/UPSTREAM_RULES.md` の遵守事項を満たすこと**（fmt, lint, テスト、コミットメッセージ規約等）
- PR に含めないファイル（メモ、ログ等）は検討 WS の `.{user}-contrib/` に置く
- キリの良いタイミングでコミット

## フェーズ5: CI 検証

### 5.1 fork の CI を有効化
```bash
# ワークフロー一覧と状態確認
gh api repos/{user}/{repo}/actions/workflows --jq '.workflows[] | "\(.name): \(.state)"'

# 必要なワークフローのみ有効化（CD, Pages 等は無効化）
gh api -X PUT repos/{user}/{repo}/actions/workflows/{id}/enable
gh api -X PUT repos/{user}/{repo}/actions/workflows/{id}/disable
```

### 5.2 Push して CI 実行
```bash
jj bookmark set {branch-name} -r @
jj bookmark set main -r @  # main への push で CI トリガー
jj git push --bookmark main --bookmark {branch-name}
```

### 5.3 CI 結果確認
```bash
gh run list --repo {user}/{repo} --workflow=CI --limit 3
gh run view {run-id} --repo {user}/{repo} --log
```

CI 失敗時は修正→push→再確認のループ。

## フェーズ6: PR 提出

### 6.1 コミット整理
- 不要なコミット（trigger CI 等）を squash
- PR-1, PR-2 等に分割する場合は jj split を活用
- `.{user}-contrib/` 配下やその他の開発メモは除外
- **コミットメッセージは `.{user}-contrib/UPSTREAM_RULES.md` の規約に従う**

### 6.2 PR 作成
```bash
gh pr create --repo {owner}/{repo} --head {user}:{branch} \
  --title "feat: ..." --body "$(cat .{user}-contrib/ISSUE_DRAFT.md)"
```
**PR テンプレートがある場合はそれに従う。**

### 6.3 レビュー対応
- レビューコメントへの対応は実装 WS で修正→push
- upstream の main が進んでいたら rebase:
  ```bash
  jj git fetch --remote upstream
  jj rebase --branch @ --onto main@upstream
  ```

## フェーズ7: マルチアプローチ（オプション）

同じ問題に複数の解法がある場合:

```
{repo}/
  main/                    ← upstream 追従
  {feature}/               ← 検討WS（比較・最終判断）
  {feature}-{approach-a}/  ← 実装A
  {feature}-{approach-b}/  ← 実装B
```

- 各実装 WS で独立に開発
- 検討 WS の `.{user}-contrib/NOTES.md` で比較表を管理
- 両方の実装が揃ってから使い勝手を比較して PR を選択

## 別セッションへの引き継ぎ

検討 WS に `.{user}-contrib/SESSION_PROMPT.md` を作成し、新セッション用の初期プロンプトを記載。
**必ず `.{user}-contrib/UPSTREAM_RULES.md` と `.{user}-contrib/NOTES.md` を読む指示を含める。**

```
{feature-name}/.{user}-contrib/SESSION_PROMPT.md を読んで作業を開始してください。
```
