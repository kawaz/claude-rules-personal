# Git リポジトリ管理

## workflow の選択

worktree / commit / PR 作業は `.jj/` 有 → `jj-workflow` skill、
無 (`.git` のみ) → `git-worktree-workflow` skill に従う。

## パス規約

`${XDG_DATA_HOME:-$HOME/.local/share}/repos/{host}/{owner}/{repo}/`

## 新規リポジトリ作成

| owner | 公開設定 | 備考 |
|-------|---------|------|
| kawaz | public | 個人OSS |
| kawaz123 | **private** | エメラダ仕事用アカウント |
| その他 | private | |

## ライセンス

MIT License, Yoshiaki Kawazu (@kawaz)
