---
name: knowledge
description: 読むだけの参照知識のカタログ (索引 + 本文の二段構成)。索引に発火語があるトピックだけ `reference/<slug>.md` を Read する。収録トピックの発火語 — daemon / service サブコマンド体系、常駐プロセスの status・restart・log の CLI 設計、launchd / systemd --user への常駐登録、supervise 監督者構成。
---

# knowledge — 参照知識カタログ

`${CLAUDE_SKILL_DIR}/reference/` 配下のうち、**いま必要なトピックのファイルのみ Read** する (索引 + 本文の二段構成で context を最小化する)。索引だけ読んで該当が無ければ何も Read しない。

索引エントリの書き方・追加削除の規約は `for-all/rules/rule-writing-guidelines.md` (常時ロード rule) が正本。

## 索引

- [cli-daemon-subcommands](reference/cli-daemon-subcommands.md) — kawaz 製 CLI 共通の `daemon` / `service` サブコマンド体系 (1 instance = 1 unit、JSON 出力規約、OS 常駐登録)。
  発火語: daemon サブコマンド, service サブコマンド, supervise, 常駐プロセスの status / restart / log, launchd / systemd --user 登録, unit
