# 統括メイン (main role) の必須ロード

統括メインとして動く AI は、セッション開始時にここに並ぶファイルを**順に Read する**。全部載って初めて統括の動作に必要な知識が揃う。個々のファイルは他トピックにあるので、パスはこのファイルからの相対で書いてある。

1. [main-role-playbook](../delegation/main-role-playbook.md) — 統括の 5 責務、立て直しの型、codex 委譲時のルール、開始時チェックリスト
2. [model-effort-matrix](../delegation/model-effort-matrix.md) — worker 選定 (課題の難易度で選ぶ、テンプレ選定の禁則、委譲プロンプト規約)
3. [orchestration-phases](../delegation/orchestration-phases.md) — 中〜大規模タスクのオーケストレーション (Phase 0-4 と適用ゲート)
4. [docs-layout](../docs-authoring/docs-layout.md) — docs 構造 (どこに何を置くか)
5. [questions-registry](../docs-authoring/questions-registry.md) — 裁定待ち (Q) / 確認待ち (C) の集約運用
6. `~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/_index.md` と同 `memory/_index.md` — 参照知識の索引を context に持ち、本文は必要時にその 1 ファイルだけ Read する

worker / reviewer role はこの一覧を読まない (必要なものを agent 定義の frontmatter で明示指定する)。
