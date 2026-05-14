# claude-rules

Personal Claude Code rules. Distributable to `~/.claude/rules/` or
`~/.claude-work/rules/` via `install.sh`.

## Layout

- `common/rules/`       — 両環境で使う汎用ルール (公開可能)
- `personal/rules/`     — 個人開発 (`~/.claude`) 専用
- `work-overlay/rules/` — 仕事用 (`~/.claude-work`) 専用 (固有名詞ゼロ)
- `install.sh`          — symlink ベースの配布スクリプト

## Install

```bash
./install.sh personal \
  --overlay ../claude-rules-emeradaco/main \
  --overlay ../claude-rules-zunsystem/main \
  --overlay ../claude-rules-syun/main
```

Directory symlinks (not file symlinks) を使うので、新規 `.md` を追加しても
install.sh の再実行は不要。

## 関連リポ

業務固有名詞のサニタイズ対象リストは別の overlay リポで管理:

- `kawaz123/claude-rules-emeradaco` — emeradaco 関連 (private)
- `kawaz/claude-rules-zunsystem` — zunsystem 関連 (private)
- `kawaz/claude-rules-syun` — syun 関連 (private)

共通サニタイズの仕組みは `common/rules/sanitize-work-identifiers.md` を参照。
