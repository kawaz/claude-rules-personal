# Dogfooding での気づきは上流の kawaz 製ツールへ還元する

kawaz 製ツール (bump-semver, pkfire, jj-worktree, authsock-warden, ...) を別プロジェクトで
使っていて仕様の罠・bug・改善点に気づいたら、**利用側プロジェクトの docs (journal/findings)
にとどめない**。kawaz は自製ツールをいくらでも直せるので、利用側に埋もれた気づきは
改善機会の損失になる。

## 還元先 (どちらか、両方も可)

1. **ツールリポの `docs/issue/` に起票** (kawaz リポは GH Issues でなくローカル issue 運用)。
   ツールリポ側の記法・命名・status 語彙に合わせる。
2. **当該ツールを担当中の Claude セッションに cmux-msg で直接共有** (セッション ID が
   分かっている / kawaz から指示がある場合)。即時対応が見込めるならこちらが速い。

## 起票・共有に含める内容

- 現象 / 再現コマンド (コピペで再現できる粒度)
- 実機確認の結果 (推測でなく観測)
- 利用側で取ったワークアラウンド
- 改善提案 (任意。「エラーメッセージにヒント追加で十分」等の所感も価値がある)

## How to apply

- 気づいた時点で還元する (まとめて後で、にしない — 忘れる)
- 利用側の journal には「上流に起票済み: <repo> docs/issue/<file>」の相互参照を残す
- ツールが kawaz 製かは repo owner (github.com/kawaz/*) で判定。迷ったら kawaz に確認
