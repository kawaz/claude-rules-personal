---
title: "docs-structure skill の runbook 命名規則と実態の乖離"
status: open
category: tech-memo
created: 2026-06-18T13:31:45+09:00
last_read:
open_entered: 2026-06-18T13:31:45+09:00
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

# docs-structure skill の runbook 命名規則と実態の乖離

## 観測 (フラグまで)

`for-me/skills/docs-structure/SKILL.md` は `docs/runbooks/<f>` を以下と定義している:

> サブディレクトリ内のファイル名は原則 `YYYY-MM-DD-<slug>.md`
> - 例外: `decisions/DR-NNNN-title.md`、`design/<topic>-<sub>.md`

→ runbook には例外規定なし = `YYYY-MM-DD-<slug>.md` 強制と読める。

一方、`~/.local/share/repos/github.com/kawaz/*/main/docs/runbooks/` の実態 (2026-06-18 時点):

| リポ | runbook ファイル名 | 命名 |
|---|---|---|
| bump-semver | `justfile-pattern-audit.md` | date-less |
| cmux-msg | `spawn-troubleshooting.md` | date-less |
| authsock-warden | `release-notarization-403.md` | date-less |
| cache-warden | `apple-signing-secrets-setup.md` 他 3 件 | date-less |
| claude-plugin-reference | `cc-version-maintenance.md` | date-less |
| claude-rules-personal | `2026-05-21-external-skill-setup.md` | YYYY-MM-DD- |
| hyoui | `2026-05-27-child-orphan-detection.md` | YYYY-MM-DD- |

主流は **date-less `<topic>.md`** (6 リポ / 8 件中)、`YYYY-MM-DD-` 付きは 2 リポのみ。

## 議論材料 (= 判断材料、結論ではない)

runbook の性質から見ると:

- **runbook** = 「最新の運用手順」 (= 同 topic 内で常に live)
- **journal/findings** = 時系列の生記録・確定事実 (= 日付が意味を持つ)

この性質差を踏まえると、runbook に日付プレフィックスをつけると:

- 「古い手順を誤参照するリスク」(= 同 topic の旧 runbook が日付付きで残ると、最新を探すのに 1 段認知負荷が増える)
- 一方で「いつから運用されている手順か」が file 名で読める利点もある

主流派 (date-less) は前者を重視、少数派 (date 付き) は後者を重視している可能性。

## 一次資料

- skill 本体: `~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/for-me/skills/docs-structure/SKILL.md` (該当箇所: 「命名規則」§ + 「ディレクトリ構造」§ の `runbooks/<f>` 行)
- 実態: `find ~/.local/share/repos/github.com/kawaz/*/main/docs/runbooks -type f -name '*.md'`

## 想定アクション (= 一案、判断は kawaz)

A. **skill を実態に追従**: `runbooks/<topic>.md` (date-less) を許容と明記、`YYYY-MM-DD-` 付きを別例外として残す
B. **少数派 2 リポを skill に追従**: `claude-rules-personal/docs/runbooks/2026-05-21-external-skill-setup.md` 等を `<topic>.md` にリネーム
C. **両許容を明文化**: 「topic 不変なら date-less、再作成が予想されるなら date 付き」等の判断指針を skill に追加

判断は kawaz に委ねる。私 (cmux-msg セッション) からは「主流が date-less である」事実までを報告。

## 発端

`kawaz/claude-plugin-reference` で docs-structure 準拠見直しをやった際、`cc-version-maintenance.md` (date-less) が skill 規約に違反するように見えるが、主流リポ群と整合していることを発見。skill 側を実態追従するのが筋と判断 (cmux-msg セッション 2026-06-18)。

## 関連

- `for-me/skills/docs-structure/SKILL.md`
- `for-all/rules/dogfooding-feedback-upstream.md` (= 本 issue のスタンス: フラグ + 一次資料、断定しない)
