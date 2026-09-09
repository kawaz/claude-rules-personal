# ツール利用の tips

## Bash: 別ディレクトリでのコマンド実行は `cd && direnv exec`

別ディレクトリでコマンドを実行する時は `(cd /path/to/dir && direnv exec . command args...)` の形にする。**`cd` だけ / `direnv exec` だけの片方では事故る** (env が乗らず別アカウント鍵のまま push する / cwd が呼び出し元のままで別リポの状態を観測する)。`git -C dir` も同じ理由で避ける。direnv 未 allow のディレクトリでは指示を仰ぐ (勝手に `direnv allow` しない)。落ちる罠の詳細は `knowledge` skill の `direnv-exec-cwd` を読む。

## Bash: `!` を含むコマンドの実行

`!` が `\!` にエスケープされる問題の回避策：

```bash
cat << 'EOF' | bash
echo 'Hello!'
EOF
```

## CLI ベンチマーク

コマンドのベンチマークには `hyperfine` を使用する。
