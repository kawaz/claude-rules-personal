---
name: no-claude-prefix-in-names
description: 新しいリポ・plugin の名前に claude / anthropic の接頭辞を付けない (classifier に止められやすくなる)
metadata:
  type: feedback
---

kawaz の裁定 (2026-11-15): **新しく作るリポジトリ名・plugin 名に `claude-` や `anthropic` 系の接頭辞を付けない。**

**Why:** `claude` や Anthropic を連想させる接頭辞の付いた plugin / リポは、auto mode の classifier などに止められやすい。ccmsg ほか既存のもので実際に困った。

**How to apply:** 名前は扱う対象や機能の語で付ける (例: Claude Code 向けの参照ファイル置き場でも `modern-web-guides`)。既存の `claude-*` リポの改名はこのメモの範囲外で、kawaz の指示があった時に行う。
