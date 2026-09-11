# 統括メイン (main role) の必須ロード — 段 1

統括メインとして動く AI は、セッション開始時に**必読**を順に Read してから、末尾の連鎖で段 2・段 3 へ進む。段の構成・必読 / 必要時の分け方・昇格の運用は reference の `rules-authoring/role-main-loading` が正本。パスはこのファイルからの相対で書いてある。

## 必読

1. [main-role-playbook](../delegation/main-role-playbook.md) — 統括の 5 責務、立て直しの型、codex 委譲時のルール、開始時チェックリスト
2. [model-effort-matrix](../delegation/model-effort-matrix.md) — worker 選定 (課題の難易度で選ぶ、テンプレ選定の禁則、委譲プロンプト規約)
3. [orchestration-phases](../delegation/orchestration-phases.md) — 中〜大規模タスクのオーケストレーション (Phase 0-4 と適用ゲート)
4. [docs-layout](../docs-authoring/docs-layout.md) — docs 構造 (どこに何を置くか)
5. [questions-registry](../docs-authoring/questions-registry.md) — 裁定待ち (Q) / 確認待ち (C) の集約運用
6. `~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/_index.md` と同 `memory/_index.md` — 参照知識の索引を context に持ち、本文は必要時にその 1 ファイルだけ Read する

## 必要時に読む

(まだ無し)

## 連鎖

1. **段 2 (面)**: 現在の面の overlay ルールリポに `reference/role-main/_index.md` があれば、それも同じ規律で読む。overlay のパスは `CLAUDE_CONFIG_DIR` に対応する overlay の rule が案内する (emrd 面なら `account-isolation` rule に `kawaz123/claude-rules-emrd/main` のパスがある)
2. **段 3 (プロジェクト)**: cwd のプロジェクトに CLAUDE.md の起動時手順があれば、それに従う
