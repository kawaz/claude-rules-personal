---
title: lint-rules の死角 — slug 改名・rule 統合時の dead wikilink を機械検出できない
status: open
category: design
created: 2026-07-07T17:19:41+09:00
last_read:
open_entered: 2026-07-07T17:19:41+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: 自リポ TODO
---

# lint-rules の死角 — slug 改名・rule 統合時の dead wikilink を機械検出できない

## 概要

`lint-rules` は for-all → for-me への越境リンク (rule ファイルが overlay 境界を跨いで参照する dead link) しか検査していない。rule 統合や slug 改名 (例: `say-command-katakana` → `notification-tips`) で発生する `[[旧slug]]` の dead wikilink は検出対象外。

対応案:

- `lint-rules` に「`[[slug]]` 全数抽出 → rules ファイル名 + skills ディレクトリ名に解決できるか検査」するチェックを追加する
- 他 overlay リポ由来の外部 slug (`identifiers-*` 等、ローカルには存在しない参照) の扱いを設計する必要あり — 許容リスト方式にするか、warning 止まり (fatal にしない) にするかはトレードオフ判断が要る

ついで検討 (別スコープ扱いでもよい):

- 「skill への参照は名前で書く」規約 ([[rule-writing-guidelines]]) の機械検査化。`[[skill名]]` wikilink が実在の skill ディレクトリ名と一致するかの検出も同種の仕組みで実現できる可能性がある

## 背景

rules diet restructure (`docs/journal/2026-07-07-rules-diet-restructure.md`) の作業中に判明。今回は手動 grep + レビュー agent で 3 箇所の参照更新漏れを確認して事なきを得たが、`lint-rules` が機械的に守ってくれない領域なので、次回以降の rule 統合・改名で同種の見落としが再発する可能性がある。

## 受け入れ条件

- [ ] `lint-rules` (または同等のチェックスクリプト) が `for-all/rules/` と `for-me/rules/` 双方の `.md` から `[[slug]]` 形式の wikilink を全数抽出する
- [ ] 抽出した slug が、ローカルの rules ファイル名 (拡張子抜き) または skills ディレクトリ名のいずれかに解決できるか検査する
- [ ] 他 overlay リポ由来と判定できる外部 slug の扱い (許容リスト / warning 止まり) の設計判断を下し、反映する
- [ ] (任意) `[[skill名]]` wikilink が実在の skill ディレクトリ名と一致するかの検査も同じ仕組みで追加できるか検討する
