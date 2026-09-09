---
title: 読むだけ系 skill の knowledge カタログへの移行
status: open
category: design
created: 2026-09-09T09:45:46+09:00
last_read:
open_entered: 2026-09-09T09:45:46+09:00
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

# 読むだけ系 skill の knowledge カタログへの移行

## 概要

新設した `skills/knowledge/` (索引 SKILL.md + `reference/<slug>.md` の二段構成) に、
既存の「読むだけ」skill を移行できないか検討する。判定境界は
rule-writing-guidelines の 3 分類原則「実行資源 (コマンド・スクリプト・テンプレ・
付属ファイル) を伴うか」。

## 背景

候補と被参照箇所 (`rg -l '<slug>' for-all for-me skills agents docs` の実測):

- `app-file-placement` — 被参照: `skills/app-file-placement/SKILL.md` のみ
  (付属ファイルなし)
- `jj-rebase-options-reference` — 被参照: `skills/jj-rebase-options-reference/SKILL.md`,
  `docs/findings/2026-05-28-rules-narrow-scope-audit.md` (付属ファイルなし)
- `cross-env-ssh-signing` — 被参照: `skills/cross-env-ssh-signing/SKILL.md`,
  `for-all/rules/claude-config-dir-isolation.md`,
  `docs/findings/2026-05-28-rules-narrow-scope-audit.md`,
  `docs/journal/2026-07-07-rules-diet-restructure.md`。
  注記: コマンド手順を含むので手順書 skill 側に残すのが妥当かもしれない

移行するなら、上記の被参照箇所をすべて直すこと (Skill tool の
`rules-personal:<slug>` 呼び出しが消えるため、参照側の記述を
「knowledge skill の `reference/<slug>.md`」に書き換える)。

どれを移すかの判断は kawaz 裁定待ち。

## 受け入れ条件

- [ ] `app-file-placement` / `jj-rebase-options-reference` /
      `cross-env-ssh-signing` それぞれについて、knowledge カタログへ移行するか
      手順書 skill として残すかを kawaz が裁定する
- [ ] 移行対象と決まったものは `skills/knowledge/reference/<slug>.md` へ移設し、
      被参照箇所 (SKILL.md 自身・for-all/for-me rules・docs/findings・docs/journal 等)
      をすべて新参照形式に書き換える
- [ ] 旧 skill ディレクトリの扱い (削除 or リダイレクト) を決めて反映する
