# 横断メモの索引

エントリ形式は `reference/_index.md` と同じ (`- [slug](<slug>.md) — 1 行要旨。` + 次行 `発火語: …`)。

- [bun-install-hangs-on-ipv6-blackhole](bun-install-hangs-on-ipv6-blackhole.md) — bun install / add が IPv6 断で "Resolving dependencies" のまま止まる時の、Node localhost レジストリ proxy による回避手順。
  発火語: bun install が止まる, Resolving dependencies, SYN_SENT, IPv6, registry.npmjs.org に繋がらない, --registry, bun.lock の 127.0.0.1
- [answer-questions-before-acting](answer-questions-before-acting.md) — kawaz の質問には対応を始める前にまず回答・評価を返す (並行は可)。
  発火語: 質問, なんで, 必要ある?, どう思う, 指摘と受け取る, 即対応
- [ai-cli-pass-long-text-by-file](ai-cli-pass-long-text-by-file.md) — AI が長文を渡す kawaz 製 CLI は引数や stdin でなくファイルパス (必須なら位置パラメータ) で受ける。`-` の特別扱いは無し、人間は `/dev/stdin` を渡す。
  発火語: 長文を渡す, 本文を引数で, エスケープ事故, バッククォート, stdin, --body-file, Write してから渡す
- [commit-push-scope-by-repo-kind](commit-push-scope-by-repo-kind.md) — rules・privacy リポは commit も push も可、プロダクトリポは docs の commit まで。push は他の未 push commit が無ければ可、あれば次の push に相乗り。
  発火語: push してよいか, 他リポに commit, issue 起票の push, リリース窓, プロダクトリポ
- [ccmsg-backtick-command-substitution](ccmsg-backtick-command-substitution.md) — ccmsg 本文をダブルクォートで渡すとバッククォート部分がコマンド置換されて空になる (送信は成功するので気づきにくい)。
  発火語: ccmsg, post, reply, メッセージが欠けた, バッククォート, コマンド置換, エージェント間メッセージ
- [no-chat-refs-in-docs](no-chat-refs-in-docs.md) — docs (DR / DESIGN / issue) に room・メッセージ番号 (rNNN mNN) を書かず日付と要点だけ。
  発火語: r303, room 番号, メッセージ番号, 出典, 裁定の記録, DR の Context
- [grep-wrapper-skips-binary-looking-files](grep-wrapper-skips-binary-looking-files.md) — Bash の `grep` は ugrep ラッパで、NUL を含むファイルや ignore 済みファイルを無言で飛ばす。「該当なし」の前に `file` と `command grep` で裏を取る。
  発火語: grep で見つからない, 該当なし, Binary file, ugrep, --ignore-files, NUL, file が data と言う
- [webui-modern-platform-first](webui-modern-platform-first.md) — kawaz の webui はモダン CSS / JS を積極採用し、古いハックで代替しない。ブラウザが持つ振る舞い (追従 / 貼り付き / 伸縮) を JS で自前制御しない。採否は Baseline を根拠に DR / DESIGN に書く。
  発火語: webui, CSS, モダン CSS, Baseline, Safari 27, ハック, 相対色構文, color-mix, @container, :has
