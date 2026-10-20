---
title: auto mode classifier が subagent 宛 SendMessage と claude plugin validate/test を止める
status: open
category: task
created: 2026-10-20T16:25:24+09:00
last_read:
open_entered: 2026-10-20T16:25:24+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: 自リポ TODO
---

# mode classifier が subagent 宛 SendMessage と claude plugin validate/test を止める

## 概要

auto mode classifier が subagent 宛 SendMessage と claude plugin validate/test を止める (2026-10-20 の thinking-guard 作業で 4 件)。許可を worker に中継する SendMessage、純粋な作業指示の SendMessage (本文に「許可」を含む)、worker の `claude plugin validate && claude plugin test`、統括の Bash (会話文脈由来の別チェック、以後その会話で恒久) が拒否された。autoMode の allow 候補: 自セッション subagent 宛 SendMessage、claude plugin validate / test。設定変更は kawaz の明示指示が要る (classifier-notes)。

## 背景

classifier-notes により autoMode と classifier.local.md は kawaz の明示指示なしに編集しない。

## 受け入れ条件

- [ ] kawaz の指示のもと autoMode の allow に候補を反映するか判断する
