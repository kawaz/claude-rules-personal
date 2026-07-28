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

### 👺FA-Q1: fleet-audit 週次自動化の実装方針 ([issue](issue/2026-07-03-fleet-audit-automation.md))

CronCreate はセッション限り (7 日失効) で恒久自動化に使えない。

- [ ] a: launchd で恒久 schedule 化 (headless claude -p で監査 → 差分だけ issue 起票)
- [ ] b: 自動化せず手動運用継続で issue close (推し。監査は月 1 回程度の手動で足りており、自動化の保守コストが上回る)
- [ ] c: 保留継続

### 👺MR-Q1: メタ認知系ルールのモデル世代交代時再検証 ([issue](issue/2026-07-03-metacognitive-rule-model-revalidation.md))

対象: sloppy-ai-patterns / synthesis-temptation-guard / default-convergence-guard (旧世代モデルの欠点前提のルールが新世代で不要かも、という問い)。

- [ ] a: frontmatter マーカー付与 (モデル交代時に grep で棚卸し対象化)
- [ ] b: 対応不要で issue close (推し。ルール自体が「症状が出たら」駆動で実害がなく、世代交代のたびの棚卸しは過剰プロセス。実際に空振りが目立ったルールを個別に削る方が安い)
- [ ] c: 定期棚卸しに組込み

### 👺SH-Q1: sanitize hook (claude-sanitize-guard) の設計レビュー go/no-go ([issue](issue/2026-07-03-sanitize-work-identifiers-hook.md))

issue の設計案: word-boundary match の warn-only hook。実装着手前に kawaz レビュー必須と明記されている。

- [ ] a: 設計案どおり実装 go
- [ ] b: 実装せず prose ルール運用継続で issue close
- [ ] c: 保留継続 (推し。warn-only の補助機構で緊急性なし、gh-issue-guard の運用実績を見てから同型で作る方が設計が安定する)

### 👺OA-Q1: orchestrate skill A/B 検証の進め方 ([issue](issue/2026-07-07-orchestrate-skill-ab-validation.md))

- [ ] a: 日常タスクの中で skill 有/無のサンプルを蓄積する方式に切替 (推し。一括 A/B は実案件 3-5 本 × 2-3 run の確保コストが高い)
- [ ] b: 元計画どおり一括 A/B を実施
- [ ] c: 検証せず issue close (skill は現状維持)

## 確認待ち
