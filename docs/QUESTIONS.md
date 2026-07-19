# 裁定待ち (Questions)

kawaz 裁定を待つ確認事項の常時集約先。
- 各項目はラベル + 質問 1〜2 行 + 選択肢 + AI の推し (根拠 1 文) + 参照
- 裁定が下りたら当該セクションを削除し、裁定内容は正規の記録先 (DR / issue / journal / commit) へ反映
- 詳細な運用規約は `for-me/rules/questions-md-registry.md` を参照

---

## AUQ-Q1: AskUserQuestion 使用禁止と他 rule の矛盾解消

`for-me/rules/questions-md-registry.md` に「AskUserQuestion 使用禁止」を統合済み
(kawaz 2026-07-19)。しかし他 2 箇所で AskUserQuestion 使用を推奨している:

- `for-all/rules/sanitize-work-identifiers.md`: 「判断に迷ったら AskUserQuestion で提示」
- `for-all/rules/notification-tips.md`: 「ユーザー在席と判断できる場合のみ AskUserQuestion で再試行を確認」

選択肢:
- **AUQ-Q1-a**: 4 箇所を「本文の箇条書きで質問 (自由文回答歓迎)」等の代替表現に置換
- **AUQ-Q1-b**: askuserquestion-usage.md に例外節を足して個別 rule での明示許可を認める
- **AUQ-Q1-c**: 今は放置、別セッションで対応 (lint は通る)

AI の推し: **AUQ-Q1-a**。禁則を「原則+例外」で緩めるより、参照側を統一表現に揃える方が rule 全体の一貫性が保てる (`self-written-rule-blind-spots` の対極確認と整合)。
