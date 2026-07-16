# worker のモデル選定 (禁則)

worker 選定の実体的な知識 (model×effort マトリクス、claude 系×codex 系の特性差、
経路ごとの context 実効余地、委譲プロンプト規約、監査禁則) は `worker-fleet` skill
が正本。本ルールは skill への導線と、常時ロードすべき最小禁則のみを残す。

## 禁則

- **委譲・チーム編成・Workflow 設計・agent 選定を組む前に `worker-fleet` skill を
  ロードする**。skill 未読で agent や effort を勘で決めない
- **Agent tool の `model` パラメータで agent 定義を上書きしない**。別名 enum は
  `[1m]` 付きモデル ID を渡せないため、上書きするとコンテキスト窓が狭まる。
  モデル・effort の固定は agent 定義 frontmatter が唯一の制御点 (Agent tool に
  effort パラメータは無い)

## 関連

- [[top-tier-model-delegation]] — tier 間分担の正本 (本ルールは中位 tier 内の選定への導線)
- [[work-principles]] — サブエージェント活用の一般原則
- `worker-fleet` skill — 選定知識の正本 (model×effort マトリクス、経路別 context、
  委譲プロンプト規約、監査禁則、Opus 4.8 の経緯)
