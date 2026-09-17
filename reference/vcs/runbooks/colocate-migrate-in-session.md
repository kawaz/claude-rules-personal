# 旧方式リポを colocate へ移す — Claude セッションの中から (cwd を失わずに)

reference の `vcs/jj-colocate-setup` の「移行」を、そのリポを cwd にしている Claude セッション自身が実行するときの手順。`runbooks/` の手順書 (移行のときだけ `jj-colocate-setup` から辿る)。

## 落とし穴

- Bash ツールの cwd はリポの `main/` にある。`mv` した瞬間に cwd は退避先の inode の上に乗り、次の呼び出しで元のパスへ `cd` し直せない (まだ無い)。**退避 → clone → 初期化 → 親ガード → `cd` 新 `main/` を絶対パスだけで 1 回の Bash 呼び出しに `&&` で繋ぐ**。先頭で `cd /private/tmp` して古い cwd から降りてから始める
- clone では戻らないものがある。移行前に旧 `main/` で `git status --ignored --short | grep '^!!'` を取り、追跡外で必要なもの (`.envrc`、`*.local.code-workspace`、ローカル設定、外部から参照されるビルド成果物) を洗い出す。`.envrc` は copy しても `direnv allow` は自分でしない (kawaz に委ねる)
- 外部 (launchd の unit、config の `binary_path`、symlink) がリポ内の生成物を指しているなら、移行直後はそのパスに実体が無い。走っているプロセスは退避後も動き続ける (開いた inode を持つ) が、再起動は失敗する。**再生成が終わるまで restart 系の操作を止める**
- worker (Agent tool) は cwd を `main/` に固定して起動するので、移行中は走らせない。走行中の worker があれば完了・commit・push を待つ
- 旧方式の `jj log -r 'remote_bookmarks()..'` には使い捨て agent workspace の空 commit や、旧 jj-worktree ツールのメタ JSON だけを持つ `default` workspace の commit が残っていることがある。中身を見て価値が無ければ退避先に残るままでよい (退避ディレクトリは消さない。削除は kawaz 判断)

## 手順

```bash
# 0. 前提確認 (旧 main/ で)
jj log -r 'remote_bookmarks()..' --no-graph -T 'change_id.short() ++ " " ++ description.first_line() ++ "\n"'   # 価値のある未 push が無いこと
jj workspace list
git --git-dir=../.git config remote.origin.url                                # origin が無ければ本手順の対象外
git status --ignored --short | grep '^!!' | grep -v '^!! target/'             # clone で戻らないものの洗い出し

# 1. ワンショット (絶対パスだけ。cwd を古い inode から降ろしてから始め、新 main/ に cd して終わる)
REPO=/Users/kawaz/.local/share/repos/github.com/<owner>/<repo>; OLD=$REPO.old-bare-$(date +%Y%m%d)
cd /private/tmp && mv "$REPO" "$OLD" && mkdir -p "$REPO" \
  && git clone -q <origin url> "$REPO/main" \
  && cd "$REPO/main" && jj git init >/dev/null && jj workspace rename main && jj bookmark track main --remote=origin \
  && cd "$REPO" && echo "guard: 上位への .git 探索を止める (実体は main/)" > .git && mkdir .jj \
  && echo "guard: 上位への .jj 探索を止める (実体は main/)" > .jj/README.md \
  && cp "$OLD/main/<repo>.local.code-workspace" "$REPO/main/" \
  && cd "$REPO/main" && pwd -P && jj st

# 2. ガードの確認 (双方エラーで止まること) と、外部が参照する生成物の再生成
(cd "$REPO" && git status; jj st)          # fatal: invalid gitfile format / The repository appears broken or inaccessible
cargo build --release ...                   # binary_path 等が指す実体を作り直してから restart 系を再開
```

既定ブランチが `main` でないリポは `jj-colocate-setup` の clone 手順どおり `origin/HEAD` から取る。

## 実績

- 2026-09-17 kawaz/llm-gateway: 未 push は agent workspace の空 commit と `default` の worktree メタだけ。`*.local.code-workspace` を copy、`target/release` を再ビルドしてから unstable unit を restart。cwd の消失なし
