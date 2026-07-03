---
title: "fleet-audit runbook の週次自動化 (schedule + subagent 構想)"
status: idea
category: design
created: 2026-07-03T14:07:52+09:00
last_read:
open_entered:
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: "エコシステム横断監査 (2026-07-03)"
---

# fleet-audit runbook の週次自動化 (schedule + subagent 構想)

## 概要

`docs/runbooks/fleet-audit.md` (新設済み) の手動チェック手順を、週次 schedule +
subagent により自動化する構想。差分だけを local-issue に起票させることで、監査を
継続運用に乗せる。

チェック項目は runbook (`fleet-audit.md`) を正とする。本 issue は「自動化する
仕組み自体」の検討であり、監査項目そのものの追加・変更は runbook 側を直接更新する。

## 背景

本 issue は 2026-07-03 に実施したエコシステム横断監査 (本リポ内で 3 subagent を
起動し、claude-rules-personal / 各 overlay を横断調査) 由来。手動運用の runbook を
作った直後の段階で、「これを毎回人手で回すのは continuity の弱点になる」という
着想が生まれた。

runbook 本文にも「監査自体の自動化 (定期実行の仕組み化) は別 issue で検討中」と
本 issue への参照が既に埋め込まれている。

## 検討事項 (要設計)

- **実装先**: 以下のいずれか、または他の形か。当事者判断に委ねる
  - 新規 plugin (cron 相当の schedule 機能 + subagent 起動を持つもの)
  - claude-rules-personal リポ内の script (`CronCreate`/`schedule` skill 等の
    既存機構を利用)
  - 既存 plugin (例: local-issue plugin) への機能追加
- **差分検出の粒度**: runbook のチェック項目ごとに前回結果との差分をどう保持するか
  (= 状態を持たせるならどこに永続化するか)
- **起票の粒度**: 検出した差分を 1 issue にまとめるか、チェック項目ごとに分けるか
- **実行トリガ**: 週次 schedule (`CronCreate` / `schedule` skill) を使うか、
  非同期の `loop` skill 的な仕組みにするか

## 受け入れ条件

- [ ] 実装先 (plugin / script / 既存 plugin 拡張) の設計判断が確定する
- [ ] `fleet-audit.md` の各チェック項目に対応する自動検出ロジックが実装される
- [ ] 検出した差分のみが local-issue に起票され、変化なしの項目はノイズを出さない
- [ ] 週次 schedule で継続実行される

## TODO

- [ ] 実装先の設計方針を kawaz と相談 (新規 plugin か既存流用か)
