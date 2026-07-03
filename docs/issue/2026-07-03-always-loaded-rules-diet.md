---
title: "常時ロードされる rules の token 予算を見直し、頻度の低いルールを skill へ降格する"
status: open
category: design
created: 2026-07-03T14:04:19+09:00
last_read:
open_entered: 2026-07-03T14:04:19+09:00
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

# 常時ロードされる rules の token 予算を見直し、頻度の低いルールを skill へ降格する

## 概要

常時ロードされる rules (`for-all/rules/` + `for-me/rules/` + overlay 分) の
合計サイズと token 予算を見直し、頻度の低いルールを skill へ降格する。

## 背景

実測: `for-all` 89.6KB + `for-me` 37.4KB = 127KB、overlay 込みで約 50
ファイルが毎セッション注入される (概算数万 token)。

降格候補:

- `tdd-and-test-design` (13KB、テスト作業時のみ必要)
- `homebrew-tap-deploy-key` (トリガ条件がルール内に明記済み)
- `codex-plugin-install` + `plan-review-with-codex` (codex 使用時のみ)
- `1password-error-notification` (エラー時のみ)

方針案: 「常時ロード = 行動制約 (constitution)、オンデマンド = 手順書」の
線引きを `rule-writing-guidelines` に明文化し、常時ロード予算 (例 15k
token) を `just lint-rules` の warning に組み込む。

skill 降格は description 設計が肝 (トリガ取りこぼし = 規律の静かな崩壊)
なので skill-creator の description 最適化 / eval の利用を推奨。

採否は kawaz 判断。

本 issue は 2026-07-03 に実施したエコシステム横断監査 (本リポ内 3
subagent 起動) 由来。

## 受け入れ条件

- [ ] 常時ロード vs オンデマンドの線引き基準が `rule-writing-guidelines` に明文化されている
- [ ] 降格候補ルールについて kawaz の採否判断が得られている
- [ ] 採用された降格について skill 化 (description 設計 + トリガ検証) が完了している
- [ ] 採用する場合、常時ロード予算チェックが `just lint-rules` 等の仕組みに組み込まれている
