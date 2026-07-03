---
title: "メタ認知系ルールのモデル世代交代時再検証運用"
status: idea
category: idea
created: 2026-07-03T14:13:51+09:00
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

# メタ認知系ルールのモデル世代交代時再検証運用

## 概要

`sloppy-ai-patterns` / `synthesis-temptation-guard` / `default-convergence-guard`
等のメタ認知系ルールは、特定世代の Claude モデルの失敗観測に基づいて書かれている。
モデル世代交代後にそのガードが不要化しても、常時ロードの context を食い続ける
懸念がある。対策として「モデル世代替わり時に対象ルールを再検証する」運用
(対象 rule へのマーカー付与、または既存の定期棚卸しへの組込み) を検討したい。

## 背景

これらのルールは各々「特定世代のモデルがやりがちな失敗パターン」を実例観測
ベースで言語化したもの。モデルが賢くなり該当の失敗傾向が消えれば、ルール自体
が不要化する可能性があるが、現状は一度書かれたら恒久的に常時ロードされ続ける
仕組みしかなく、不要化を検知する仕組みがない。

本 issue は 2026-07-03 に実施したエコシステム横断監査 (本リポ内 3 subagent
起動) 由来。

## 受け入れ条件

- [ ] メタ認知系ルールをモデル世代交代時に再検証する運用方針について kawaz の
      判断が得られている (マーカー付与 / 定期棚卸し組込み / 対応不要、のいずれか)
