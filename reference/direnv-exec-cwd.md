# 別ディレクトリでコマンドを実行する形 (cd と direnv exec)

kawaz 環境はプロジェクト毎に `.envrc` で環境変数 (認証境界の `SSH_AUTH_SOCK` / `GH_CONFIG_DIR` / `CLAUDE_CONFIG_DIR` 等) を設定している。Claude の Bash は非対話 shell なので **cd しても direnv hook が発火しない**。一方 `direnv exec` は **env を注入するだけで cwd を変えない**。片方だけでは必ずどちらかの罠を踏む。

```bash
# Good — env (.envrc) と cwd の両方が対象ディレクトリに揃う
(cd /path/to/dir && direnv exec . command args...)

# Bad — env は乗るが cwd が呼び出し元のまま。cwd 依存ツール (jj / git /
# 相対パス解決) が「別リポの状態を観測する」事故になる
direnv exec /path/to/dir command args...

# Bad — `--` は不要かつ有害 (direnv が `--` をコマンド名として解釈しエラーになる)
direnv exec /path/to/dir -- command args...

# 許容 — direnv 管理外のディレクトリ、または .envrc に依存しない操作
(cd /path/to/dir && command)

# Bad — ユーザの cwd が変わる (subshell 化しない裸の cd)
cd /path/to/dir && command
```

- `cd` だけで `git push` すると、別アカウントの鍵のまま実行される (SSH_AUTH_SOCK が切り替わらない)
- `direnv exec` だけで `jj` を実行すると、別リポの `@` を誤観測する
- `git -C dir push` も `direnv exec` を経由しないので同じ理由で避ける
- 特に **git push / gh / ssh を伴う越境操作は direnv exec 必須**
- direnv 未 allow のディレクトリでは `direnv exec` がエラーになる。勝手に `direnv allow` せず指示を仰ぐ
