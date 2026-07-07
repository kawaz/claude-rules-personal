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

## ユーザへの質問

質問・確認が必要な場合は `AskUserQuestion` ツールを使用する。

- 複数の選択肢がある場合に特に有効
- 複数の質問を一度に聞ける（最大4問）
- ユーザは「Other」で自由入力も可能
