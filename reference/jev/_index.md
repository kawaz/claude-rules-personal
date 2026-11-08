# Jev (TypeSafe AI の判断専用 API)

文章を生成せず、state に対する型付きの質問 (Choice / Score / Noul / Box) に確率付きの答えを返す API。判定機・ルーティング・lint に組み込む時に読む。

- [question-design](question-design.md) — 型の選び方 (答えの構造から)、1 問 1 論点の分解、fan-out、Noul / Choice / Score の書き方、範囲外入力の受け皿 (companion Noul / none)。
  Choice か Score か, Noul, 質問を分解, 複合的な判断, 範囲外入力, none の選択肢, companion Noul, 選択肢の順序, 質問 ID, instructions, criteria, 字面どおり
- [request-and-state](request-and-state.md) — model の版固定、state をオブジェクトで渡しキーで名指す、日本語入力の扱い、制限・料金・状態コード、画像・Box・long context。
  jev-latest, 版 ID, state の形, オブジェクト, バッククォート, 日本語, CJK, 英語で書く, 料金, レート制限, 529, 429, max_tokens_exceeded, Danger Zone, assets, box
- [answers-and-lint](answers-and-lint.md) — しきい値の置き場 (型ごと)、confidence の意味と式、テンプレの静的 lint の検査項目。
  しきい値, 0.7, 0.3, 中間帯, confidence, probabilities, 確率との違い, 人に回す, jev-lint, テンプレの検査, golden
