# codex plugin の broker / background / 結果取得機構

- 起票: 2026-06-15
- 対象: `openai/codex-plugin-cc` (commit: clone時点の HEAD)
- 動機: 「codex にレビューさせて」と頼むと `/codex:status` → `/codex:result` を手で打たされる。
  `/codex:setup` すると詰まりが解消することがある。この因果を憶測なく特定する。

> ラベル規約 (claude-plugin-reference 準拠):
> `[コード確定]` = companion script のコードで確認、`[spec]` = 公式 docs、
> `[未検証]` = 実機未確認 (要検証 → 格上げ)、`[推論]` = 確定事実からの演繹

## 判明した事実

### F1. `/codex:setup` は永続 state を書かない (素の場合)

`buildSetupReport` は node/npm/codex の有無・auth・review gate を**点検して返すだけ**。
state file に書くのは `--enable-review-gate` / `--disable-review-gate` 指定時の
`config.stopReviewGate` のみ。素の `/codex:setup` は state を一切変更しない。[コード確定]

→ **毎セッションの予防的 setup は無意味。** review gate は project 単位で永続するので
1 回で足りる (再実行不要)。[コード確定]

### F2. 「setup すると協調する」の正体は broker (session runtime) の確立

`/codex:setup` は `getCodexAuthStatus` 内で `CodexAppServerClient.connect` を呼ぶ。
これが broker (= codex app-server プロセス) に接続する副作用を持つ。[コード確定]

- broker は `os.tmpdir()` に `mkdtempSync` で作られる一時 dir で動く実プロセス。
  endpoint/pid/log を持つ。[コード確定]
- broker session file は `resolveStateDir(cwd)/<BROKER_STATE_FILE>` に保存されるが、
  本体プロセスが死ねば再利用不可。[コード確定]
- `session-lifecycle-hook.mjs` の `handleSessionEnd` が `teardownBrokerSession` を呼ぶ
  → **broker は session 終了で破棄される = セッション単位で揮発する。**[コード確定]

→ setup 自体が協調を生むのではなく、setup が **broker を温める契機**になっている。
詰まったとき手で setup を打つのは、事実上「broker リセットボタン」として効いていた。[推論]

### F3. status/result は session_id 紐付けで job を解決する

`getCurrentClaudeSessionId()` は環境変数 `CODEX_COMPANION_SESSION_ID` を読む。
この変数は `handleSessionStart` (SessionStart hook) が `CLAUDE_ENV_FILE` 経由で書く。[コード確定]

- session_id が無い (= hook 未発火 / `CLAUDE_ENV_FILE` 不在) と
  `filterJobsForCurrentClaudeSession` は**フィルタせず全 job を返す** (null 時 fallback)。[コード確定]
- → 紐付けが曖昧な状態だと、Claude が「このセッションの job」と確信できず
  status/result を kawaz に振りやすくなる。[推論]

### F4. background レビュー/タスクは detached worker で broker を別プロセスに立てる (詰まりの主因)

`--background` 指定時、`enqueueBackgroundTask` → `spawnDetachedTaskWorker` が
`spawn(..., { detached: true, stdio: "ignore" })` + `child.unref()` で
**完全に切り離した別プロセス**を起動する。[コード確定]

帰結 (すべて [コード確定] からの [推論]):
- detached worker は自分のプロセスで broker を立てる → **メインの Claude session と broker 非共有**。
  メインから見ると runtime が `direct` のまま (詰まりの一因)。
- `child.unref()` で親は待たず即リターン → 結果は worker が非同期にファイルへ書く →
  **status/result を叩く以外に取得経路がない。**
- foreground (`handleReviewCommand` / `--background` なしの `handleTask`) は
  **同一プロセスで** broker を立て結果をそのまま返す。
  → **broker がメインで立つのは foreground のときだけ。**[コード確定: handleTask の background 分岐は
  `options.background` ガード内のみ]

### F5. review.md のデフォルトは background に倒れやすい

`commands/review.md` の Execution mode rules:
「明らかに小さい (1-2 file) ときだけ wait を勧め、**それ以外・規模不明を含むすべてで background を勧める**」。[コード確定: commands/review.md 本文]

→ kawaz が `--wait`/`--background` を指定せず「codex にレビューさせて」と頼むと、
Claude は規模見積もりで background に倒れ、F4 の破綻連鎖に入る。[推論]

### F6. rescue subagent への prompt 文言が内側 background 判定を引っ張る (2026-06-15 反証イベントで確定)

`codex:codex-rescue` subagent は forwarding wrapper で、prompt を内側 companion に
そのまま渡す。内側は F5 のデフォルト判断 (= 規模不明なら background) を引き継ぐため、
prompt 内の **示唆語**が判定を強く引っ張る。[実機確定: 下記「検証の詳細 / P-TODO1 部分検証」参照]

- `--background` を直接書かなくても、「background で」「長時間 task OK」「放置で」
  「気長に」「並行で」等の示唆語で内側 background に倒れ、F4 の detached worker 経路に流れる
- 結果として外側 Agent の `<result>` には job ID 文字列のみが返り、status/result 手回収が発生する

→ 二層構成 (P2) の成立には「内側 background を発火させない prompt 文言ガード」が必須。
ルール `for-me/rules/plan-review-with-codex.md` の「prompt に書いてはいけない語」section
として明示済み。

## 実用的な示唆 / ベストプラクティス

### P1. 詰まりの根本原因

「background 実行 → detached worker → broker 非共有 → 結果ファイル送り → status/result 手回収」
という連鎖。kawaz が明示的に background を選ばなくても、review のデフォルト判断 (F5) で
Claude が background に倒れることで起きる。**setup 不足ではない。**

### P2. 解決の核: rescue subagent の二層 background/foreground

`codex:codex-rescue` は **Agent tool で起動する subagent**。これを使うと:

- **メイン → rescue subagent**: `run_in_background: true` で起動。
  → メイン非ブロック (kawaz の「チャット常時開放」大方針を満たす)。
- **rescue subagent → codex companion**: subagent の prompt に `--background` を**渡さない**
  かつ **background 示唆語を含めない** (F6)。
  → `handleTask` が foreground 同期実行に流れ (F4 の background 分岐を踏まない)、
    subagent プロセスで broker が立ち、結果取得まで完走する。[コード確定: handleTask]
- 完了時、結果は `<task-notification>` の `<result>` でメインに返る。
  [部分検証済 (2026-06-15): F6 違反下では崩壊することを実機確認、文言ガード遵守下の完全動作は未検証]

→ **メイン外側 = background / subagent 内側 = foreground** の二層にすれば、
非ブロックと broker 一貫 + 自動回収を両取りできる。status/result 手回収が消える。
[文言ガード前提、P-TODO1 残課題]

### P3. companion 直叩きは依然禁止

F4/P2 は「rescue subagent 経由」が前提。companion script の bash 直叩きは
review contract / job tracking / broker 管理を bypass するので従来通り禁止。

### P4. 残るトレードオフ (ヨイショ回避のため明示)

rescue subagent 内部が foreground で回る間、subagent 内の bash 経由 codex 実行は
Claude Code の Bash tool 10 分制約を受けうる [spec: BASH_MAX_TIMEOUT]。
大規模一発レビューでは subagent 内部でタイムアウトしうる。
ループ用途 (各周の差分が小さい) なら実害は出にくい。**A/B/C どの設計でも完全には消せない構造的制約。**

## 検証の詳細

### 確定事実の出典 (companion script)

| 事実 | 関数 / 箇所 |
|---|---|
| F1 | `buildSetupReport` / `handleSetup` (setConfig は review-gate 時のみ) |
| F2 | `getSessionRuntimeStatus`, `getCodexAuthStatus`→`CodexAppServerClient.connect`, `broker-lifecycle.mjs` (mkdtemp/teardownBrokerSession), `session-lifecycle-hook.mjs` handleSessionEnd |
| F3 | `getCurrentClaudeSessionId`, `filterJobsForCurrentClaudeSession` (null fallback), `handleSessionStart` appendEnvVar |
| F4 | `spawnDetachedTaskWorker` (detached/unref), `enqueueBackgroundTask`, `handleReviewCommand` (foreground 同一プロセス), `handleTask` (background ガード) |
| F5 | `commands/review.md` Execution mode rules |
| F6 | 下記「P-TODO1 部分検証」の実機観測 |

### P-TODO1 部分検証 (2026-06-15、CC: Opus 4.7[1m])

#### 観測イベント

`for-me/rules/plan-review-with-codex.md` 改訂作業の発注時、メイン (Fable 5) から
rescue を以下の条件で起動:

- 起動: `Agent({ subagent_type: "codex:codex-rescue", run_in_background: true, prompt: ... })`
- prompt 末尾に「長時間 task OK、background で進めてください」と記載

結果: `<task-notification>` の `<result>` には
`"Codex Task started in the background as task-mqeik2ip-3ew8t7. Check /codex:status task-mqeik2ip-3ew8t7 for progress."`
のみ。レビュー結果全文は乗らず、kawaz の手回収が必要になった。

#### 解釈

- 外側 Agent は background なのでメイン非ブロックは確保された (= 二層構成の外側は成立)
- 内側 rescue が detached background 経路 (F4) に流れた = `<result>` は job ID 文字列のみ
- 原因: prompt の「長時間 task OK、background で進めてください」が F5 (review.md デフォルト判断)
  を background に倒した。`--background` を直接書かなくても **示唆語**で同等の崩壊が起こる (= F6)
- ドラフト P2 の「二層構成」自体は理論的には成立しうるが、**prompt 文言ガードが「`--background`
  を書かない」止まりでは不十分**であることが実機で確定

#### P-TODO1 の格上げ

- P-TODO1 → **「F6 違反下では崩壊する」を実機確定 (= ルール文言ガード追加の根拠)**
- 完全な肯定検証 (= 文言ガード厳守時に `<result>` に全文が乗ること) は別途必要
- ルール `for-me/rules/plan-review-with-codex.md` には「prompt に書いてはいけない語」と
  「prompt に書くべき語」section を新設し、禁則語リスト + 推奨文言を明示

### P-TODO (実機検証が必要 → 検証後に格上げ)

- [x] **P-TODO1 (反証側)**: F6 違反下で崩壊することは実機確定 (2026-06-15)。
  - [ ] **P-TODO1' (肯定側、要追検証)**: 文言ガード厳守時に `<result>` 全文が乗るか
- [ ] P-TODO2: broker が新セッション間で生存し再利用されるか
  (F2 では handleSessionEnd で teardown される = 揮発と読めるが、SessionEnd hook が
  毎回確実に発火するかは未観測)。生存するなら「project で 1 回 review/task すれば
  以降のセッションも broker 再利用で協調」が成立しうる。
- [ ] P-TODO3: rescue subagent 内部 foreground 実行が 10 分制約 (P4) に実際に当たる規模の閾値。

## 関連

- ルール `for-me/rules/plan-review-with-codex.md` の根拠 (F6 を反映した文言ガード追加済み)。
- ルール `for-me/rules/codex-plugin-install.md` の「毎セッション setup」記述は F1 で否定済み (補足済み)。
