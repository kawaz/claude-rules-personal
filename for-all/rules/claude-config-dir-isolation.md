# `CLAUDE_CONFIG_DIR` 運用と `~/.claude` 汚染対策

kawaz の環境では、Claude Code の親ディレクトリ走査仕様による設定汚染を防ぐため、
**`CLAUDE_CONFIG_DIR` を常時明示指定する**運用にしている。本ファイルはその仕組みの正本。

## 背景: なぜ `~/.claude` を放置できないか

Claude Code は cwd から親ディレクトリへ向かって `.claude/rules/` 等を walk-up 探索する。
もし `~/.claude/rules/` が存在すると、`$HOME` 配下のあらゆる作業ディレクトリで
個人ルールが意図せず読み込まれてしまい、業務リポなど別環境の isolation が壊れる。

## 対策

### 1. `~/.claude` は regular file として置く

```bash
$ file ~/.claude
/Users/kawaz/.claude: Unicode text, UTF-8 text
```

- `mkdir ~/.claude` は "File exists" で失敗
- 何かが `~/.claude/foo` を読もうとすると ENOTDIR で失敗
- 物理的に `~/.claude/rules/` を作れないため、走査汚染が起こり得ない

### 2. `CLAUDE_CONFIG_DIR` を環境ごとに明示指定

| 環境 | CLAUDE_CONFIG_DIR | 設定場所 |
|------|------------------|---------|
| 個人面 (デフォルト) | `~/.claude-personal` | `~/.zshrc` で常時 export |
| 仕事面 (emeradaco) | `~/.claude-emeradaco` | `emeradaco/.envrc` で direnv 経由切替 |
| (将来追加分) | `~/.claude-<env>` | 各 overlay の `.envrc` で切替 |

direnv 経由で `cd` した瞬間に `CLAUDE_CONFIG_DIR` が切り替わるため、kawaz は環境を
意識せず作業できる。Claude Code 起動時に有効な `CLAUDE_CONFIG_DIR` の値が
そのセッションの面 (personal / emeradaco / ...) を決める。

### 3. 禁止事項

- **`~/.claude` を symlink で置き換えない** (`~/.claude -> ~/.claude-personal` 等)。
  symlink 経由でも walk-up 探索でヒットしてしまい、汚染問題が再発する。
- **`~/.claude/` をディレクトリとして再作成しない**。意図的に regular file にしている
  ことを知らずに `mkdir` を試みるツール (init スクリプト等) を見つけたら、
  そのツールを直すかオプションを切る。

## 関連 overlay リポ

各 overlay は `for-all/rules/` の symlink を `~/.claude-<env>/rules/for-all-from-<name>/`
として注入する。`for-me/rules/` は当該環境にのみ注入される。

| リポ | 環境 | 立ち位置 |
|------|------|---------|
| [kawaz/claude-rules-personal](https://github.com/kawaz/claude-rules-personal) | 全環境共通 + 個人面のみ | kawaz 個人ルール (public 候補) |
| [kawaz123/claude-rules-emeradaco](https://github.com/kawaz123/claude-rules-emeradaco) | emeradaco 仕事面 | emeradaco 仕事専用 (private) |
| [kawaz/claude-rules-zunsystem](https://github.com/kawaz/claude-rules-zunsystem) | zunsystem 面 | private overlay |
| [kawaz/claude-rules-syun](https://github.com/kawaz/claude-rules-syun) | syun 面 | private overlay |

各 overlay の固有情報 (アカウント区別、認証境界、越境手順等) は
それぞれの overlay 内で `for-all/rules/` または `for-me/rules/` として管理する。

## 越境作業の一般形

「いま `CLAUDE_CONFIG_DIR=~/.claude-X` で起動しているセッションで、別環境 Y の
ファイルを触ってほしい」という指示が来ることがある。このとき以下の手順で対応する:

```bash
# 環境 Y の作業ディレクトリへ cd した瞬間に direnv が .envrc を発火させて
# 環境変数 (CLAUDE_CONFIG_DIR は触らないが GH_CONFIG_DIR / SSH_AUTH_SOCK 等) が切替わる。
# サブシェル化 (( ... )) で囲むことで、cwd や env を元のセッションに残さない。
(cd /path/to/env-Y/<repo> && <command>)
```

注意:

- **Claude Code セッション自体の CLAUDE_CONFIG_DIR は変わらない** (起動時固定)。
  越境作業中も session の rules/settings/memory は元の環境のものを参照する
- **memory は越境しない**: 各環境の `$CLAUDE_CONFIG_DIR/projects/.../memory/` は別物
- **rules は越境する**: 本ファイルは `for-all/rules/` にあり、両環境 (personal /
  emeradaco / ...) の `rules/for-all-from-personal/` に symlink で注入されている

各環境固有の越境手順 (例: emeradaco なら gh トークン / SSH 鍵切替) は当該 overlay の
ルールを参照する。
