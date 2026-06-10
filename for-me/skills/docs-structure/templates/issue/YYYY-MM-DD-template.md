# {タイトル}

- Status: open <!-- idea / open / wip / blocked / pending-sublimation -->
- Created: YYYY-MM-DD
- Origin: {自リポ TODO / 他プロジェクト依頼 (= 依頼元プロジェクト)}
<!-- blocked の時は blocked_by を追記:
- Blocked by: {別 issue / 外部依存}
-->

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

解決後はこのファイルを **削除** する (jj/git 履歴で追える)。
