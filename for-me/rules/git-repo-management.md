# Git リポジトリ管理

## workflow の選択

worktree / commit / PR 作業は reference の `vcs/_index` で構成を見分け、該当する本文に従う。

## パス規約

`${XDG_DATA_HOME:-$HOME/.local/share}/repos/{host}/{owner}/{repo}/`

## 新規リポジトリ作成

| owner | 公開設定 | 備考 |
|-------|---------|------|
| kawaz | public | 個人OSS |
| 業務用アカウント (名は privacy リポの `kawaz-identity`) | **private** | |
| その他 | private | |

## ライセンス

MIT License, Yoshiaki Kawazu (@kawaz)
