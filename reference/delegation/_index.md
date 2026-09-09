# 委譲・オーケストレーション

サブエージェントに何を誰へ渡すか、どの順序で進めるか、統括としてどう立て直すか。

入口は 4 つ:

- **worker を選ぶ** → `model-effort-matrix` (表と判定分岐)。性格差の背景を知りたければ `model-characteristics`、入力量が心配なら `context-budget`
- **順序を決める** → `orchestration-phases` (Phase 0-4)
- **統括として立て直す** → `main-role-playbook` (失敗パターン・5 責務・立て直しの型)
- **codex に大入力を渡す** → `codex-bare-batch`

- [model-effort-matrix](model-effort-matrix.md) — 課題の性質から agent を選ぶ表と判定分岐、tier 分担の禁則、委譲プロンプトに必ず入れる規約。
  発火語: worker 選定, サブエージェント委譲, model と effort, subagent_type, tier 分担, 委譲プロンプト, 監査側の禁則
- [model-characteristics](model-characteristics.md) — sonnet5 / opus5 / fable / codex 系の性格差と effort の効き方。
  発火語: モデル特性, sonnet5 の手抜き, fable は遅い, codex は不具合調査に強い, effort high が要る, ベンチ数値
- [context-budget](context-budget.md) — 経路ごとの実効入力余地の表と見積り式、`[1m]` 固定と割増帯の扱い。
  発火語: context が足りない, Prompt is too long, 実効余地, 見積り, [1m], 272K 超, 割増料金
- [orchestration-phases](orchestration-phases.md) — Phase 0-4 の実行順序制御、適用ゲート、常時 rules との分担。
  発火語: Phase 0, 完了条件, 検証方法, やらないこと, リスク順分解, 実行ループ, 全体検証
- [main-role-playbook](main-role-playbook.md) — 統括の失敗パターン・5 責務・立て直しの型・codex 委譲時のルール・開始時チェックリスト。
  発火語: 統括の立て直し, worker 起草の drift, 逐条監査, 自律進行, QUESTIONS.md, セッション開始チェック
- [codex-bare-batch](codex-bare-batch.md) — `claude -p --bare` で codex に大入力を渡す定型コマンドと実測済みの罠。
  発火語: claude -p --bare, codex 大入力, CLAUDE_CODE_MAX_CONTEXT_TOKENS, ANTHROPIC_BASE_URL, disallowedTools, prompt.md
