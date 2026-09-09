# Git リポジトリ管理

## workflow の選択

VCS コマンド実行時に hook (`hooks/vcs-guide.sh`) が構成に応じた reference を案内する。

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
