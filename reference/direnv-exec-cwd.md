# 別ディレクトリでコマンドを実行する形 (cd と direnv exec)

kawaz 環境はプロジェクト毎に `.envrc` で環境変数 (認証境界の `SSH_AUTH_SOCK` / `GH_CONFIG_DIR` / `CLAUDE_CONFIG_DIR` 等) を設定している。

**セッション起動時の cwd には direnv が既に適用されている** (Claude 自体が direnv の効いた shell から起動される)。**cwd 内 (= プロジェクトルート) で実行するコマンドには `cd` も `direnv exec` も付けない**。付けるのは別ディレクトリに出る時だけで、その時は Claude の Bash が非対話 shell で `cd` しても direnv hook が発火せず、`direnv exec` は env を注入するだけで cwd を変えないため、両方を組にする。

```bash
# Good — cwd 内。direnv は起動時に適用済み
just push

# 不要 — cwd 内なのに wrap している (動くが、写されて「常に wrap」の手癖になる)
(cd "$PWD" && direnv exec . just push)
direnv exec "$PWD" just push

# Good — 別ディレクトリ。env (.envrc) と cwd の両方が対象ディレクトリに揃う
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

## プロジェクトの scripts は自分で direnv を当てる

特定プロジェクトの環境 (その `.envrc` の認証境界・変数) を前提に動くスクリプト (`scripts/` 配下の観測・運用スクリプト等) は、呼び出し側に `(cd && direnv exec .)` を強いず、冒頭で自分のディレクトリに `cd` して `direnv exec` し直す (kawaz 2026-11-06)。別の `.envrc` が効いている場所から呼ばれても正しい環境に揃う。

```bash
set -euo pipefail
if [[ -z ${APPLIED_MY_DIRENV:-} ]]; then
  real0=$(realpath "$0")
  cd "$(dirname "$real0")" && APPLIED_MY_DIRENV=1 exec direnv exec . "$real0" "$@"
fi
unset APPLIED_MY_DIRENV
```

- 目印は自前の変数で持つ (`DIRENV_DIR` は「どこかの `.envrc` が当たっている」しか分からず、別リポから呼ばれた時に当て直せない)
- `exec` で親を置き換える (返ってきた親が本体をもう 1 回走らせないため)。`cd` の失敗は `set -e` で止まる
- 対象は「そのプロジェクトの環境で動くもの」だけ。`~/bin/` に置く汎用スクリプトのように呼び出し元の環境で動くべきものには入れない
