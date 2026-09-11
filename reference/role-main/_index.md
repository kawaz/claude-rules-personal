# 統括メイン (main role) の必須ロード

統括メインとして動く AI は、セッション開始時にここに並ぶファイルを**順に Read する**。これはロードリスト 3 段の**段 1** (面によらず共通)。段 2 = 現在の面 (overlay) の role-main、段 3 = cwd のプロジェクトの CLAUDE.md で、辿り方は末尾の「連鎖」節に書く。個々のファイルは他トピックにあるので、パスはこのファイルからの相対で書いてある。

worker / reviewer role はこの一覧を読まない (必要なものを agent 定義の frontmatter で明示指定する)。

## 必読

1. [main-role-playbook](../delegation/main-role-playbook.md) — 統括の 5 責務、立て直しの型、codex 委譲時のルール、開始時チェックリスト
2. [model-effort-matrix](../delegation/model-effort-matrix.md) — worker 選定 (課題の難易度で選ぶ、テンプレ選定の禁則、委譲プロンプト規約)
3. [orchestration-phases](../delegation/orchestration-phases.md) — 中〜大規模タスクのオーケストレーション (Phase 0-4 と適用ゲート)
4. [docs-layout](../docs-authoring/docs-layout.md) — docs 構造 (どこに何を置くか)
5. [questions-registry](../docs-authoring/questions-registry.md) — 裁定待ち (Q) / 確認待ち (C) の集約運用
6. `~/.local/share/repos/github.com/kawaz/claude-rules-personal/main/reference/_index.md` と同 `memory/_index.md` — 参照知識の索引を context に持ち、本文は必要時にその 1 ファイルだけ Read する

## 必要時に読む

(まだ無し)

## 必読と必要時の運用

必読は「載っていないと事故る」もの、必要時は「その作業に入ってから読めば足りる」もの。この 2 節構成と昇格の運用は**全段の index に適用**する (段 2・段 3 の index も同じ規律で書く)。

必要時側に置いたドキュメントについて、kawaz から「ちゃんと読まずに作業してる?」「それってやり方違わない?」「どっかにあったよね?」「決めた気がする」のようなシグナルが出たら、その対象が必要時リストにあるかを確認する。あれば **kawaz に確認したうえで必読へ移す** (「必要時に置いていたが読まずに事故ったので必読へ上げてよいか」と聞く)。kawaz が「まだ様子見」と言えば移さない。

## 連鎖

段 1 を読み終えたら、次の 2 段を順に辿る:

1. **段 2 (面)**: 現在の面の overlay ルールリポに `reference/role-main/_index.md` があれば、それも同じ規律で読む。overlay のパスは `CLAUDE_CONFIG_DIR` に対応する overlay の rule が案内する (emrd 面なら `account-isolation` rule に `kawaz123/claude-rules-emrd/main` のパスがある)
2. **段 3 (プロジェクト)**: cwd のプロジェクトに CLAUDE.md の起動時手順があれば、それに従う
