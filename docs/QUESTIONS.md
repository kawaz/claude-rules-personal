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

### KN-Q1 読むだけ系 skill を knowledge カタログへ移すか

[docs/issue/2026-09-09-readonly-skill-knowledge-migration.md](issue/2026-09-09-readonly-skill-knowledge-migration.md)。
境界は「実行資源を伴うか」。統括推し: a と b は移す、c は手順書として残す。

- [ ] a: `app-file-placement` を移す (付属ファイルなし、被参照は自身のみ)
- [ ] b: `jj-rebase-options-reference` を移す (同上)
- [ ] c: `cross-env-ssh-signing` を移す (コマンド手順を含むので手順書側が妥当と見ている)

## 確認待ち

### KN-C1 cli-daemon-subcommands エントリの内容確認

[skills/knowledge/reference/cli-daemon-subcommands.md](../skills/knowledge/reference/cli-daemon-subcommands.md)。
r285m27 原文を起こし、llm-gateway 側の補足 4 点は別節に分離。見てほしいのは
「採用側で決まった補足」節が体系本体に昇格してよいものか、と launcher 節を「検討」のままにしてよいか。

- [ ] a: このままで OK (push して配布)
- [ ] b: 修正あり (チャットで指摘)
