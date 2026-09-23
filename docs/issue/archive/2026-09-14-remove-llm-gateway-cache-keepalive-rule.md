---
title: llm-gateway cache keepalive 応答 rule の削除
status: resolved
category: task
created: 2026-09-14T17:02:15+09:00
last_read:
open_entered: 2026-09-14T17:02:15+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered: 2026-09-23T22:49:05+09:00
discard_reason:
pending_reason:
close_reason: ["done: for-all/rules/llm-gateway-cache-keepalive.md を削除、_index.md の該当行を削除", "done: reference に合図方式の記述は残っていないことを grep で確認 (cli-daemon-subcommands の KeepAlive は launchd の機能で無関係)", "done: just lint-rules OK", "done: commit f0bd8427"]
blocked_by:
origin: llm-gateway 統括セッション
---

# llm-gateway cache keepalive 応答 rule の削除

## 概要

常時ロード rule `for-all/rules/llm-gateway-cache-keepalive.md`
(`[llm-gateway keepalive ping] nonce=…` に nonce を 1 行で返す規約) を削除する。
`for-all/rules/_index.md` の「運用・インフラ」節の該当行も同じ変更で外す。
reference の `cli-daemon-subcommands` 等に合図方式 (ping を送って nonce を
待つ方式) の記述が残っていれば、現行の自送信 (replay) 方式に合わせて修正する。

## 背景

llm-gateway v0.48.0 (DR-0027 段階 B、2026-09-14 展開済み) で合図方式の
keepalive が撤去され、gateway は自送信 (replay) で prompt cache を延命する
ようになった。このため `[llm-gateway keepalive ping] nonce=…` 通知はもう
届かない。正本は llm-gateway リポの
`docs/decisions/DR-0027-keepalive-by-replay.md` 決定 7。

## 受け入れ条件

- [ ] `for-all/rules/llm-gateway-cache-keepalive.md` が削除されている
- [ ] `for-all/rules/_index.md` の「運用・インフラ」節から該当行が外れている
- [ ] reference (`cli-daemon-subcommands` 等) に合図方式の記述が残っていれば
      現行 (自送信/replay) 方式に更新されている
- [ ] `just lint-rules` が通る
