# `CLAUDE_CONFIG_DIR` 運用と `~/.claude` 汚染対策 (禁則)

kawaz の環境は Claude Code の親ディレクトリ走査による設定汚染を防ぐため、
`CLAUDE_CONFIG_DIR` を常時明示指定する運用。セッションの面 (personal /
emeradaco / ...) は起動時の `CLAUDE_CONFIG_DIR` の値で決まり、途中で変わらない。

## 禁則

- **`~/.claude` は意図的に regular file として置いてある**。
  `mkdir ~/.claude` や directory としての再作成は禁止。`~/.claude/foo` を
  作ろうとするツールを見つけたら、そのツールを直すかオプションで切る
- **`~/.claude` を symlink で置き換えない** (`~/.claude -> ~/.claude-personal`
  等)。symlink 経由でも walk-up 探索でヒットし、`$HOME` 配下全域で個人ルール
  が意図せず読み込まれる汚染が再発する
- 環境ごとの `CLAUDE_CONFIG_DIR` は `~/.zshrc` (個人面デフォルト) と各 overlay
  の `.envrc` (direnv) が正本。rule 側に環境一覧を複製しない
  (repos_mapping.json 参照)

## 越境作業

別環境のリポを触る指示が来たら、基本形は
`direnv exec /path/to/env-Y/<repo> -- <command>` — .envrc の環境変数
(SSH_AUTH_SOCK / GH_CONFIG_DIR 等) が確実に適用される。
`(cd ... && <command>)` のサブシェルは Claude の非対話 shell では
**direnv hook が発火せず** .envrc が乗らない ([[tooling-tips]] の実測参照)。
`~/.ssh/config` の Match exec (cwd/remote 判定) は cd でも効くが、
env 由来の切替 (jj signing 等) は direnv exec が必要。rules は全環境に
注入されるが memory は越境しない。**push / commit signing を伴う越境**は
認証が2経路あり、`cross-env-ssh-signing` skill の手順に従う。
