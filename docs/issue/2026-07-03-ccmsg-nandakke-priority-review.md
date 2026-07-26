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

- **ccmsg**: claude-ccmsg は最も活発に開発中 (commit 803、最新 Release
  v0.73.28、DR-0001〜0028、本日も commit)。逆に比較対象だった cmux-msg 側が
  2026-07-07 Release v0.31.8 で停止しており、当初の「回っている P2P 方式 vs
  停滞中の rewrite」という対比は逆転した。
- **nandakke**: 「ぼんやり全体把握 + 必要時に正確取得」構想で、常時ロード
  肥大という実在ペインと同型の問題を突いている。肥大は 78KB (for-all/rules
  69132B + for-me/rules 8802B) へ軽減済みだが未解消。姉妹 issue
  `2026-07-03-always-loaded-rules-diet` は status: open のままで、その受け
  入れ条件「常時ロード予算チェックが just lint-rules 等に組み込まれている」
  が未達 (justfile の検査は 1 ファイル 5KB 超の WARN のみで合計予算の検査は
  存在しない)。

本 issue は 2026-07-03 に実施したエコシステム横断監査 (本リポ内 3 subagent
起動) 由来。

## 受け入れ条件

- [x] ccmsg の中央デーモン化 rewrite が design-priority 観点で正当化される
      要求か、kawaz の判断が得られている (根拠: ccmsg 側
      `docs/journal/2026-07-03-dr0001-provenance-audit.md` で kawaz 本人が
      旧 DR-0001 を一次資料準拠で全面書き直しさせ、以降 28 DR 出荷という
      経路で事実上裁可済み)
- [ ] nandakke の相対的な着手優先度 (go/no-go)。現況: claude-nandakke/main は
      2026-06-21 で停止、README は Pre-implementation (per DR-0001,
      §YAGNI)、docs/ROADMAP.md の Phase 1 未着手、docs/issue/ の各件も
      未消化のまま。さらに `2026-07-03-repo-retirement-todo-list` の候補
      リストに nandakke は含まれておらず archive/削除/継続の判定経路にも
      乗っていない
