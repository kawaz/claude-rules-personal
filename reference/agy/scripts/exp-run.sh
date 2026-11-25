#!/bin/bash
# agy の実験を、毎回同じ文字列のコマンドで回すための台。引数は取らない。
# 入力: $TMPDIR/agy-exp/cmd。1 行 = agy に渡す引数列 (bash の配列として解釈する)。
#   行頭に `@stdin=<ファイル名> ` を付けると、$TMPDIR/agy-exp/<ファイル名> を agy の標準入力に渡す。
#   agy は $TMPDIR/agy-exp/work/ で動く。$U は実行ごとに作る小文字の uuid。
# 出力: $TMPDIR/agy-exp/out.txt (標準出力にも同じ物を出す)
set -u
: "${TMPDIR:?TMPDIR is not set}"
here="${TMPDIR%/}/agy-exp"
work="$here/work"
mkdir -p "$work"
U=$(uuidgen | tr 'A-Z' 'a-z')
export U
{
  echo "U=$U"
  while IFS= read -r line || [ -n "$line" ]; do
    [ -z "$line" ] && continue
    stdin=/dev/null
    if [[ "$line" =~ ^@stdin=([^ ]+)\ (.*)$ ]]; then
      stdin="$here/${BASH_REMATCH[1]}"
      line="${BASH_REMATCH[2]}"
    fi
    echo "### agy $line  (stdin=$stdin)"
    eval "args=($line)"
    (cd "$work" && timeout 200 agy "${args[@]}" < "$stdin" 2>&1)
    echo "### exit=$?"
  done < "$here/cmd"
  echo "### files in work:"; ls -A "$work"
} > "$here/out.txt" 2>&1
cat "$here/out.txt"
