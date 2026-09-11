---
name: no-chat-refs-in-docs
description: docs (DR / DESIGN / issue) に ccmsg の room・メッセージ番号 (rNNN mNN) を書かず、日付と判断の要点だけを書く
metadata:
  type: feedback
---

DR / DESIGN / issue / journal に、kawaz との会話の出典として ccmsg の room・メッセージ番号 (`r292 m10〜m19` のような形) を書かない。書くのは **日付と判断の要点** (「kawaz 2026-09-11」の形) だけ。

**Why:** room は一時的で消えれば辿れず、辿れても第三者や後日の読者には意味が無い (kawaz 2026-09-12)。

**How to apply:** 裁定を記録する時は `(kawaz <日付>)` + 要点。会話の番号はセッション内の作業メモ (`/tmp` や state ファイル) にだけ置く。既存 docs で見つけたら触ったついでに直す。
