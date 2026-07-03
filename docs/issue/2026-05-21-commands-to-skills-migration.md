---
title: "既存 commands を skills に移行する"
status: open
category: task
created: 2026-05-28T08:50:04+09:00
last_read:
open_entered: 2026-05-28T08:50:04+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin:
---

# 既存 commands を skills に移行する

## 背景

`$CLAUDE_CONFIG_DIR/commands/*.md` (カスタム slash command) と
`$CLAUDE_CONFIG_DIR/skills/<name>/SKILL.md` (skill) は、いずれも
「実行可能な frontmatter 付き Markdown」で本質的に同じ。Claude Code は
commands も skill 一覧に統合表示する。

二本立てで管理するより **skills に一本化** する方がシンプル
(setup.sh 拡張も skills だけ対応すれば済む。
`docs/issue/2026-05-14-setup-sh-skills-support.md` 方針 2)。

## 現状

`~/.claude-personal/commands/` に以下が直置きされている (2026-05-21 時点):

- `decomposition.md` / `decomposition.ja.md`
- `handoff.md`
- `itumono-contribute.md` / `itumono-full-loop.md` / `itumono-full-review.md`
- `itumono-nonstop.md` / `itumono-review-claude.md` / `itumono-review-codex.md`
- `itumono-review-gemini.md`

これらは overlay 管理 (claude-rules-*) されておらず、手動配置されたもの。

## 移行で必要な作業

1. **形式変換**: 単一ファイル `commands/<name>.md` → ディレクトリ `skills/<name>/SKILL.md`
2. **frontmatter 調整**: skill は `name` / `description` を要件とする。
   command の frontmatter との差異を埋める
3. **overlay リポへの取り込み**: 各 command を適切な overlay リポの
   `for-*/skills/<slug>/` に配置 (どのリポの for-all/for-me/for-others かは内容で判断)
4. **prefix 運用への乗せ替え**: setup.sh が `<repo>-<slug>` で配置するため、
   呼び出し名が `/itumono-full-review` → `/<repo>-itumono-full-review` 等に変わる。
   呼び出し名の変化を許容するか検討
5. 旧 `commands/*.md` の削除 (移行確認後)

## 論点

- prefix が付くと既存の呼び出し名が変わる。手に馴染んだ `/handoff` 等が
  `/personal-handoff` になる。許容するか、別の救済策を考えるか
- `itumono-*` 群はまとまった機能。個別 skill のままか、束ねるか

## 優先度

中。skills 一本化の方針は確定済み (`2026-05-14-setup-sh-skills-support.md`)。
setup.sh の skills 対応が入った後、計画的に移行する。

## 関連

- `docs/issue/2026-05-14-setup-sh-skills-support.md` (skills 配置の仕組み)
