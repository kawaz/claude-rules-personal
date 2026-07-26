<!--
issue は claude-local-issue plugin の `write` sub-command で起票する (= 手書きしない)。
本ファイルは plugin が生成する形の参考。frontmatter / status 遷移 / archive の機械的詳細
は plugin の `SKILL.md` / `docs/DESIGN.md` を参照。
-->
---
title: "{タイトル}"
status: open
category: task
created: YYYY-MM-DDTHH:MM:SS+09:00
last_read:
open_entered: YYYY-MM-DDTHH:MM:SS+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: "{自リポ TODO / 他プロジェクト依頼 (= 依頼元プロジェクト)}"
---

# {タイトル}

## 概要

{何をしたいか、何が問題か}

## 背景

{なぜ必要か、どこから来た要望か}

## 受け入れ条件

- [ ] {完了の判定基準 1}
- [ ] {完了の判定基準 2}

## TODO

<!-- wip 状態のとき進捗 checkbox で内包。idea/open 時は section ごと削除可。 -->

- [ ] {次に手を付けるサブタスク}
- [ ] ...

## 解決時の記録先

- 単純なコード修正のみ: 記録不要 (commit message で足りる)
- 設計判断を伴う: `decisions/DR-NNNN-...md`
- 運用上の再発可能性: `runbooks/<topic>.md`
- 経緯・ハマり所を残したい: `journal/YYYY-MM-DD-<slug>.md`

解決時は plugin の `update <slug> close` で `docs/issue/archive/` へ移動 (= 削除ではない、履歴は DB として残る)。
