---
title: "worktree-workflow runbook template (= just push gate で bump-semver vcs is worktree を使う)"
status: open
category: request
created: 2026-06-22T18:12:43+09:00
last_read:
open_entered: 2026-06-22T18:12:43+09:00
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

# worktree-workflow runbook template (= just push gate で bump-semver vcs is worktree を使う)

## 概要

kawaz/bump-semver v0.40.0 で land した `vcs is worktree` / `vcs promote` / `vcs sync` を使い、各 kawaz リポの justfile に push gate を標準化する。runbook テンプレ (`docs/runbooks/worktree-workflow.md`) として docs-structure skill の templates 配下に置く。

## 背景

kawaz/bump-semver v0.40.0 で worktree/promote/sync subcommands が land した (= DR-0038)。`vcs is worktree` で「現在 secondary workspace / linked worktree か」が判定でき、`vcs promote` で default branch/bookmark を forward、`vcs sync --onto REF` で worktree のベース更新ができる。

これを各 kawaz リポの justfile 標準テンプレに乗せたい。

## 望ましい姿

各 kawaz リポの justfile に以下のような push gate を入れる:

```just
push:
    @if bump-semver vcs is worktree; then \
        wt=$(bump-semver vcs get worktree-name); \
        bn=$(bump-semver vcs get default-branch); \
        echo "⚠ worktree '$wt' にいます。${bn} に合流が必要です。"; \
        echo ""; \
        echo "  1. ベースを最新に同期:   just sync"; \
        echo "  2. ${bn} に合流:          just promote"; \
        echo "  3. push:                  just push"; \
        exit 1; \
    fi
    # 既存の検証ゲート + vcs push

sync:
    bump-semver vcs sync --onto origin/$(bump-semver vcs get default-branch)

promote:
    bump-semver vcs promote
```

これを **runbook (= docs/runbooks/worktree-workflow.md)** としてテンプレ化する。docs-structure skill の templates 配下に置くのが筋。

## 含む

- justfile の push/sync/promote task の標準テンプレ
- 各リポでの adopt 手順 (= migration step)
- worktree から落としたままの場合の挙動・対処
- bump-semver v0.40.0+ を前提とする旨

## 含まない (= 別 issue)

- claude-plugin-reference 等 既存 kawaz リポ群への一斉 migration (段階的に各リポで判断)
- Claude Code EnterWorktree 側の `worktree.baseRef = head` 設定変更可否 (= harness 側の話)
- jj-worktree plugin への bookmark 自動セット提案 (= jj-worktree plugin 側で別途検討)

## 一次資料

- bump-semver DR-0038: kawaz/bump-semver/docs/decisions/DR-0038-vcs-worktree-promote-sync.md
- 元 issue (起票時点の問題提起): claude-plugin-reference docs/journal/2026-06-18-worktree-promote-and-marker-lockfile.md (= 起票根拠の journal)
- bump-semver v0.40.0 release: https://github.com/kawaz/bump-semver/releases/tag/v0.40.0

## 実装委ねるポイント

- runbook の置き場所 (= docs-structure の runbook 規約 templates/ サブ)
- 既存 docs-structure templates との一貫性 (= 命名・章立て)
- justfile の sync/promote task 名や hint メッセージ表現

実装方針は当事者判断に委ねる。本 issue は **必要性のフラグ + 一次資料 (= bump-semver 側の land 済み実装と DR) の提示** に留める。

## 受け入れ条件

- [ ] docs-structure skill の templates 配下に `runbooks/worktree-workflow.md` テンプレが追加される
- [ ] justfile 標準テンプレに push/sync/promote task のサンプルが記載される
- [ ] bump-semver v0.40.0+ を前提とする旨が明記される
- [ ] 各リポでの adopt 手順 (migration step) が記載される
