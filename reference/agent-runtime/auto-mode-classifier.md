# auto mode classifier の設定と、プロジェクト固有の許可

auto mode では tool call を classifier (別モデル) が審査する。何を読み、どこに何を書けば誤拒否が減るかの正本。置き場の禁則は `classifier-notes` rule。

## classifier が読むもの

- user settings (`$CLAUDE_CONFIG_DIR/settings.json`) の `autoMode`、managed settings、`--settings` の inline JSON。**project の `.claude/settings.json` / `.claude/settings.local.json` は読まない** (リポに checked-in された設定が allow を注入できないようにするため)
- CLAUDE.md / `.claude/rules/` の本文は**効かない** (`.claude/rules/` に allow を書いても同じ操作が止められ続けた、実測 2026-11-08)。classifier に効くのはユーザの発言と `autoMode`、完全一致の allow だけ
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

- server-side review (gateway 経由でも env 未設定で既定 on、2.1.319 で実測): session の model request の `safeguards` 欄で頼み、応答の `safeguard_results` で判定が返る。別 call は無い。transcript の assistant に `serverClassifierRequest` が付くのが頼んだ印
- server が判定を返さない時 (gateway の openai 経路を通った main / subagent):
  - feature flag と telemetry を止めていない環境 (kawaz の今の gateway 構成): その 1 本で以後プロセス全体が local classifier に切り替わる (ラッチ、再起動で戻る)。main も課金対象の local 判定になる
  - `CLAUDE_CODE_DISABLE_FEATURE_FLAGS` / `DISABLE_TELEMETRY` / `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` のどれかを設定した環境 (2.1.319+): local に落ちず、その call は `Auto mode is unavailable: its safety check does not run for this session` で拒否 (`reasonCode` `classifier:auto-mode:unavailable`)。ラッチは立たず main は server 判定のまま。openai 経路の worker の tool call は全部拒否になる
  - `CLAUDE_CODE_AUTO_MODE_SERVER=0` は常に local classifier だけを使う (上の拒否も起きない)。`=1` は `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` があっても server を使う (2.1.319+)
  - `claude -p` は main の call がこの拒否を受けると exit 1 (JSON は `subtype:"success"` のまま `permission_denials` に載る)。subagent の call だけの拒否は exit 0 なので、script では `permission_denials` を見る
  - 観測: `--debug-file` の `[server-classifier]` 行と `[API REQUEST] source=side_query` (local classifier の request)。手順は lab-claude の `experiments/01-auto-mode-server-2-1-319/`
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
    "Local config and state operations for these user-authored tools are routine: llm-gateway, ccmsg, hyoui, cache-warden, bump-semver, kuu (directories ~/.config/<tool>/, ~/.local/share/<tool>/, ~/.local/state/<tool>/, ~/.cache/<tool>/). This covers reading and editing their config files and appending to or rewriting their key-ring files by rename. It does not cover deleting credential or key files (the user must name the file), copying those files out of their directories or into any repo, printing secret values into the transcript, shell rc files, ~/.ssh, ~/.config/gh, launchd or systemd units, or any effect those CLIs have beyond this machine (pushes, uploads, deploys, messages), which is judged on its own terms",
    "In the trusted repos, `jj commit`, `jj git push`, the `just push` recipe and the `cd <dir> && direnv exec . <cmd>` wrapper are the ordinary commit/push path; treat them like plain `git commit` / `git push` to the repo's own remote. This clears the destination only: rewriting history others authored (`jj abandon`, `squash`, `rebase`, moving a bookmark backwards) is still Git Destructive, and what is pushed is still subject to Credential Leakage, Sensitive-Source Provenance and Out-of-Place Publication",
    "Editing and deleting files and directories under /tmp or /private/tmp that this session or its workers created is routine"
  ],
  "soft_deny": [
    "$defaults",
    "Editing the autoMode block in settings.json needs the user's explicit instruction naming the change"
  ]
}
```

allow は当たれば必ず通すので、広い allow は deny より危険 (`claude auto-mode critique` は「`~/.config` 配下なら何でも」の文を、鍵の中身を transcript に出す / shell rc や unit の編集まで通すとして退ける)。ツールは名前で列挙し (ownership は transcript から検証できない)、閉じていない方向 (削除、コピー、CLI の外向き効果) を除外文で全部塞ぐ。既定 allow に Multi-Agent Coordination と Session-Created Job Cleanup があるので、SendMessage と `/tmp` の行は `critique` が冗長と言えば削る。`/auto-mode-setup` を後から回す時は「add」を選ぶ (replace は手書き分を消す)。

## プロジェクト固有の許可 (`.claude/settings.local.json` の完全一致 allow)

プロジェクト固有に要る Edit / Bash の許可は、そのプロジェクトの `.claude/settings.local.json` の `permissions.allow` に**ワイルドカード無しの完全一致形**で書く。完全一致の allow は classifier より先に評価されて確実に通る。ワイルドカード付き (`Bash(llm-gateway daemon *)` 等) は classifier の判定に回るので使わない。入れるのは**実際に繰り返し止められた操作だけ** (先回りで列挙しない)。

```json
{
  "permissions": {
    "allow": [
      "Edit(~/.config/foo/bar.toml)",
      "Bash(llm-gateway daemon reload unstable)"
    ]
  }
}
```

- Edit は `~/` 始まりか絶対パスで書く
- Bash は引数込みのコマンド全文で書く (止められたコマンドと 1 文字違えば当たらない)
- JSON の文字列に入るので、コマンド中の `\n` は `\\n` と書く
- `.gitignore` に `.claude/settings.local.json` を入れ、commit しない

エージェントは `.claude/settings*.json` を書けない (Write / Edit / `cp` とも、許可の後でも fast classifier が止める)。足す時は ccmsg の `permit` ツールの `project_permissions` に `{ "add": "<rule>" }` (要らなくなった rule は `{ "remove": "<rule>" }`) を書く。kawaz が webui で押すと ccmsg の daemon がそのセッションのプロジェクトの `.claude/settings.local.json` に書き、起動中のセッションにすぐ効く (再起動不要。差分が `ccmsg:daemon` の封筒で届く)。今止められた操作をすぐ再実行したい時は `commands` / `intents` も一緒に出す。Edit の rule は `~/` でなく絶対パス (`Edit(/Users/…/file.toml)`) で書く (`~/` 形は効かなかった、実測 2026-11-08)。

## 誤拒否の見方と直し方

- 止められた時にユーザへ許可を求める手順 (ccmsg の `permit` ツール、許可後は同じ操作を書き換えずに再実行、伝言の許可は効かない、subagent は委譲元が代行) は rule `classifier-notes` が正本。ここは「なぜ止まったか」を読んで設定を直す側
- 拒否文言の `[...]` が当たった rule 名。`claude auto-mode defaults --label '<名前>'` で全文
- 同じ送り先 (host / remote / bucket) で繰り返し止まる → `environment`、面をまたいで同じ操作で止まる → `allow`、そのプロジェクトの同じ操作で止まる → `.claude/settings.local.json` の完全一致 allow、1 回きり → 次の message で intent を名指しして再試行 (`/permissions` の Recently denied で `r`)
- 「Blocked by fast classifier」は docs に無い文言 (server-side review の拒否と推測)。「no verdict」系は classifier 自体の失敗で、設定では直らない
