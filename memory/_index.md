# 横断メモの索引

エントリ形式は `reference/_index.md` と同じ (`- [slug](<slug>.md) — 1 行要旨。` + 次行 `発火語: …`)。

- [bun-install-hangs-on-ipv6-blackhole](bun-install-hangs-on-ipv6-blackhole.md) — bun install が "Resolving dependencies" で止まった時の回避手順。
  発火語: bun install が止まる, Resolving dependencies
- [answer-questions-before-acting](answer-questions-before-acting.md) — kawaz の質問には対応を始める前にまず回答・評価を返す (並行は可)。
  発火語: なんで, 必要ある?, どう思う
- [ai-cli-pass-long-text-by-file](ai-cli-pass-long-text-by-file.md) — AI が長文を渡す kawaz 製 CLI はファイルパスで受ける (引数・stdin でなく)。
  発火語: 長文を渡す, エスケープ事故, --body-file
- [commit-push-scope-by-repo-kind](commit-push-scope-by-repo-kind.md) — リポの種別ごとに、どこまで commit / push してよいか。
  発火語: push してよいか, 他リポに commit
- [ccmsg-backtick-command-substitution](ccmsg-backtick-command-substitution.md) — ccmsg 本文のバッククォートがコマンド置換で消える (送信は成功する)。
  発火語: ccmsg, メッセージが欠けた, バッククォート
- [no-chat-refs-in-docs](no-chat-refs-in-docs.md) — docs に room・メッセージ番号を書かず日付と要点だけ。
  発火語: room 番号, メッセージ番号, 出典
- [grep-wrapper-skips-binary-looking-files](grep-wrapper-skips-binary-looking-files.md) — Bash の `grep` (ugrep ラッパ) は NUL 入り・ignore 済みファイルを無言で飛ばす。「該当なし」の前に裏を取る。
  発火語: grep で見つからない, 該当なし, Binary file
- [webui-modern-platform-first](webui-modern-platform-first.md) — kawaz の webui はモダン CSS / JS を使い、古いハックや JS 自前制御で代替しない。
  発火語: webui, CSS, Baseline
