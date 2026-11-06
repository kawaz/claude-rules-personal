# 通知系 tips (音声通知 / 1Password エラー)

## 音声通知は ccmsg の say ツールで

kawaz に音声で呼びかける時 (作業の区切り、判断を仰ぎたい時、止まった時) は ccmsg の say ツールを使う (`{ "text": "<短い日本語の文>" }`。daemon が音声で読み上げ、webui のそのセッションにも 🔔 で残る。使い方の正本は ccmsg plugin の skill)。「離席中のときだけ」という一般の遠慮は要らない。`say` コマンドを直接叩かない。Claude Code 組み込みの `PushNotification` は音声に繋がらないので使わない (ccmsg の tool が無い環境でだけ代替)。

読み上げの誤読 (英単語・頭字語) は ccmsg の `say` が発声直前に辞書 `${XDG_CONFIG_HOME:-~/.config}/ccmsg/say-dictionary.tsv` (`word<TAB>読み`) で直すので、本文は普通に書く。変な読みに気づいたら、その単語を辞書に 1 行足す (次の発声から効く)。

## 1Password エラー時の対応

git / jj / ssh の署名操作は通常タイムアウトしない。`1Password: failed to fill whole buffer` エラーが発生した場合のみ:

1. 音声通知: ccmsg の say ツールで「1Password のエラーで困ってます。気づいて！」
2. ユーザー在席と判断できる場合のみ、チャット本文で再試行可否を尋ねる (推し: 再試行。自由文回答歓迎)
3. 不在推定時 (「離席する」「寝る」等の直前発言 / /remote-control 中 / フルオートモード) は問い返さず、音声通知のみで push をスキップして他の作業を続行

jj 管理リポでは `git.sign-on-push` により `jj git push` 時にまとめて署名するため、commit 時の 1Password エラーは無視し、push 時のみ上記対応。
