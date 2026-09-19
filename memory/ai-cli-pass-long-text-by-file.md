---
name: ai-cli-pass-long-text-by-file
description: AI が長文 (メッセージ本文・state・issue 本文) を渡す CLI は、引数や stdin でなくファイルパスで受ける
metadata:
  type: reference
---

AI が長文を渡す kawaz 製 CLI (ccmsg の本文、Jev の state、issue の本文など) は **ファイルパスで受ける** (必須なら位置パラメータ、任意なら `--body-file <path>` のような option)。AI は `Write` tool で本文をファイルに置いてからパスを渡す。

## Why

- 引数渡しは AI が shell 文字列を組み立てるので、ダブルクォート内のバッククォートがコマンド置換される・`$` や `!` が展開される・glob がエラーになる、の事故が消えない ([[ccmsg-backtick-command-substitution]])
- stdin 渡しもパイプの手前 (`echo '...' |`、heredoc) で結局 shell の引用が要り、事故の場所が変わるだけ。シングルクォートは本文中の `'` で壊れる
- `Write` tool は本文を JSON パラメータで受けるので shell も展開も通らず、AI 側のエスケープ責務がゼロになる。transcript に残るのはパスだけなので長文でも context を食わない

## How to apply

- `-` (stdin の特別扱い) は用意しない。人間が手で使う時は `/dev/stdin` を渡せば済む
- 置き場はセッションのスクラッチ dir (`/tmp/claude-<uid>/<project>/<session>/` のように tasks が使っている場所)。セッション終了で消え、他セッションと衝突しない。CLI は入力ファイルを消さない (消すのは呼び出し側の責務)
- スクラッチ dir は、パスで発火する hook (docs/issue/ の access guard 等) の監視対象外に置く
- 送った内容は CLI 側の log (room log 等) に残す。transcript からは追えなくなるため
