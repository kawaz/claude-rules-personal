# codex プラグイン経由のレビュー / 委譲

ユーザに plan / 設計 doc / 大規模リファクタ案を提示する前、または重い調査 / 修正タスクを codex に二次意見 / 委譲したいときに使う。事前に [[codex-plugin-install]] 完了が前提。

## AI 経路: `codex:codex-rescue` subagent

AI から codex を呼ぶ正規ルートは `codex:codex-rescue` subagent のみ。Agent tool で起動する。

```
Agent({
  subagent_type: "codex:codex-rescue",
  run_in_background: true,
  prompt: "<意図 + ref + 補足>"
})
```

`codex exec` や `codex-companion.mjs` を Bash で直叩きしない。

## 通常経路: 外側 background / 内側 foreground

通常は `run_in_background: true` を指定し、prompt に `--background` を書かない。

- 外側 `run_in_background: true`: メインのチャットをブロックしない。
- 内側 foreground: companion の detached worker を避ける。
- prompt に `--background` / 「codex 側 background」/ 「長時間 task OK、background で」を書かない。
- `<task-notification>` の `<result>` にレビュー結果が十分入っているか確認する。

P-TODO1 は [検証不能: Claude Code 2.1.177]。`<result>` 全文返却は未検証として扱う。
通知が空 / job ID のみ / partial の場合は、結果取得の退避経路へ進む。

## 結果取得の退避経路

通知で全文を回収できない場合、AI は結果取得を完了したものとして扱わない。

1. subagent 通知に job ID があれば控える。
2. job ID が無ければ kawaz に `/codex:status` で対象 job を確認してもらう。
3. 完了後、kawaz に `/codex:result <job-id>` で全文を取得してもらう。
4. 取得した全文を読んでから次判断に進む。

`/codex:status` / `/codex:result` は kawaz 手動専用。AI は slash command 入力を代行できない。

## 大規模時

subagent 内側 foreground は Claude Code の Bash tool 10 分制約を受けうる。
大規模一発レビューでタイムアウトしそうな場合のみ、最初から codex 側 background を許可する。

その場合は prompt に次を明記する:

```
大規模レビューなので codex 側 background 可。
完了通知が job ID のみなら、結果取得は /codex:status と /codex:result で行う。
```

この経路では自動回収を期待しない。status/result 手回収を前提にする。

## prompt の書き方

| 用途 | prompt に書く要点 |
|---|---|
| review (read-only) | 「`<path>` をレビュー」「read-only review、コード修正不要」 |
| adversarial review | 「設計判断・実装アプローチへの挑戦観点で」「focus: ...」 |
| plan 作成 | 「`X` を実装する plan を立てて」「constraint は `Y`」 |
| 修正 / fix | 「`Z` の bug を root-cause investigation して fix も適用」 |
| 過去 thread 続行 | 「resume して top finding を fix」 |
| 大規模調査 | 「`A` 全体を deep root-cause analysis」 |

ref も prompt に書く。codex は単独で repo を読める。

## kawaz 手動経路: slash command

以下は kawaz が console で直接打つ専用。AI はこれらを自分で実行できない。

| slash command | 用途 |
|---|---|
| `/codex:review` / `/codex:adversarial-review` | working tree diff の defect 検出 / 設計挑戦 |
| `/codex:rescue` | AI 経路 `codex:codex-rescue` の手動版 |
| `/codex:status` / `/codex:result` / `/codex:cancel` | job 管理 |
| `/codex:setup` | 動作確認 / review gate 切替。毎セッション不要 |

AI が「ここで codex 使ってほしい」と思ったら、kawaz に `/codex:<cmd>` 入力を頼まず、
まず `codex:codex-rescue` subagent を起動する。

## review gate

`/codex:setup --enable-review-gate` で project 単位 ON。永続するので 1 回で足りる。
session 終了時に adversarial review が同期 blocking で走る。ON/OFF は kawaz の明示意図でのみ行う。

## 関連

- [[codex-plugin-install]] — plugin 導入 / 認証境界 / jj 環境注意点
- [[feedback-evaluation]] — codex 指摘への evaluation
- [[discussion-style]] — 議論段階の振る舞い
- findings/2026-06-15-codex-broker-background-result-retrieval.md — 本ルールの根拠
