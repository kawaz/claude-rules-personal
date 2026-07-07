---
name: git-worktree-workflow
description: "`.jj` が存在しない git 専用リポでの git bare + worktree 方式の作業手順書。ディレクトリ構成 (bare repo + 兄弟 worktree)、feature/fix/docs ブランチ命名、worktree 命名 (issue 番号 / pr 番号 / wip)、リポジトリ親の特定コマンド、PR-base ブランチの初回作成、新規 PR 作成フロー、wip → PR 昇格 (branch -m → push -u → worktree move)、pre-commit 自動修正時の amend を扱う。`.jj` が無い git リポで worktree / PR 作成の作業を始めるときに使う。`.jj` があるリポは jj-workflow skill が正。"
---

# Git ワークフロー（git bare + worktree 方式）

`.jj` が存在しないリポジトリで適用。`.jj` がある場合は jj-workflow skill (git bare + jj workspace 方式) に従う。

## ディレクトリ構成

```
~/.local/share/repos/{host}/{org-user}/{repo}/
  .git/           # bare repository（上位リポジトリ探索の打ち止め役も兼ねる）
  .envrc          # リポジトリ共通の環境設定
  .claude/        # リポジトリ共通の個人用Claude設定（git管理外）
  {main}/         # メインブランチのworktree
  {worktree}/     # 作業用worktree
```

リポジトリ親（`{repo}/`）が共有設定の置き場。各worktreeはその直下に兄弟として並ぶ。
repo直下に `.git`(bare) があることで、上位の `.git` への探索が打ち止めになり事故を防ぐ。
bare なので repo 直下で `git status` しても作業ツリーとしては機能しない。

## ブランチ命名

feature/, refactor/, fix/, docs/ プレフィックスを使用。

## Worktree

リポジトリ親ディレクトリ内にworktreeとして作成。

命名: `{種別}{番号}-{ブランチ名}`
- Issue起点: `1234-feature-xxx`
- PR引き継ぎ: `pr1234-feature-xxx`
- レビュー: `review1234-xxx`
- ローカル: `wip-xxx`

### リポジトリ親の特定

worktreeの作業ディレクトリ内から：

```bash
REPO_ROOT=$(git rev-parse --git-common-dir | sed 's|/\.git$||')
```

### 作成後

フルパスを省略せず報告。

## PR

### PR-baseブランチ（初回のみ作成）

リポジトリ親で実行：

```bash
git branch pr-base origin/HEAD
TREE=$(git rev-parse pr-base^{tree})
COMMIT=$(git commit-tree "$TREE" -p pr-base -m "chore: PR番号取得用")
git update-ref refs/heads/pr-base "$COMMIT"
```

### 新規PR

```bash
git fetch origin
git update-ref refs/heads/pr-base origin/HEAD
git push origin pr-base:{branch}
gh pr create --repo {owner}/{repo} --head {branch} --title "..." --body "..."
# → PR番号でworktree作成
```

### wip → PR昇格

`git branch -m` → `git push -u` → `gh pr create` → `git worktree move`
**注意**: move後にcwdが消失。move前に新パス（フルパス）を案内。

### push後

PRのURL表示。ブランチ名の数字はIssue番号の可能性があるので `gh pr` で確認。

## コミット

pre-commitフックで自動修正があった場合、内容確認して問題なければ自動amend。
