# ツール利用の tips

## Bash: 別ディレクトリでのコマンド実行は `direnv exec`

別ディレクトリでコマンドを実行する時は `direnv exec` を基本にする。

```bash
# Good — .envrc の環境変数 (SSH_AUTH_SOCK / GH_CONFIG_DIR 等) が正しく適用される
direnv exec /path/to/dir command args...

# Bad — `--` は不要かつ有害 (direnv が `--` をコマンド名として解釈しエラーになる。実測 2026-07-23)
direnv exec /path/to/dir -- command args...

# 許容 — direnv 管理外のディレクトリ、または .envrc に依存しない操作
(cd /path/to/dir && command)

# Bad — ユーザの cwd が変わる
cd /path/to/dir && command
```

**Why**: kawaz 環境はプロジェクト毎に `.envrc` で環境変数 (認証境界の
SSH_AUTH_SOCK / GH_CONFIG_DIR / CLAUDE_CONFIG_DIR 等) を設定している。
Claude の Bash は非対話 shell で **cd しても direnv hook が発火しない**ため、
`(cd dir && git push)` は别アカウント鍵のまま実行される事故につながる
(実測: emeradaco リポで cd only だと SSH_AUTH_SOCK が kawaz 鍵のまま、
`direnv exec` なら emerada 鍵に切替。2026-07-23 確認)。

- 特に **git push / gh / ssh を伴う越境操作は direnv exec 必須**
- `git -C dir push` も同じ理由で direnv の env が乗らないので避ける
- direnv 未 allow のディレクトリでは `direnv exec` がエラーになる —
  その場合は指示を仰ぐ (勝手に `direnv allow` しない)

## Bash: `!` を含むコマンドの実行

`!` が `\!` にエスケープされる問題の回避策：

```bash
cat << 'EOF' | bash
echo 'Hello!'
EOF
```

## CLI ベンチマーク

コマンドのベンチマークには `hyperfine` を使用する。
