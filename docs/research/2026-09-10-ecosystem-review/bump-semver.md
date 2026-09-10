# エコシステムレビュー指摘 — bump-semver

外部レビュー (2026-09-09〜10) のうち本リポ向けの指摘。温度感と共通指摘は [README](README.md) / [common](common.md) を参照。

優先度: ★3 (次の作業で) / ★2 (近いうちに) / ★1 (気づいた時に)。「裁定待ち」は kawaz の判断が要るもの。各項目は「指摘 → 修正案」。

単体評価 (9/9、depth 350): 350 コミット、DR 43 本、テスト関数 861、Go 約 40k 行 (`src/` 単一 `package main` 110 ファイル)。名前は bump-semver だが実体は「タスクランナーに書くと数十行のスクリプトになる定型処理を 1 行にする共通レイヤ」で、version bump / compare に加えて `vcs` サブコマンド群 (git / jj 吸収、DR-0020)、`glob:` 入力 (DR-0024)、glob-backref の言語非依存 spec (DR-0028)、翻訳ペアの commit-lag 検出 (`vcs outdated`、DR-0027) を持つ。全リポの justfile がこれを dogfood し、`push` recipe が「deps に gate を並べて `bump-semver vcs push` を 1 行叩く」形に収束している = 動機 (レシピ内は数行、依存関係で構成) はほぼ達成。DR-0034 (引数インジェクション、`vcs diff -- --output=<path>` で任意ファイル書き込みが成立していた実害を潰す) と DR-0035 (all-or-nothing + atomic write) は、内部ツールでここまで詰める例が少ない。8/1 で停止。

### B-1 (削除) 既知バグは解決済み

- v1 で「`vcs commit` が存在しないパスを黙って落とす」を挙げたが、DR-0037 (デフォルト反転) と 8/1 の `--allow-nonexistent-path` hint 修正で解決済み。取り下げ

### B-2 ★1 名前と実態の乖離 (裁定済み: (b) 改名せず README を直す)

- 指摘: 43 DR のうち version bump 本体に関するものは前半 20 本弱で、後半は `vcs` / `glob` / `outdated` / worktree / repository slug と「タスクランナーの共通レイヤ」の話。README の 1 行目「semver 文字列を取得・bump・比較するための、絞り込まれた CLI」は実態の 3 分の 1 しか説明していない。stable-which が DR-0013 で「モジュール名と実態の乖離を解消」したのと同じ状況がツール名で起きている
- 修正案 (裁定待ち): (a) 改名する (候補は crates.io / npm / PyPI / GitHub / homebrew formula 名の衝突確認とセットで別途)。全リポの justfile と tap に焼き込まれているので、旧名を alias バイナリとして残す。(b) 改名せず README の 1 行目を「タスクランナーの定型処理 (version / vcs / glob / 翻訳ペア) を 1 行にする CLI」に書き換え、名前は歴史として受け入れる。動機が「苛つきを全部閉じ込める」なら (b) で名前より説明を直すのが安い

### B-3 ★2 justfile の canonical が 3 箇所に分かれている

- 指摘: 「bump-semver の justfile が canonical」と書いている場所が (1) bump-semver の `docs/runbooks/justfile-pattern-audit.md`、(2) rules-personal の `reference/justfile/recipes.md`、(3) 各リポの justfile 冒頭コメント、の 3 つ。(1) は「`docs-structure` rule で定められている」と書くが、その rule は今日 `reference/docs-authoring/` と `reference/justfile/` に移設済みで dead reference。(1) の手順 (`ls -lt` で mtime 順に読む、diff、発見種別ごとの対応表) は他リポの justfile を監査する手順なので、bump-semver の runbook というより rules-personal の fleet-audit runbook の一部
- 修正案: 実体 (bump-semver の justfile) と記述 (`reference/justfile/recipes.md`) の 2 層に整理し、(1) は `docs/runbooks/fleet-audit.md` (rules-personal) の justfile 節へ移す。bump-semver 側には「canonical justfile はこのリポの `justfile`。監査手順は rules-personal の fleet-audit」の 1 行だけ残す

### B-4 ★1 他リポの運用に直結する open issue 2 本

- 指摘: `2026-07-28 check-on-default-branch-gate-false-no-hint` (gate が false の時に hint が出ない) と `2026-07-29 justfile-on-success-release-list-help-broken` (`just --list` の説明が崩れる、llm-gateway のフラグで追記あり) は、全リポの `push` / `watch` recipe に影響する。8/1 から止まっている
- 修正案: どちらも小さいので次に bump-semver を触る時にまとめて。hint の件は rules-personal の justfile の `check-on-default-branch` が自前で `printf` の hint を持っている (= bump-semver が出さないので各リポが書いている) 実例があり、bump-semver 側で出せば各リポの `[script]` recipe が消える

### B-5 (確定: 現状維持) `src/` 単一 `package main` 110 ファイル 40k 行

- 指摘: DR-0036 で `internal/` 分割を見送り、再検討トリガを「`vcs` 系を別ツールとして切り出す需要」「ビルド / テスト時間」と定めている。40k 行・110 ファイルが 1 パッケージなのは Go としては珍しい規模で、B-2 で改名や `vcs` 分離を選ぶならトリガに当たる
- 修正案: B-2 の裁定に従属。(a) なら DR-0036 の再検討を同時に、(b) なら現状維持
