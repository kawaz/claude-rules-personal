# 裁定・確認待ち一覧 (ユーザ用)

## 運用規約

<details>
<summary>ゼロコンテキストエージェント向け（本セクションは消さない）</summary>

- 裁定/確認待ち項目を 1項目=1ラベル=1セクション で記載
- ラベル形式: XX-Q1（XX は 2-3 文字、バッチやセッション内で一意、Qn単独の使い回し禁止、長期一意性は不要)
- 依頼形式: 「👺XX-Q1 の裁定お願いします」（参照用途ではラベルに👺を付けない。誤陽性がユーザのハイライト/アラームを汚す）
- チャット提示と同一ターンで本ファイルに記録 + path 指定 commit (push はリリース窓に同乗)
- 裁定が下りたら該当セクションを即削除し、内容は正規の記録先 (DR / issue / journal / close_reason) へ反映。本ファイルは常に「現在待ち」だけを持つ
- 参照は[]()で提示（リポ内は相対、リポ外はフルパス）
- 初版質問/依頼は長文で書かない（ユーザが説明を求めらたら本ファイルに説明を追加し、チャットで👺ラベルで再依頼）
- **選択肢・確認項目は `- [ ] a: …` 形式（チェックボックス + ラベル）で書く**。
  Q / C で記法を分けない。回答は「チェックを付ける」でも「XX-Q1a」と言葉で返すでも通る
  （複数まとめてチェックし「チェックしたよ」の一言で済ませる運用を想定）

</details>

## 裁定待ち

## 確認待ち

### ER-C1: claude-rules-personal の push

未 push の commit が溜まっている (リネーム本体 + 派生で見つけた不具合修正 + 運用)。
public リポなので push 判断を仰ぐ。`skills/` と `agents/` を変更しているため
`check-version-bumped` gate に掛かるので、実行は `just bump-version` → `just push`。

**push まで `rules-personal:sonnet5-worker-xhigh` と
`rules-personal:codex-luna-reviewer-xhigh` が使えません** (手置きから plugin 管理下へ
移したため、marketplace 経由で配布されるまで空白になる)。

- [ ] a: push してよい (bump は patch)
- [ ] b: push してよい (bump 種別を指定: minor / major)
- [ ] c: まだ待つ
