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

適用候補リポ:

- ssh-agent-router
- ssh-agent-tools
- ssh-authsock-filter (GitHub 非公開・ローカルのみの断片)
- claude-desktop-ws (commit 0 の骨組み)
- json-compact (docs のみで実装なし)
- claude-pr-monitor のローカル化石クローン (rename 済み)
- csv2json
- csv2tsv
- unbreaker
- findmy
- bump.mbt (GitHub archive 済み・ローカル整理のみ)
- claude-plugins (marketplace リポ。kawaz 本人が 2026-05-24 に PR #1 で非推奨化を merge 済み・README に「アーカイブまたは削除予定」と明記済みだが archive 未実施。ローカル clone は origin に対し 1 ahead / 3 behind で diverged — ローカル側 commit は force-uv v0.2.3 bump で origin 側の同内容 commit と重複しており、統合 or 破棄の判断も必要)

## 背景

2026-07-03 に実施したエコシステム横断監査 (本リポ内 3 subagent 起動) で、
上記リポが「実体不明瞭」「実装なし」「既に上流で archive 済み」等の理由で
整理候補として検出された。判断・作業手順は `docs/runbooks/repo-retirement.md`
に委ねる。

なお claude-plugin-jj は当該リポ側に個別 issue 起票済みのため、本リストには含めない。

## 受け入れ条件

- [ ] 各候補リポについて kawaz が archive / 削除 / 継続 のいずれかを判断する
- [ ] 判断が出たリポは runbook (`docs/runbooks/repo-retirement.md`) の手順で処理済みにする
- [ ] リスト全件の処理が完了する

## TODO

<!-- wip 時のみ -->
