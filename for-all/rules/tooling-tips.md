# ツール利用の tips

## Bash: 別ディレクトリでのコマンド実行は `cd && direnv exec`

別ディレクトリでコマンドを実行する時は `(cd /path/to/dir && direnv exec . command args...)` の形にする。**`cd` だけ / `direnv exec` だけの片方では事故る** (env が乗らず別アカウント鍵のまま push する / cwd が呼び出し元のままで別リポの状態を観測する)。`git -C dir` も同じ理由で避ける。direnv 未 allow のディレクトリでは指示を仰ぐ (勝手に `direnv allow` しない)。落ちる罠の詳細は reference の `direnv-exec-cwd` ([[knowledge-guide]] のパス) を読む。

## 一時ファイル: scratchpad か `mktemp -d` の中に置く

- 作業用の一時ファイル・ディレクトリは、Claude Code の scratchpad ディレクトリか `mktemp -d` で作ったディレクトリの中に置く。`/tmp/foo` のような固定名で直接作らない (名前が衝突しうる。後始末の `rm` は `mktemp -d` の中でも auto mode の classifier に止められることがあるので、止められたら [[classifier-notes]] に従う)
- サブエージェント・worker を使うときは、親が `mktemp -d` でベースを 1 つ作り、その**実パス**を子へのプロンプトに書く (Bash の変数は呼び出しをまたいで残らない)。子はその中に `mktemp -d -p <ベース>` で自分用のサブディレクトリを作って作業する。後始末は親がベースごと行う
