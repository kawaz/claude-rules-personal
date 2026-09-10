# エコシステムレビュー指摘 — stable-which

外部レビュー (2026-09-09〜10) のうち本リポ向けの指摘。温度感と共通指摘は [README](README.md) / [common](common.md) を参照。

優先度: ★3 (次の作業で) / ★2 (近いうちに) / ★1 (気づいた時に)。「裁定待ち」は kawaz の判断が要るもの。各項目は「指摘 → 修正案」。

単体評価 (9/9): ライブラリ crate は依存ゼロで crates.io 公開済み、163 tests。DR-016 の durability モデル (参照パスと realpath を別々に判定する、allow-list 方式で Unknown は安全側) が製品の核で、その根拠が findings `binary-path-durability-matrix` (Homebrew / nix / mise / aqua / rye / claude / cursor-agent の実機調査) にある。DR-003「安定性は不安定パターンの不在で判定」→ DR-016「durable は肯定条件のみ」と、判定の向きを途中で反転させた経緯が DR に残っているのも良い。利用側 3 リポ (llm-gateway `executable.rs` / hyoui DR-0031 / cache-warden DR-0019) が「判定は stable-which に任せる」で揃っており、dogfood から生まれたライブラリとして役割が定まっている。7/9 以降更新なしだが、これは完成に近いので問題ではない。指摘は全部小さい。

### SW-1 ★1 CLI の引数パーサ

- 指摘: `stable-which-cli/src/main.rs` は 266 行の手書きパーサで、issue `2026-06-13-cli-arg-separator` (`--` 未対応) が open のまま。`--format` / `--policy` の値検証も文字列 match
- 修正案: kuu が使える段階になったら kuu.mbt でなく Rust 側の薄い引数定義に置き換える対象。それまでは `--` だけ足して issue を閉じる (10 行)

### SW-2 ★1 docs の命名・形式の揺れ

- 指摘: DR ファイル名が `DR-001` (3 桁) なのに INDEX 冒頭は「`DR-NNNN`（4 桁連番）」と書いている。issue の frontmatter が `- Status: open` 形式 (6/13 の 2 本) と YAML 形式 (6/28 の 1 本) で混在。6/13 の「docs-structure 標準への再構成」コミットで揃え切れていない
- 修正案: DR を 4 桁に改名 (16 本、リンクは INDEX と DESIGN だけ) し、issue 2 本を YAML frontmatter に。テンプレどおりに揃えるだけ

### SW-3 ★1 実装コメントの未来予告

- 指摘: `durability.rs` の doc comment に「planned for 0.5.x. See `docs/issue/` for the tracking issue」が 2 箇所。`no-historical-noise` の未来予告に当たる (issue へのリンクで足りる)
- 修正案: 「Windows-native durable surfaces are not in the allow-list (issue: windows-durable-location)」に。docs.rs に出る文なので版番号の予告は特に腐りやすい

### SW-4 ★1 既知の限界を README に

- 指摘: findings 5 で「shebang 埋め込み型の versioned 依存 (rye の script エントリポイント等) はパス文字列だけでは検出不能」が確定事実として書かれ、`durability.rs` の doc comment にも Known limitations があるが、README には無い。利用側が `durable` を「絶対に壊れない」と読むリスク
- 修正案: README の Durability 節末尾に「判定はパス文字列ベース。shebang 内のバージョン付きパスや、シム先の差し替えは検出しない」を 1 段落
