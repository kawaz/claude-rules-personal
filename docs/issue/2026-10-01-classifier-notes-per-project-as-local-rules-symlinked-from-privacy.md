---
title: auto mode classifier 向けのプロジェクト固有の環境説明の置き場と書式を rule 化する
status: open
category: design
created: 2026-10-01T13:35:35+09:00
last_read:
open_entered: 2026-10-01T13:35:35+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: llm-gateway
---

# auto mode classifier 向けのプロジェクト固有の環境説明の置き場と書式を rule 化する

## 概要

auto mode classifier 向けのプロジェクト固有の環境説明の置き場と書式を rule 化する (kawaz 合意 2026-10-01、llm-gateway で最初の 1 本を運用開始)。rule 化は数リポで効きを見てから本文を起こす (後続)。

## 背景

根拠 (docs auto-mode-config / permission-modes): classifier は `autoMode` (user settings、project settings は読まない) と CLAUDE.md / `.claude/rules/` を読む。

- 面横断 (信頼リポ / secrets の置き場 / XDG 配下の自作ツール) は `autoMode` に置く
- プロジェクト固有は `.claude/rules/classifier.local.md` に置く

## 運用案

- 正本は `privacy-personal/classifier/classifier-<repo>.md` (private で版管理)
- 各リポの `.claude/rules/classifier.local.md` はそこへの相対 symlink、`.gitignore` に `.claude/rules/*.local.md`
- classifier.md を他用途に流用しない

## 書式案

- 冒頭 1 行で「classifier への環境説明、Claude の行動規範ではない」と宣言
- 以下 `environment` / `allow` / `soft_deny` / `hard_deny` の見出しに箇条書きのみ (散文禁止、各項目は settings の entries にそのまま移せる 1 文)
- 個別列挙より状況の包括記述を優先。個別に書くのは名前で同一性を判定するものと deny
- soft_deny に「このファイルと settings の autoMode の編集は明示指示が要る」を入れる

## 受け入れ条件

- [ ] 数リポで効きを確認する
- [ ] 置き場・書式を rule として起こす
