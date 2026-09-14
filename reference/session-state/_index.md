# セッション状態ファイルの索引

- [load](load.md) — セッション開始時に状態ファイルを見つけて引き継ぐ手順 (場所・cwd 照合・鮮度・loaded_by・継続作業指示のラベル別分岐) と、書く側の禁則。
  発火語: セッション開始, latest.md, 状態ファイル, claude-session-state, 継続作業指示, loaded_by, 引き継ぎ
- [write](write.md) — 状態ファイルを書く手順 (前提チェック・永続化ファースト・保存先と latest.md テンプレ・10 セクション・出どころラベル・compaction 前の力点・自己 /clear)。
  発火語: pre-clear, pre-compact, 状態を保存, clear の前, compaction の前, 引き継ぎを書く, 継続作業指示を書く
