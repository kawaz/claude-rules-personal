---
title: リポ整理 (archive/削除/継続判定) 適用対象リストの消化
status: open
category: task
created: 2026-07-03T14:09:26+09:00
last_read:
open_entered: 2026-07-03T14:09:26+09:00
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

# リポ整理 (archive/削除/継続判定) 適用対象リストの消化

## 概要

`docs/runbooks/repo-retirement.md` (新設済み) の適用対象リストを消化するタスク。
以下の適用候補リポについて、archive / 削除 / 継続の判断を kawaz が行い、
判断が出たリポから runbook の手順に従って処理する。

適用候補リポ (2026-07-26 時点):

### 未処理

- ssh-agent-router: 「後継を案内して archive」の方針は確定済み。後継リポの特定が未完 (kawaz は cache-warden を挙げたが役割が対応せず、対応するのは authsock-warden に見える。docs/QUESTIONS.md の RR-C1 で確認待ち)

### 処理済み (完全削除、ローカル)

- ssh-agent-tools (608M、GH に実体なし)
- json-compact (184K、GH に実体なし)
- ssh-authsock-filter (92K、commit 0、GH に実体なし)
- claude-desktop-ws (80K、.git のみで空、GH に実体なし)
- bump.mbt (3.3M、GH は archive 済みの空リポ。ローカルに 2732 行の MoonBit 実装があったが後継 bump-semver で作り直し済みのため削除)
- claude-plugins (1.6M、GH archive 実行済み + ローカル削除)

計 6 リポ、約 610M を回収。

### GH archive 実行済み

- claude-plugins (isArchived=true を確認済み。後継は個別 plugin リポ 6 件へ移行済みで GH README に明記済み)

### 処理不要と判明

- claude-pr-monitor: GH 上で claude-gh-monitor に rename 済み。同一リポなので引退作業自体が不要 (旧名で gh repo view すると rename 先の状態が返る点に注意)

### 放置 (kawaz 裁定)

- csv2json (2016 年最終)
- csv2tsv (2020 年最終)
- unbreaker (2020 年最終)
- findmy (GH 側 2025-02、ローカル 2022 で未同期)

## 背景

2026-07-03 に実施したエコシステム横断監査 (本リポ内 3 subagent 起動) で、
上記リポが「実体不明瞭」「実装なし」「既に上流で archive 済み」等の理由で
整理候補として検出された。判断・作業手順は `docs/runbooks/repo-retirement.md`
に委ねる。

なお claude-plugin-jj は当該リポ側に個別 issue 起票済みのため、本リストには含めない。

## 受け入れ条件

- [x] 各候補リポについて kawaz が archive / 削除 / 継続 のいずれかを判断する (ssh-agent-router の後継特定のみ残)
- [ ] 判断が出たリポは runbook の手順で処理済みにする (ssh-agent-router 以外は完了)
- [ ] リスト全件の処理が完了する (残り 1 件)

## TODO

<!-- wip 時のみ -->
