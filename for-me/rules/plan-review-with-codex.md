# codex プラグイン経由のレビュー / 委譲

ユーザに plan / 設計 doc / 大規模リファクタ案を提示する前、または重い調査 / 修正タスクを codex に二次意見 / 委譲したいときに使う。事前に [[codex-plugin-install]] 完了が前提。

## AI 経路: `codex:codex-rescue` subagent 一本

AI から codex を呼ぶ正規ルートは `codex:codex-rescue` subagent のみ。Agent tool で `subagent_type: "codex:codex-rescue"` を起動、prompt に意図を書く。

```
Agent({
  subagent_type: "codex:codex-rescue",
  run_in_background: true,
  prompt: "<意図 + ref + 補足>"
})
```

rescue は forwarding wrapper、内部で `codex-companion.mjs task` に丸投げ → codex 側が prompt 解釈して適切に動く。`review` / `adversarial-review` / `plan` / `修正` / `調査` の使い分けマトリクスは不要、prompt の文言で codex が routing する。

### prompt の書き方

意図に応じて明示:

| 用途 | prompt に書く要点 |
|---|---|
| review (read-only) | 「`<path>` をレビュー」「read-only review、コード修正不要」 — `--write` 抑止 |
| adversarial review | 「設計判断・実装アプローチへの挑戦観点で」「focus: ...」 — adversarial framing 自動 |
| plan 作成 | 「`X` を実装する plan を立てて」「constraint は `Y`」 |
| 修正 / fix | 「`Z` の bug を root-cause investigation して fix も適用」 — default で `--write` 付与 |
| 過去 thread 続行 | 「resume して top finding を fix」 — rescue が `--resume-last` 付与 |
| 大規模調査 | 「`A` 全体を deep root-cause analysis、長時間 task OK」 |

ref も prompt に書く (= `CLAUDE.md` / 関連 DR / file path)。codex は単独で repo を読めるので、関連 file はリストで渡せば良い。

### background / foreground

- **background が default**: kawaz は「指示 → 放置 → 節目で見に来る」スタイル運用、長時間 task は遠慮なく background 化
- foreground は「結果待たないと次判断できない」「1-2 file の軽微 review」だけ
- Agent tool の `run_in_background: true` を指定 + prompt に「長時間 task OK、background で」と明示

### 結果取得

Agent tool は forwarding 完了通知のみ (= job ID 不明)、実体の codex job は別 process。完了確認は **kawaz が console で `/codex:status` 入力** → job ID 確認 → `/codex:result <job-id>` で全文取得 (= これらも `disable-model-invocation: true` で AI 不可)。

## kawaz 手動経路: slash command

kawaz が console で直接 codex を起動するとき。`disable-model-invocation: true` で AI からは呼べない:

| slash command | 用途 |
|---|---|
| `/codex:review` | 既存 PR / working tree diff の defect 検出 |
| `/codex:adversarial-review` | 設計判断・実装アプローチへの挑戦 (= focus text 末尾追加可) |
| `/codex:rescue` | 任意 prompt で codex 委譲 (= AI 経路 `codex:codex-rescue` の手動版) |
| `/codex:status` / `/codex:result` / `/codex:cancel` | job 管理 |
| `/codex:setup` / `/codex:setup --enable-review-gate` | plugin setup / review gate |

AI が「ここで codex 使ってほしい」と思ったら kawaz に `/codex:<cmd>` 入力依頼するのではなく、自分で `codex:codex-rescue` subagent を起動する (= 同等以上の能力)。

## `codex exec` 直叩き / companion script 直叩きは禁則

AI が `codex exec "..."` や `node "${CLAUDE_PLUGIN_ROOT}/scripts/codex-companion.mjs" ...` を Bash で直叩きしない。companion script を bypass すると review contract (= adversarial framing、瑣末フィルタ) / job tracking / review gate 機構が効かなくなる。

## review gate

`/codex:setup --enable-review-gate` で project 単位 ON。session 終了時に adversarial review が **同期 blocking** で走り、issue 検出時は stop を block する。ON 中は本 rule の foreground 経路と意味が重なる。

ON/OFF 切替は **kawaz の明示意図**で行う。AI は勝手に触らない。

## 関連

- [[codex-plugin-install]] — plugin 導入 / 認証境界 / jj 環境注意点
- [[feedback-evaluation]] — codex 指摘への evaluation (= ヨイショ禁止、悪い面を必ず指摘)
- [[discussion-style]] — 議論段階の振る舞い (= 方針確定前と確定後で投げ方が変わる)
