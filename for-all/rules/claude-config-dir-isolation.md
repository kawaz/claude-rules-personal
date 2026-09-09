# `CLAUDE_CONFIG_DIR` 運用と `~/.claude` 汚染対策 (禁則)

kawaz の環境は Claude Code の親ディレクトリ走査による設定汚染を防ぐため、`CLAUDE_CONFIG_DIR` を常時明示指定する運用。セッションの面 (personal / emrd / ...) は起動時の `CLAUDE_CONFIG_DIR` の値で決まり、途中で変わらない。

**面が分かれていても全部 kawaz 個人のルール**。業務面のルールも「仕事のチームで共有するもの」ではなく、**作業場所に応じた差分を持つ個人ルール**にすぎない。分離しているのは情報の越境を防ぐためであって、別人格を作るためではない (= worker さばきや VCS 手順のように場所に依らず要るものは、面をまたいで同じ)。

## 禁則

- **`~/.claude` は意図的に regular file として置いてある**。`mkdir ~/.claude` や directory としての再作成は禁止。`~/.claude/foo` を作ろうとするツールを見つけたら、そのツールを直すかオプションで切る
- **`~/.claude` を symlink で置き換えない** (`~/.claude -> ~/.claude-personal` 等)。symlink 経由でも walk-up 探索でヒットし、`$HOME` 配下全域で個人ルールが意図せず読み込まれる汚染が再発する
- 環境ごとの `CLAUDE_CONFIG_DIR` は `~/.zshrc` (個人面デフォルト) と各 overlay の `.envrc` (direnv) が正本。rule 側に環境一覧を複製しない (repos_mapping.json 参照)

## 越境作業

別環境のリポを触る指示が来たら `(cd /path/to/env-Y/<repo> && direnv exec . <command>)` を基本形にする ([[tooling-tips]] が正本)。rules は全環境に注入されるが memory は越境しない。**push / commit signing を伴う越境**は認証が 2 経路あり、`knowledge` skill の `cross-env-ssh-signing` を参照。
