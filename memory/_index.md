# 横断メモの索引

エントリ形式は `reference/_index.md` と同じ (`- [slug](<slug>.md) — 1 行要旨。`)。常時ロードなので発火語の行は持たない。

- [bun-install-hangs-on-ipv6-blackhole](bun-install-hangs-on-ipv6-blackhole.md) — bun install が "Resolving dependencies" で止まった時の回避手順。
- [answer-questions-before-acting](answer-questions-before-acting.md) — kawaz の質問には対応を始める前にまず回答・評価を返す (並行は可)。
- [ai-cli-pass-long-text-by-file](ai-cli-pass-long-text-by-file.md) — AI が長文を渡す kawaz 製 CLI はファイルパスで受ける (引数・stdin でなく)。
- [commit-push-scope-by-repo-kind](commit-push-scope-by-repo-kind.md) — リポの種別ごとに、どこまで commit / push してよいか。
- [ccmsg-backtick-command-substitution](ccmsg-backtick-command-substitution.md) — ccmsg 本文のバッククォートがコマンド置換で消える (送信は成功する)。
- [no-chat-refs-in-docs](no-chat-refs-in-docs.md) — docs に room・メッセージ番号を書かず日付と要点だけ。
- [grep-wrapper-skips-binary-looking-files](grep-wrapper-skips-binary-looking-files.md) — Bash の `grep` (ugrep ラッパ) は NUL 入り・ignore 済みファイルを無言で飛ばす。「該当なし」の前に裏を取る。
- [webui-modern-platform-first](webui-modern-platform-first.md) — kawaz の webui はモダン CSS / JS を使い、古いハックや JS 自前制御で代替しない。
- [index-lines-terse](index-lines-terse.md) — 索引の 1 行は短く (用途だけ、要約を詰めない)。
- [workboard-personal-scheduling](workboard-personal-scheduling.md) — 先の予定は workboard-personal/main に ccmsg で送る (起こしてもらえる)。
- [classifier-blocks-batches](classifier-blocks-batches.md) — classifier に止められる操作の型と通し方 (1 コマンド 1 単位、Read してから実行)。
