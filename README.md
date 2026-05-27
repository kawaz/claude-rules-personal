# claude-rules-personal

kawaz の Claude Code 用ルール / スキルの **central リポジトリ**。
`claude-rules-*` overlay 群を束ね、`setup.sh` で各 `CLAUDE_CONFIG_DIR` に配備する。

## リポジトリ群の構成

`claude-rules-*` は 1 つの central + 複数の overlay で構成される。

| リポ | 役割 | 専用環境 (CLAUDE_CONFIG_DIR) |
|------|------|------|
| **kawaz/claude-rules-personal** (これ) | central。全 overlay を束ね、`setup.sh` / `repos_mapping.json` を持つ | `~/.claude-personal` |
| kawaz123/claude-rules-emeradaco | emeradaco 業務面の overlay (private) | `~/.claude-emeradaco` |
| kawaz/claude-rules-zunsystem | zunsystem 識別子 overlay (private) | (専用環境なし) |
| kawaz/claude-rules-syun | syun 識別子 overlay (private) | (専用環境なし) |

- `setup.sh` と `repos_mapping.json` は **この personal リポにのみ置く** (2 重管理しない)
- どの overlay のルール/スキルを変更しても、反映は **personal の `setup.sh` を実行**する
- 整理方法・設計判断などの詳細ドキュメントは **personal の `docs/` に集約**する

## レイアウト

各リポ共通:

- `for-all/rules/` — 全環境向けルール (全 `~/.claude*/rules/` に注入)
- `for-all/skills/<slug>/` — 全環境向けスキル
- `for-all/plugins.json` — Claude Code plugin の宣言 (setup.sh が install)
- `for-me/rules/`, `for-me/skills/<slug>/` — その面の専用環境にのみ注入
- `for-others/rules/` — 他環境から参照される情報 (固有名詞リスト等のサニタイズ規定)

`for-me` の "me" は「個人 vs 他者」ではなく、kawaz が持つ複数の面
(個人開発 / emeradaco 業務 / ...) のうちの **その overlay の面**を指す。

personal リポ固有:

- `setup.sh` — symlink ベースの配備スクリプト
- `repos_mapping.json` — 全 overlay リポと各 `home` (CLAUDE_CONFIG_DIR) の定義
- `docs/` — 設計判断・課題 (`issue/`)、運用手順 (`runbooks/`) 等

## セットアップ

配備先の `CLAUDE_CONFIG_DIR` を指定して `setup.sh` を実行する:

```bash
CLAUDE_CONFIG_DIR=~/.claude-personal  ./setup.sh
CLAUDE_CONFIG_DIR=~/.claude-emeradaco ./setup.sh
```

setup.sh は `repos_mapping.json` の全 overlay を読み:

- `for-*/rules/` を `$TARGET/rules/` 配下にディレクトリ symlink
- `for-*/skills/<slug>/` を `$TARGET/skills/<repo>-<slug>` に per-skill symlink
- `for-all/plugins.json` の plugin を `claude plugin install`
- 移動・削除された symlink の残骸 (dangling) を掃除

詳細は `./setup.sh --help`。

## ドキュメント

- `docs/issue/` — TODO・課題
- `docs/runbooks/` — 運用・セットアップ手順

## サニタイズ

業務固有名詞は public 候補の personal には置かず、各 overlay リポ (private) で管理。
共通サニタイズの仕組みは `for-all/rules/sanitize-work-identifiers.md` を参照。
