# 通知系 tips (音声通知 / 1Password エラー)

## 音声通知は `PushNotification` ツールで

kawaz に音声で呼びかける時は `PushNotification` ツールを使う (ccmsg 環境では hook が本文をそのまま macOS の `say` と webui の通知に流す。「離席中のときだけ」という一般の遠慮は要らない)。`say` コマンドを直接叩かない。

本文の英大文字略語はそのまま読むと変な読み方になる (例: `OTP` → 「おっとぴー」) ので、**頭字語・略語はカタカナに変換して書く**。変換表は reference の `say-katakana` ([[knowledge-guide]] のパス) を読む。

## 1Password エラー時の対応

git / jj / ssh の署名操作は通常タイムアウトしない。`1Password: failed to fill whole buffer` エラーが発生した場合のみ:

1. 音声通知: `PushNotification` で「ワンパスワードのエラーで困ってます。気づいて！」
2. ユーザー在席と判断できる場合のみ、チャット本文で再試行可否を尋ねる (推し: 再試行。自由文回答歓迎)
3. 不在推定時 (「離席する」「寝る」等の直前発言 / /remote-control 中 / フルオートモード) は問い返さず、音声通知のみで push をスキップして他の作業を続行

jj 管理リポでは `git.sign-on-push` により `jj git push` 時にまとめて署名するため、commit 時の 1Password エラーは無視し、push 時のみ上記対応。
