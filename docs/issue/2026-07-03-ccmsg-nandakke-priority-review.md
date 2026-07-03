---
title: "ccmsg / nandakke の優先度再考 — エコシステム横断監査所見"
status: idea
category: idea
created: 2026-07-03T14:12:08+09:00
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
origin: エコシステム横断監査 (2026-07-03)
---

# ccmsg / nandakke の優先度再考 — エコシステム横断監査所見

## 概要

kawaz 製ツール群のうち ccmsg と nandakke の優先度を、監査所見として再考するメモ。
戦略判断そのものは kawaz に委ねる。

## 背景

- **ccmsg**: 現に回っている P2P 方式 (cmux-msg、324 commits) の中央デーモン化
  rewrite で、着手 4 日で停滞中。`design-priority` 観点で「これは設計由来の
  要求か」の再確認を推奨。
- **nandakke**: 「ぼんやり全体把握 + 必要時に正確取得」構想で、常時ロード肥大
  (127KB、issue `2026-07-03-always-loaded-rules-diet` 参照) という実在ペイン
  と同型の問題を突いており、相対的に着手価値が高い可能性がある。

本 issue は 2026-07-03 に実施したエコシステム横断監査 (本リポ内 3 subagent
起動) 由来。

## 受け入れ条件

- [ ] ccmsg の中央デーモン化 rewrite が design-priority 観点で正当化される
      要求か、kawaz の判断が得られている
- [ ] nandakke の相対的な着手優先度について kawaz の判断が得られている
