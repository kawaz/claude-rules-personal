---
title: "{タイトル}"
status: open
category: task
created: YYYY-MM-DD
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

解決時は status を `resolved` か `discarded` にして `close_reason` を書けば、plugin が `docs/issue/archive/` へ移動する (= 削除ではない)。
