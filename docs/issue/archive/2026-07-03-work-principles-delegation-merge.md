---
title: "work-principles.md と top-tier-model-delegation.md の委譲ロジック責務分裂を解消する"
status: resolved
category: design
created: 2026-07-03T14:10:51+09:00
last_read:
open_entered:
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered: 2026-07-28T22:04:27+09:00
discard_reason:
pending_reason:
close_reason: ["done: issue 起票直後の c57ca5a921 (work-principles / top-tier-model-delegation 統合) と後続 3f6f783 (選定詳細を worker-fleet skill へ切り出し) により委譲ロジックの重複は解消済み。work-principles.md は tier 別強度の要約のみ保持、選定詳細は worker-fleet skill に一本化。実物確認済み (top-tier-model-delegation.md はリポに現存せず)"]
blocked_by:
origin: エコシステム横断監査 (2026-07-03)
---

# work-principles.md と top-tier-model-delegation.md の委譲ロジック責務分裂を解消する

## 概要

`work-principles.md` と `top-tier-model-delegation.md` の間でサブエージェント
委譲判断のロジックが分裂し、相互参照している状態を解消したい。

所有権を片方へ寄せる案として、委譲判断の詳細は `top-tier-model-delegation`
に集約し、`work-principles` は原則のみを残す構成が候補。

## 背景

2026-07-03 の別 fix セッションで `work-principles` を `for-me` から
`for-all` へ昇格済み (越境リンク解消のため) であり、本統合検討はその次段の
整理として位置づける。

本 issue は 2026-07-03 に実施したエコシステム横断監査 (本リポ内 3
subagent 起動) 由来。

## 受け入れ条件

- [ ] `work-principles.md` と `top-tier-model-delegation.md` の委譲判断ロジックの重複箇所が洗い出されている
- [ ] 所有権の寄せ先 (どちらに詳細を集約するか) が決定されている
- [ ] 決定に従い両ファイルが書き換えられ、相互参照が一方向 (or 不要) になっている
