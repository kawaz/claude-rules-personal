# auto mode classifier の設定と、プロジェクト固有の環境説明

auto mode では tool call を classifier (別モデル) が審査する。何を読み、どこに何を書けば誤拒否が減るかの正本。置き場の禁則は `classifier-notes` rule。

## classifier が読むもの

- user settings (`$CLAUDE_CONFIG_DIR/settings.json`) の `autoMode`、managed settings、`--settings` の inline JSON。**project の `.claude/settings.json` / `.claude/settings.local.json` は読まない** (リポに checked-in された設定が allow を注入できないようにするため)
- Claude と同じ CLAUDE.md / `.claude/rules/` の内容 (symlink も辿る)
- transcript: ユーザの message、read-only 以外の tool call。tool result は剥がされる (ファイルや web の内容で classifier を操作できない)
- 評価順: `permissions.allow/ask/deny` → read-only / cwd 内の自動承認 → classifier。**`Bash(*)` のような広い allow は auto mode では停止され classifier が走る。狭い完全一致 (`Bash(bun test)`) は classifier を飛ばす**。`autoMode.classifyAllShell: true` で全 shell を classifier 経由にできる
- 会話で述べた境界 (「push 前に確認」) は transcript から読まれるので、compaction で消えると効かなくなる。恒久にするなら `autoMode` か `permissions.deny`

## `autoMode` の 4 区分 (`claude auto-mode defaults` で既定を印字)

| 区分 | 意味 | 既定 |
|---|---|---|
| `hard_deny` | 無条件 block。intent でも allow でも覆らない | 1 本 (Data Exfiltration) |
| `soft_deny` | 破壊的・危険な操作の block。**ユーザの明示 intent か `allow` で解除できる** | 72 本 (Git Destructive、Production Deploy、Credential Materialization、Secret-Store Writes、Self-Modification、Auto-Mode Bypass 等) |
| `allow` | soft_deny の例外 | 17 本 (Local Operations、Standard Credentials、Multi-Agent Coordination、Session-Created Job Cleanup、Git Push Destination、Memory Directory 等) |
| `environment` | rule でなく前提知識の slot (Organization / Secrets management / Trusted repo / Source control / Sensitive data locations 等 21 slot)。`None configured` の slot は保守側の既定で動く | 21 slot |

各配列は自然文の entries。先頭に `"$defaults"` を置くと既定が継ぎ足される (省くとその区分の既定を全部捨てる)。`claude auto-mode config` で effective、`claude auto-mode critique` で曖昧・冗長の指摘。

## 課金とコスト

- server-side review (対話セッションで既定、gateway 経由でも v2.1.278+ で既定): session の model request に同梱され別 call は無い。gateway が review を落とすと local classifier に fallback
- local classifier: Claude Code 自身が Sonnet 5 に別 request を投げ、API / Enterprise では token usage に数える
- どちらでも entries と CLAUDE.md は毎 check の request に載る。**書く量の規律は rule と同じ**

## 面横断の entries (user settings に書く)

personal 面の例。業務面は org / remote を差し替えて別の config dir に書く。

```json
"autoMode": {
  "environment": [
    "$defaults",
    "Organization: kawaz (individual developer, open source). Primary use: software development on personal and own-company repositories",
    "Trusted repos: everything under ~/.local/share/repos/github.com/kawaz/ and ~/.local/share/repos/github.com/zunsystem/ (both owned by the user); their GitHub remotes are the user's own",
    "Secrets management: per-tool config under ~/.config/<tool>/ and 1Password via `op run`; credential files there are the user's own",
    "Multiple Claude Code sessions run on the same machine for the same user and coordinate through SendMessage and ccmsg; sending messages between them is routine"
  ],
  "allow": [
    "$defaults",
    "Reading and editing files under $XDG_CONFIG_HOME, $XDG_DATA_HOME, $XDG_STATE_HOME, $XDG_CACHE_HOME, $XDG_RUNTIME_DIR (and their ~/.config, ~/.local/share, ~/.local/state, ~/.cache defaults) for the user's own tools, including config, key rings and credential files, is routine operation of those tools",
    "Committing and pushing with `jj`, `just push` and `cd <dir> && direnv exec . <cmd>` to the trusted repos is routine",
    "Editing and deleting files and directories under /tmp or /private/tmp that this session or its workers created is routine"
  ],
  "soft_deny": [
    "$defaults",
    "Editing .claude/rules/classifier.local.md in any repo or the autoMode block in settings.json needs the user's explicit instruction naming the change"
  ]
}
```

既定 allow に Multi-Agent Coordination と Session-Created Job Cleanup があるので、SendMessage と `/tmp` の行は `critique` が冗長と言えば削る。`/auto-mode-setup` を後から回す時は「add」を選ぶ (replace は手書き分を消す)。

## プロジェクト固有の環境説明 (`classifier.local.md`)

正本は privacy リポ `classifier/classifier-<repo>.md`。プロジェクト側は symlink と `.gitignore`:

```bash
cd <repo>
mkdir -p .claude/rules
ln -sfn <privacy リポへの相対パス>/classifier/classifier-<repo>.md .claude/rules/classifier.local.md
printf '\n# auto mode classifier 向けの個人設定 (正本は privacy リポ、symlink)\n.claude/rules/*.local.md\n' >> .gitignore
```

本文の型 (箇条書きのみ、各項目は settings の entries にそのまま移せる 1 文):

```markdown
# <repo> の auto mode classifier 向け環境説明

このファイルは auto mode classifier への環境説明で、Claude の行動規範ではない。各項目は settings.json の `autoMode` の entries と同じ粒度で書く (面全体に効かせたい項目はそちらへ移してここから消す)。

## environment

- <このリポの runtime が置く場所、動かす unit や CLI など、判定に要る状況の包括記述>

## allow

- <このリポで通常運用と見なす操作。既定 soft_deny の名前 (Credential Materialization 等) を否定する形で書くと効きやすい>

## soft_deny

- <このリポで明示指示が要る操作 (本番 unit の変更、鍵の削除 等)>
- Editing this file (.claude/rules/classifier.local.md) or the `autoMode` block in settings.json needs the user's explicit instruction naming the change
```

実例は privacy リポの `classifier/classifier-llm-gateway.md`。

## 誤拒否の見方と直し方

- 拒否文言の `[...]` が当たった rule 名。`claude auto-mode defaults --label '<名前>'` で全文
- 同じ送り先 (host / remote / bucket) で繰り返し止まる → `environment`、同じ操作で止まる → `allow`、1 回きり → 次の message で intent を名指しして再試行 (`/permissions` の Recently denied で `r`)
- 「Blocked by fast classifier」は docs に無い文言 (server-side review の拒否と推測)。「no verdict」系は classifier 自体の失敗で、設定では直らない
