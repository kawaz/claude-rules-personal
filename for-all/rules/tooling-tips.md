# ツール利用の tips

## Bash: サブシェルでの cd

ユーザ提示コマンドで `cd` を伴う場合はサブシェルで囲む。

```bash
# Good
(cd /path/to/dir && command)

# Bad - ユーザのcwdが変わる
cd /path/to/dir && command
```

## Bash: `!` を含むコマンドの実行

`!` が `\!` にエスケープされる問題の回避策：

```bash
cat << 'EOF' | bash
echo 'Hello!'
EOF
```

## CLI ベンチマーク

コマンドのベンチマークには `hyperfine` を使用する。
