---
title: claude-plugin-reference plugin を退役させ、必要な事実だけ reference/claude-plugins/ に書き直す
status: open
category: task
created: 2026-09-29T14:45:45+09:00
last_read:
open_entered: 2026-09-29T14:45:45+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: ccmsg (クロスプロジェクト起票)
---

# claude-plugin-reference plugin を退役させ、必要な事実だけ reference/claude-plugins/ に書き直す

## 概要

claude-plugin-reference plugin を退役させ、必要な事実だけ
reference/claude-plugins/ に書き直す。

kawaz 2026-09-29: 「plugin reference は最近更新をサボっているので参照しない方がマシ。
ナレッジは reference にまとめる方針にし始めたし、そのリポ自体もう存在意義が無い。
plugin からも取り除く方がよい」。

## 背景

事実: claude-plugin-reference の最終検証は Claude Code 2.1.199、現行は 2.1.284。
2026-09-29 に ccmsg の実装 worker (sol) が古い reference を根拠に進めかけた。
今日の Mods 調査では binary 同梱の型定義 (claude-code.d.ts) と skill 本文、
`claude plugin validate` の実出力を正とする方法で精度が出た (reference/claude-mods/)。

## 受け入れ条件

- [ ] kawaz が settings.json の enabledPlugins から
      `claude-plugin-reference@claude-plugin-reference` を外す
      (AI は settings.json を書けない、kawaz 作業)
- [ ] plugin を「必ず参照する」と書いている rule / skill / reference の記述を
      洗い出して消す (grep 'claude-plugin-reference')
- [ ] 現行版で実機確認済みの最小の事実だけを `reference/claude-plugins/`
      (plugin.json / marketplace.json / hooks.json の形、command hook の
      JSON I/O の要点、`/Users/kawaz/.claude-personal/plugins/cache/local-issue/local-issue/0.2.12`
      等の置換、engine が plugin dir に書く型定義) に書き直す。
      素材は kawaz/ccmsg の findings 2026-09-29
      (hooks-json-modules-compat、claude-mods-experiments) と
      `src/plugin/claude.ts`。古い reference から内容を写さない
      (検証し直したものだけ)
- [ ] 上が済んだらリポ kawaz/claude-plugin-reference を archive
      (削除は kawaz 判断)

## TODO

<!-- wip 時のみ -->

着手は ccmsg の DR-0016 実装が一段落してから。
