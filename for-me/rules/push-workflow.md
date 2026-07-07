# Push ワークフロー (禁則)

## commit (= 固定) → push の順、常にパス指定

push の前提は固定された commit。**自分が修正したファイルだけを `<files...>`
でパス指定して固定する**。パスなしの `jj commit -m "msg"` / `git commit -am` /
`git add .` は他セッション (= 別 workspace / 別 Claude) の未認識変更を
巻き込む事故源 (双方向: 自分が巻き込む / 自分が巻き込まれる)。

- **jj リポ**: `jj commit -m "msg" <files...>` 必須。`jj split` も同様。
  `jj describe` 単体は @ にラベルを貼るだけ (= 固定ではない)。詳細は
  `jj-tips` skill
- **git リポ**: `git commit -m "msg" <files...>` 必須。`-a` / `git add .` は避ける
- 例外 (パス指定なし可): @ の全ファイルが自セッション生成かつ他セッション
  接触なしと確認済みの時のみ。通常は判断コストの方が高いので常にパス指定

## push 直前: @ に他セッションのファイルが居残っていないか確認

`jj status` (or `git status`) で確認。`<files...>` 指定から漏れて @ に残った
他セッションのファイルは**放置せず読む**: コミットすべきなら別 commit で
固定、価値がなければ削除。「自分のファイルじゃないからほっとく」は不可。

## push 経路と後処理

- `jj git push` / `git push` を直接実行しない。リポの push task (justfile 等)
  を使う。直接 push しても push-guard plugin の hook がブロックする
- rules リポでは push の deps で `just lint-rules` が走る (規約の正本は
  [[rule-writing-guidelines]])
- push 後、subscribe stream に `Monitor で 'just watch' を起動して` が届いたら
  task 名そのまま Monitor (persistent=true) で起動する。watch 運用の詳細・
  notify が無いリポでの手動手順は `push-watch` skill 参照
