---
title: ライブ引き継ぎで温まっている worker を新セッションに渡す (ccmsg send の session_id + agent_id)
status: open
category: task
created: 2026-11-09T15:48:11+09:00
last_read:
open_entered: 2026-11-09T15:48:11+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: pam-passkey
---

# ライブ引き継ぎで温まっている worker を新セッションに渡す (ccmsg send の session_id + agent_id)

## 概要

### 観測 (2026-11-09、pam-passkey の統括セッション)

`mcp__ccmsg-v1__send` に `session_id` (worker の親セッション) と `agent_id` (Agent tool の spawn 結果の id) を付けると、そのセッション内で走っている特定の worker に直接届き、worker はそれを読んで応答できた (worker からは SendMessage で返答)。別セッションからでも同じ経路で使える。ccmsg の webui ではチームメートのセッションとその間の SendMessage も見えるので、引き継いだ後の往復も追える。

### 提案 (`reference/session-state/handoff.md` の改訂)

- 6 節「peer と worker」の「worker は新から使えないので再 spawn 手順」を改める: **役に立つ (文脈が温まっている) worker は `session_id + agent_id` を本文で渡し、新がそのまま使う**。旧は worker に「新しい統括の session_id は X、以後の報告は ccmsg send でそちらへ」と伝える。worker は SendMessage では旧の統括にしか返せないので、新宛ては `mcp__ccmsg-v1__send` を使わせる
- 引き継がない worker は旧が **TaskStop で止めてから** 止まる (ccmsg 上で生きている worker = 引き継いだ worker、と見分けられるようにする)
- 旧が閉じる範囲の worker は従来どおり旧が受け取る
- 受け側の手順に「渡された worker には ccmsg send (session_id + agent_id) で話しかける。agent_id は spawn 結果の内部値で peers には載らないので、本文に書かれたものだけが手掛かり」を足す

## 背景

pam-passkey の統括セッションでの実機観測。

## 受け入れ条件

- [ ] handoff.md の 6 節と受け側の手順を上の形に
- [ ] ccmsg skill (`skills/ccmsg/SKILL.md`) の `agent_id` の説明に「別セッションの統括から、引き継いだ worker に話しかける用途」を 1 行
