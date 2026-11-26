# 別ディレクトリでコマンドを実行する形 (cd と direnv exec)

kawaz 環境はプロジェクト毎に `.envrc` で環境変数 (認証境界の `SSH_AUTH_SOCK` / `GH_CONFIG_DIR` / `CLAUDE_CONFIG_DIR` 等) を設定している。

**セッション起動時の cwd には direnv が既に適用されている** (Claude 自体が direnv の効いた shell から起動される)。**cwd 内 (= プロジェクトルート) で実行するコマンドには `cd` も `direnv exec` も付けない**。別ディレクトリに出る時は、行き先を治める `.envrc` が今のセッションの物と同じかで形が分かれる。

| 行き先 | 形 |
|---|---|
| 今のセッションと同じ `.envrc` の下 (同じ owner の隣のリポ等) | `(cd /path/to/dir && command)`。`direnv exec` は付けない |
| 違う `.envrc` の下 (別の面・別のアカウント)、または自前の `.envrc` を持つ | `(cd /path/to/dir && direnv exec . command)` |

- `.envrc` は owner のディレクトリ (`~/.local/share/repos/github.com/<owner>/.envrc`) にあるのが普通で、同じ owner のリポ同士は同じ env になる。リポ自身が `.envrc` を持つ時は、その限りでない
- 見分け方: 行き先から上に辿って最初に見つかる `.envrc` が、cwd から辿った物と同じファイルか
- 同じ env の所に `direnv exec` を付けても env は変わらない。auto mode の classifier は `cd <dir> && direnv exec . <push 等>` の形を止めることがあり (実例 2026-11-24: 隣のリポの `just push`)、`direnv exec` を外した形は通った
- 違う env の所では、Claude の Bash が非対話 shell で `cd` しても direnv hook が発火せず、`direnv exec` は env を注入するだけで cwd を変えないため、両方を組にする

```bash
# Good — cwd 内。direnv は起動時に適用済み
just push

# 不要 — cwd 内なのに wrap している (動くが、写されて「常に wrap」の手癖になる)
(cd "$PWD" && direnv exec . just push)
direnv exec "$PWD" just push

# Good — 別ディレクトリで、同じ .envrc の下 (同じ owner の隣のリポ)。env は既に同じ
(cd /path/to/sibling-repo && just push)

# Good — 別ディレクトリで、違う .envrc の下。env (.envrc) と cwd の両方が対象ディレクトリに揃う
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

違う `.envrc` の下に出る時に落ちる罠:

- `cd` だけで `git push` すると、別アカウントの鍵のまま実行される (SSH_AUTH_SOCK が切り替わらない)
- `direnv exec` だけで `jj` を実行すると、別リポの `@` を誤観測する
- `git -C dir push` も `direnv exec` を経由しないので同じ理由で避ける
- 特に **別の面・別のアカウントへの git push / gh / ssh を伴う越境操作は direnv exec 必須**
- direnv 未 allow のディレクトリでは `direnv exec` がエラーになる。勝手に `direnv allow` せず指示を仰ぐ

## プロジェクトの scripts は自分で direnv を当てる

特定プロジェクトの環境 (その `.envrc` の認証境界・変数) を前提に動くスクリプト (`scripts/` 配下の観測・運用スクリプト等) は、呼び出し側に `(cd && direnv exec .)` を強いず、冒頭で自分のディレクトリに `cd` して `direnv exec` し直す。別の `.envrc` が効いている場所から呼ばれても正しい環境に揃う。

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
