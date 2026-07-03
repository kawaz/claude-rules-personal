---
title: "work-principles.md と top-tier-model-delegation.md の委譲ロジック責務分裂を解消する"
status: idea
category: design
created: 2026-07-03T14:10:51+09:00
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
