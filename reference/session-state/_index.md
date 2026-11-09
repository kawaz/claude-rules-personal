# セッションの引き継ぎの索引

- [handoff](handoff.md) — 作業を新しいセッションへ渡す既定の手順 (同じ cwd に launch して本文を send で渡すライブ引き継ぎ、本文のテンプレと継続作業指示の書式、旧が閉じる範囲の分割、受け側のラベル分岐)。
  引き継ぎ, 新しいセッションに渡す, セッションを交代, launch, send で渡す, 引き継ぎの本文, 継続作業指示, 出どころラベル, 触らないで, 自分で閉じる, 引き継ぎを受けた
- [write](write.md) — 旧が生きていられない時に状態ファイルを書く手順 (書く条件・前提チェック・保存先とテンプレ・10 セクション・compaction 前の力点)。
  pre-clear, pre-compact, 状態を保存, clear の前, compaction の前, ハーネス再起動, 状態ファイルを書く, latest.md を書く
- [load](load.md) — 状態ファイルを見つけて 1 回だけ引き継ぐ手順 (探す時・場所・cwd 照合・鮮度・loaded_by)。
  セッション開始, latest.md, 状態ファイル, claude-session-state, loaded_by, clear の後, compaction の後, 旧セッションが落ちた
