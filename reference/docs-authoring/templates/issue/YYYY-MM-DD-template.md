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

{wip の間は進捗を checkbox で書く。idea / open の間はこの節ごと削除してよい}

- [ ] {次に手を付けるサブタスク}
- [ ] ...

## 解決時の記録先

- 単純なコード修正のみ: 記録不要 (commit message で足りる)
- 設計判断を伴う: `decisions/DR-NNNN-...md`
- 運用上の再発可能性: `runbooks/<topic>.md`
- 経緯・ハマり所を残したい: `journal/YYYY-MM-DD-<slug>.md`

解決時は plugin の `update <slug> close` で `docs/issue/archive/` へ移動 (= 削除ではない、履歴は DB として残る)。
