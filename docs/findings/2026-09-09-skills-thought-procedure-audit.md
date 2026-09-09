# skill の思想 / 手順 / 実行資源の仕分け精査 (2026-09-09)

`skills/*/SKILL.md` 34 本を全件通読し、付属ファイルの有無を `find` で確認したうえで、節単位に「思想 (常時ロード rule へ昇格)」「手順・表・テンプレ文 (`reference/<topic>/` へ)」「実行資源を伴う / ロード単位として skill が適切 (skill に残す)」の 3 値で仕分けた。読み取りのみで、skill ファイルは編集していない。

**結論 3 行**:

- **分割候補は 16 本** (skill から `reference/` へ剥がせる節を持つもの)。うち **9 本は丸ごと reference へ移せる** (実行資源ゼロ、純手順)。
- **丸ごと skill に残すべきは 18 本**。内訳は付属ファイルを持つもの 4 本 (`docs-structure` / `questions-registry` / `gh-image-attach` / `macos-signing-notarization`)、frontmatter の harness 機能を使うもの 1 本 (`decomposition-ja`)、ユーザが `/名前` で起動する投入プロンプトそのもの 9 本 (`itumono-*` 7 + `eli5` + `pre-clear`)、ロード単位としての意味が本体である 4 本 (`load-role-main` / `pre-compact` / `sloppy-ai-patterns` / `push-watch`)。
- 昇格させたい思想を全部 rule に入れると **+4,500 bytes** で常時ロードが 79,150 になり予算 81,920 に対し余裕が 3% しか残らない。**推しは厳選 3 件 (+約 2,000 bytes、合計 76,650)**。残りは reference の冒頭に置いて発火語で引く。

## 判明した事実

- 常時ロードの実測は **74,652 bytes** (`for-all/rules` 68,320 + `for-me/rules` 6,332)。統括の指示にあった 73,016 とは 1,636 の差があり、直近の降格作業のあと `knowledge-guide.md` が増えた分だと見られる。予算 81,920 に対する残余は 7,268。
- skill 側の総量は **245,136 bytes**。うち `SKILL.md` 本体が 179,535、付属ファイル (テンプレ・分割 md・手順書) が 65,601。
- **付属ファイルを持つ skill は 4 本だけ**。`docs-structure` (templates/ 19 本)、`macos-signing-notarization` (分割 md 5 本)、`gh-image-attach` (`instruction.md`)、`questions-registry` (`QUESTIONS.template.md`)。残り 30 本は `SKILL.md` 単独で、kawaz の定義でいう「実行資源を伴う手順」に該当しない。
- 「実行資源ゼロなら reference」を機械適用すると 30 本が対象になるが、実際には **skill でなければ機能が失われるものが 3 系統ある**。(a) frontmatter が harness 機能を使うもの (`decomposition-ja` の `context: fork` / `agent: general-purpose`)、(b) ユーザが `/名前 引数` で起動し本文がそのまま投入プロンプトになるもの (`eli5` の `$ARGUMENTS`、`itumono-*` の「引数:」冒頭)、(c) 別 skill から連続 invoke される起動単位 (`load-role-main` が指す 5 本)。この 3 系統は「実行資源」の定義を「ファイル」に限定すると取りこぼす。
- **skill を消すと壊れる参照は 3 経路で実測できた**。`hooks/vcs-skill-autoload.sh` が `rules-personal:jj-colocate-workflow` / `jj-workflow` / `jj-tips` / `git-worktree-workflow` の 4 本を skill 名で名指しし、`hooks/hooks.json` の SessionStart が `rules-personal:load-role-main` を名指しし、`agents/codex-sol-worker.md` の description が `codex-bare-batch skill` に言及している。rule 側からの言及は `for-me/rules/push-workflow.md` (jj-tips / push-watch)、`for-me/rules/git-repo-management.md` (jj-workflow / git-worktree-workflow)、`for-all/rules/sloppy-ai-patterns.md` (sloppy-ai-patterns / test-failure-no-tampering)、`for-all/rules/empirical-verification.md` (test-failure-no-tampering)、`for-all/rules/rule-writing-guidelines.md` (tdd-and-test-design)、`for-all/rules/work-principles.md` (worker-fleet)、`for-all/rules/design-priority.md` (orchestrate) の 7 箇所。
- skill 一覧に出ているのに `skills/` に実体が無いものが 3 本ある: `rules-personal:app-file-placement` / `rules-personal:cross-env-ssh-signing` / `rules-personal:jj-rebase-options-reference`。いずれも既に `reference/` へ移した先行分で、**plugin の reload 前なので description だけが context に残っている**状態。今回の移設でも同じラグが出るので、移設後に reload が要る。
- `sloppy-ai-patterns` は既に「常時側 = rule、詳細 = skill」の分離ができている唯一の例で、今回の仕分けの完成形にあたる。ただし分離先が skill なので、reference へ移せば plugin reload なしで更新できるぶん有利になる。

## 実用的な示唆 / ベストプラクティス

- **「実行資源を伴うか」の判定は、ファイルの有無ではなく「この本文が invoke されること自体に意味があるか」で見る**。テンプレファイルは分かりやすい実行資源だが、`$ARGUMENTS` を受けて投入プロンプトになる本文や、frontmatter で fork 実行を指示する定義も同じく「読むだけでは成立しない」。逆に `jj-tips` のように「読んで真似する」だけの本文は、ファイルが 23KB あっても reference が正しい置き場になる。
- **hook で発火する skill は、移設しても hook の文言を同時に直せば成立する**。`vcs-skill-autoload.sh` は `additionalContext` で「Skill tool で invoke してください」と書いているだけなので、「`reference/vcs/_index.md` を Read してください」に変えれば同じ経路が使える。むしろ reference のほうが階層化 (`_index` → 本文 1 ファイル) できるぶん、jj を使うだけのセッションが 23KB を丸ごと背負わずに済む。
- **`load-role-main` が指す 5 本は「ロード単位」であって「skill である必然性」ではない**。loader の本文を「skill を invoke」と「reference を Read」の混在にすれば、起動時ロードの経路を保ったまま中身を reference へ移せる。実際 6 番目の項目は既に `reference/_index.md` を Read する指示になっており、混在は先例がある。
- **思想の昇格は「量」でなく「発火の有無」で決める**。テスト改変の禁則や自律進行の禁則は、その場面が来たときに「skill を読もう」と思う前に判断が終わってしまう種類なので常時側が正しい。一方でテスト設計の網羅観点 (境界・同値分割・デシジョンテーブル) は「テストを書く」と決めた後に読めば足りるので reference が正しい。同じ skill の中で両者が同居しているのが `tdd-and-test-design` と `test-failure-no-tampering`。
- **`role-main-context` §2 のような「特定プロジェクトの失敗実測」は、思想でも手順でもない第 3 のもの**。`no-historical-noise` でいう history narrative に近く、再発防止の教訓部分だけが価値を持つ。教訓を 1 行ずつに圧縮すると §1 の責務リストとほぼ重複する。skill を軽くする最大の単独機会 (3,729 bytes) だが、kawaz が「毎セッション同じ叱りをするのが面倒」と言って作らせた経緯があるため、削減提案としては両論併記にとどめた。

## 検証の詳細

### 仕分け表

判定は **思想** (常時 rule へ) / **手順** (reference へ) / **skill 維持** の 3 値。bytes は `awk` による節単位の実測 (改行含む)。

| skill | 節 | 判定 | bytes | 理由 |
|---|---|---|---|---|
| tdd-and-test-design | 核心原則 (何を保証するか / 仕様輪郭) | 思想 | 2362 | 「テストは動く仕様書」はテストを書く前から効く評価軸 |
| tdd-and-test-design | 対極 (書かない / 削る / 緩める) | 思想 | 1298 | 過剰網羅への歯止め。核心原則と対で常時に置かないと片面になる |
| tdd-and-test-design | RED 段階の観点リスト | 手順 | 2280 | 境界・同値分割・デシジョンテーブルの列挙は書く時に開く表 |
| tdd-and-test-design | テストの全体観 (チェックリスト) | 手順 | 941 | 観点×実行場所の表 |
| tdd-and-test-design | 真の仕様書 (コメント inline 化) | 手順 | 3742 | コメント様式の具体例。書く瞬間に読めばよい |
| tdd-and-test-design | サイクル / 適用範囲 / 反例 / Why | 手順 | 1714 | 説明。思想は上 2 節に凝縮できる |
| test-failure-no-tampering | 禁則パターン + 正しい対応の順序 | 思想 | 2139 | fail を目にした瞬間に効く禁則。読みに行く前に判断が終わる |
| test-failure-no-tampering | flaky と呼ぶ前の説明責任 | 思想 (要圧縮) | 3080 | 自警は思想、埋めるべき 5 項目と例は手順。3:7 で分ける |
| test-failure-no-tampering | How to apply / Why | 手順 | 1416 | 上 2 節と重複 |
| design-spec-authoring | §1.1 目的を解の形に汚染されずに書く | 思想 | 900 | 判定基準 (手段を変えても文が変わらないか) が汎用 |
| design-spec-authoring | §1.2 手順の量から目的を逆算しない | 思想 | 1100 | 受付の比喩が長いが、核は 2 行に落ちる |
| design-spec-authoring | §1.4 何を管理したくないかを明示 | 思想 | 400 | 「増やさない対象を目的と同格に置く」は判断の起点 |
| design-spec-authoring | §2.1-2.3 誰の責務か / 境界の記述 / 裁量の線引き | 思想 | 2000 | 設計中に常に効く。既存 design-thinking と地続き |
| design-spec-authoring | §1.3 / §1.5 / §2.4-2.7 | 手順 | 1970 | 着手前チェックの項目列挙 |
| design-spec-authoring | §3 仕上げに確認すること (§3.1-3.7) | 手順 | 2674 | 通読・相互参照の python スニペット等、仕上げ時のチェック表 |
| design-spec-authoring | §4 作業上の注意 | 手順 | 534 | §4.1 は role-main-context §2.4 と重複、§4.2 は VCS 外限定 |
| sloppy-ai-patterns | 代替表 / 例外 / 様式 (全体) | 手順 | 2791 | 実行資源なし。rule 側に症状と自警が既にある完成形 |
| worker-fleet | 禁則 (model 未指定 / 下位 tier へのレビュー委譲) | 思想 | 897 | 起動のたびに効く。既に work-principles と半分重複 |
| worker-fleet | 選定の第一原則 (難易度で選ぶ) | 思想 | 996 | テンプレ選定の禁則。role-main-context §1.3 と重複 |
| worker-fleet | model × effort 選択マトリクス | 手順 | 4897 | 表。選ぶ瞬間に開く |
| worker-fleet | context 配分 | 手順 | 2684 | 実測値の表 |
| worker-fleet | モデル特性差 / claude×codex 特性差 | 手順 | 2938 | 参照知識そのもの |
| worker-fleet | 委譲プロンプト規約 / 監査側の禁則 | 思想 (要圧縮) | 1207 | 「fresh な実出力を貼らせる」は毎回効く。3 行に落とせる |
| worker-fleet | 自 tier 判定と分担原則 / Why | 手順 | 1417 | work-principles 側に既に同内容がある |
| orchestrate | 三原則 | 思想 | 439 | 完了条件を先に固定する / 観測を信じる / リスク順 |
| orchestrate | Phase 0-4 + 適用ゲート + 分担 | 手順 | 5161 | 実行順序の手順書。着手時に 1 回開けば足りる |
| role-main-context | §1.4 自律進行 | 思想 | 1100 | 「ボール渡しで止まらない」は毎ターン効く統括の禁則 |
| role-main-context | §1.1-1.3 / §1.5 責務 | 思想 (要圧縮) | 2590 | 5 責務は 5 行に落ちる。現状は解説が厚い |
| role-main-context | §2 繰り返し発生する失敗パターン | 手順 (境界) | 3729 | 特定プロジェクトの実測 narrative。両論を後述 |
| role-main-context | §3 立て直しの型 / §5 codex 委譲 / §6 チェックリスト | 手順 | 2805 | 場面が来たら開く手順 |
| jj-tips | 全節 | 手順 | 23463 | 実行資源ゼロの純パターン集。単独で最大の移設対象 |
| jj-workflow | 全節 | 手順 | 12383 | セットアップ・PR・トラブルシュートのコマンド列 |
| jj-colocate-workflow | 全節 | 手順 | 6316 | 同上 (新標準の手順書) |
| git-worktree-workflow | 全節 | 手順 | 2593 | 同上 (git 専用リポ) |
| docs-structure | 命名規則 / ディレクトリ構造 / 補足 / 言語ポリシー / 移行 / 参考実装 | 手順 | 11541 | 構造定義。テンプレを使う時に開く |
| docs-structure | テンプレファイル一覧 | skill 維持 | 1695 | `templates/` 19 本への索引。実行資源と不可分 |
| docs-structure | task runner (justfile) | 手順 | 5427 | justfile の recipe 設計。docs 構造とは別トピック |
| docs-knowledge-flow | 全節 | 手順 | 5923 | 「いつ何を書くか」の判断表。書く直前に開く |
| release-flow | 禁則 (tag / gh release を手で打たない) | 思想 | 758 | 不可逆かつ外向き。押される瞬間に効く |
| release-flow | 標準ループ / 観点 / 逸脱リポ | 手順 | 1810 | 手順 |
| push-watch | 全節 | skill 維持 (境界) | 3515 | 「Monitor で just watch を起動して」の受信時に開く。後述 |
| pre-clear | 全節 | skill 維持 | 14630 | `/clear` 前の起動単位。hyoui 経由の自己実行まで含む |
| pre-compact | 全節 | skill 維持 | 3514 | 同上 (pre-clear を正本として参照する差分) |
| questions-registry | 全節 | skill 維持 | 2865 | `QUESTIONS.template.md` を持つ |
| load-role-main | 全節 | skill 維持 | 1783 | hooks.json が名指しする起動点 |
| gh-image-attach | 全節 | skill 維持 | 5239 | `instruction.md` をサブエージェントに渡す |
| macos-signing-notarization | 全節 | skill 維持 (境界) | 3335 | 分割 md 5 本の INDEX。reference の階層化と同型で移設可 |
| gh-image-fetch | 全節 | 手順 | 7884 | API 経路の表と curl 手順。実行資源なし |
| homebrew-tap-deploy-key | 全節 | 手順 | 4692 | 鍵生成コマンド列 |
| playwright-cli-chrome-beta-multi-profile | 全節 | 手順 | 8703 | セットアップ手順。overlay 側の profile 定義から参照される |
| codex-bare-batch | 全節 | 手順 | 5135 | 定型コマンドと実測値 |
| decomposition-ja | 全節 | skill 維持 | 9595 | frontmatter の `context: fork` / `agent:` が harness 機能 |
| eli5 | 全節 | skill 維持 | 751 | `$ARGUMENTS` を受ける投入プロンプト |
| itumono-* (7 本) | 全節 | skill 維持 | 33163 | 「引数:」で始まるユーザ起動ワークフロー |

### reference のトピック構成案

移設先を `reference/<topic>/_index.md` + 分割 md にまとめると、トップ索引に載るエントリは 8 件で済む。

**`reference/vcs/`** (jj-tips 23,463 + jj-workflow 12,383 + jj-colocate-workflow 6,316 + git-worktree-workflow 2,593 = 44,755、既存 `reference/jj-rebase-options.md` もここへ吸収)

| ファイル | 要旨 |
|---|---|
| `_index.md` | 構成の見分け方 (colocate / bare+workspace / git 専用) と各本文への発火語つき索引 |
| `jj-commit-basics.md` | 覚えるべき 5 コマンド、commit と split の使い分け、パス指定の禁則 |
| `jj-restructure.md` | split / squash / rebase / duplicate による組み替え、過去コミットからのパス除去、隔離 workspace 経由の送り込み |
| `jj-recovery.md` | op restore、bookmark 移動と push のハマりどころ、fork の upstream 追従 |
| `jj-antipatterns.md` | `--ignore-working-copy`、describe だけで終わる事故、複数エージェントの同一 workspace |
| `jj-colocate-setup.md` | colocate 新標準のレイアウト・新規作成・clone・移行手順・作業場所の使い分け |
| `jj-bare-workspace-setup.md` | 旧方式のセットアップ・PR 手順・トラブルシュート ("stale info" / tag が見えない) |
| `git-worktree-setup.md` | git 専用リポの worktree / PR 手順 |
| `jj-rebase-options.md` | 既存 (リビジョン指定オプションの完全リファレンス) |

トップ索引の発火語: `jj commit, jj split, jj rebase, jj workspace, bookmark, colocate, worktree, PR 作成, push が拒否される, op restore, stale info`

**`reference/testing/`** (tdd-and-test-design の手順部 8,677 + test-failure-no-tampering の手順部 4,496 = 13,173)

| ファイル | 要旨 |
|---|---|
| `_index.md` | 設計時 / 失敗時 の 2 入口 |
| `test-coverage-checklist.md` | RED 段階の観点リスト (境界・同値分割・デシジョンテーブル・状態遷移・並行性)、テストの全体観の表 |
| `test-as-spec-comments.md` | コメント様式、DR 参照の書き方、portability の根拠 |
| `flaky-accountability.md` | flaky 認定で埋める 5 項目、NG/OK 例、timeout 延長の条件 |

発火語: `テスト設計, 境界値, 同値分割, デシジョンテーブル, テストコメント, flaky, たまに失敗する, timeout を伸ばす, ignore 化`

**`reference/delegation/`** (worker-fleet の手順部 11,936 + orchestrate の手順部 5,161 + role-main-context の手順部 6,534 = 23,631)

| ファイル | 要旨 |
|---|---|
| `_index.md` | 選定 / 順序制御 / 統括の型 の 3 入口 |
| `model-effort-matrix.md` | 課題の性質 × agent の表、判定の分岐、agent 名の prefix 規約 |
| `model-characteristics.md` | sonnet5 / opus5 / fable / codex 系の特性差と effort の効き方 |
| `context-budget.md` | 経路ごとの実効入力余地、見積り式、`[1m]` の方針 |
| `orchestration-phases.md` | Phase 0-4 と適用ゲート |
| `main-role-playbook.md` | 統括の 5 責務の詳細、立て直しの型、codex 委譲時のルール、開始時チェックリスト |

発火語: `worker 選定, サブエージェント委譲, model と effort, context が足りない, Prompt is too long, Phase 0, 完了条件, 統括の立て直し`

**`reference/docs-authoring/`** (docs-structure の構造定義部 11,541 + docs-knowledge-flow 5,923 = 17,464。`templates/` は skill 側に残す)

| ファイル | 要旨 |
|---|---|
| `_index.md` | 「どこに置くか」「いつ書くか」の 2 入口。テンプレ本体は skill にある旨を明記 |
| `docs-layout.md` | 命名規則、ディレクトリ構造、各カテゴリの運用、既存リポの移行 |
| `translation-pairs.md` | 日本語原本 + 英訳ペアの運用と push 時ガード |
| `knowledge-timing.md` | issue 解決時のフロー、DR / runbook / findings / journal を立てるタイミング |

発火語: `docs 構造, DR を立てる, findings, journal, runbook, 翻訳ペア, README-ja`

**`reference/justfile/`** (docs-structure の task runner 節 5,427 + release-flow の手順部 1,810 = 7,237)

| ファイル | 要旨 |
|---|---|
| `_index.md` | recipe 設計 / リリース自動化 の 2 入口 |
| `recipes.md` | 標準 recipe の並び、push 順序と mutating lint、just 変数を使わない理由、version bump gate、worktree からの push gate |
| `release-pipeline.md` | VERSION bump → push → workflow が tag/Release を作る標準ループ、標準型から外れたリポの直し方 |

発火語: `justfile, just push, recipe, check-version-bumped, release.yml, リリースが出ない, tag が作られない`

**`reference/design-spec/`** (design-spec-authoring の手順部 5,178)

| ファイル | 要旨 |
|---|---|
| `_index.md` | 着手前 / 仕上げ の 2 入口 |
| `spec-preflight.md` | スコープの粒度、前提条件の列挙、曖昧な数値、やらないことの書き方、不採用表 |
| `spec-finishing.md` | 通読、目的確定前の記述の疑い、相互参照の機械検証、廃止言及の削除、章立てと分量、削って良くなるか |

発火語: `DR を書く, 仕様書, プロトコル設計, 節番号の参照, 不採用表, 設計文書のレビュー`

**`reference/gh-ops/`** (gh-image-fetch 7,884 + homebrew-tap-deploy-key 4,692 = 12,576)

| ファイル | 要旨 |
|---|---|
| `_index.md` | 画像取得 / deploy key の 2 入口 |
| `gh-image-fetch.md` | body_html 経由の JWT URL、README の camo、raw への手組み、TTL 5 分の注意 |
| `homebrew-tap-deploy-key.md` | 鍵生成 → secret 登録 → tap 登録、dotfiles の brews 登録忘れ |

発火語: `GitHub の画像を取得, user-attachments, camo, raw.githubusercontent, HOMEBREW_TAP_DEPLOY_KEY, Permission to homebrew-tap denied`

**`reference/agent-runtime/`** (sloppy-ai-patterns 2,791 + codex-bare-batch 5,135 + playwright-cli 8,703 = 16,629)

| ファイル | 要旨 |
|---|---|
| `_index.md` | 3 本への索引 |
| `event-driven-alternatives.md` | sleep / polling の代替 primitive 表と正当な例外 |
| `codex-bare-batch.md` | `claude -p --bare` の定型コマンド、実測済みの罠 5 点、prompt.md の型 |
| `playwright-chrome-profiles.md` | Chrome Beta マルチプロファイルの attach、タブグループ、トラブルシュート |

発火語: `sleep で待つ, polling, event-driven, claude -p --bare, codex に大入力, playwright-cli, PLAYWRIGHT_MCP_EXTENSION_TOKEN, Chrome プロファイル`

### 常時ロードへ昇格させる文案 (推し 3 件)

昇格は全部やると予算を圧迫するので、「その場面で skill / reference を読みに行く発想が出ないもの」だけに絞った。

**(1) 新設 `for-all/rules/test-integrity.md` (約 850 bytes)** — `test-failure-no-tampering` の禁則と `tdd-and-test-design` の対極を統合する。既存 rule に足せる先が無く、`sloppy-ai-patterns` rule に混ぜると症状カタログの性格が崩れるため新設が素直。

> # テストの改変で green を作らない
>
> テストが fail したとき、**入力の書き換え・assert の緩和・timeout 延長・cfg での暗黙 skip・テスト削除で green に戻すのは禁則**。真因を直すか、`#[ignore = "<理由 + 追跡 ref>"]` で意図を保ったまま明示 skip し、追跡 issue を起票する。green は「直った証拠」、ignore 増は「直してないことの可視化」で、両者を混同しない。
>
> 「**flaky**」「たまに失敗」「環境依存」「timing 問題」は真因調査を打ち切る逃げ道として最も濫用される。そう書きたくなった瞬間が手抜きシグナル。不安定さの軸 / 再現条件 / 真因仮説 / 即直せない理由 / 追跡 issue を全部書けないなら flaky ではなく調査未完了。埋めるべき項目と例は reference の `testing/flaky-accountability` を読む。
>
> テストを書く側の対極も持つ: 既存が同じ仕様輪郭を覆っているなら追加しない、直交する軸の組合せは直交性自体を 1〜2 case で固定すれば足りる、仕様が要求しない厳密 assert は緩める、該当しない観点は「該当なし: 理由」と明示する。網羅観点の一覧は reference の `testing/test-coverage-checklist`。

**(2) 既存 `for-all/rules/design-thinking.md` に節を追加 (約 700 bytes)** — `design-spec-authoring` の §1.1 / §1.2 / §1.4 / §2.1 / §2.2 を圧縮する。「ワークアラウンドフィールド禁止」と同じ層の判断なので新設せず節追加が正しい。

> ## 目的と責務から書く
>
> 目的は**手段を変えても文が変わらない**形で書く (「設定ファイルを JSON で読む」でなく「設定を外部から差し替えられるようにする」)。書かれた手順の量から目的を逆算しない — 基盤が既に満たしている保証は手順に現れないので、逆算すると目的から落ちて、基盤を差し替えた瞬間に消える。**手順に現れない保証こそ目的に明記する**。
>
> **何を増やしたくないかを目的と同格に置く**。制約より強く効き、後の判断がそこから導ける。増やしたくない対象が何を指すかも定義する (定義がないと「これは該当しない」で迂回される)。
>
> 論点に気づいたら「対処すべきか」でなく **「誰の責務か」から問う**。対処できるものは全部対処すべきに見えるため、前者で入ると正しいものが積み上がって芯が見えなくなる。責務外は無視でも対処でもなく**境界の記述として残す** (「扱わない、他者の責務だから」)。着手前・仕上げのチェック項目は reference の `design-spec/` を読む。

**(3) 既存 `for-me/rules/role-based-skill-loading.md` に節を追加 (約 450 bytes)** — `role-main-context` §1.4 の自律進行。統括専用なので `for-me` 側が適切。

> ## 統括は自律進行する (ボール渡しで止まらない)
>
> 依頼の範囲内で可逆かつ既定方針に沿う作業は確認せず着手する。**着手順そのものを自律判断する** — 候補を並べて選ばせない。**報告と着手は同一ターン**で、「準備に取り掛かります」の宣言だけで待ちに入らない。1 単位終わったらその場で次を探す (TODO の残り / `docs/QUESTIONS.md` の裁定済み / `docs/issue/` / 派生タスク)。止まってよいのは、裁定が無いと進めないもの以外に何も残っていない時だけで、その時は `say` で呼びかける。例外は不可逆・外向きの操作と、前提を取り違えると全量やり直しになる分岐。

昇格を見送った候補と理由: `worker-fleet` の禁則と第一原則 (**work-principles と `role-based-skill-loading` に既に同趣旨があり、重複を増やす**)、`orchestrate` の三原則 (`empirical-verification` と `design-priority` でほぼ覆える)、`release-flow` の禁則 (**push task の hook が実際のガードになっており、rule は保険にすぎない**)、`role-main-context` の 5 責務 (圧縮しても 5 行 × 解説で 800 bytes 必要な一方、失敗時の効き目が (3) ほど鋭くない)。

### skill を消す / 移す場合に壊れる参照 (実測)

| 移設対象 | 被参照箇所 | 必要な追随 |
|---|---|---|
| jj-tips / jj-workflow / jj-colocate-workflow / git-worktree-workflow | `hooks/vcs-skill-autoload.sh` (skills 変数の 3 分岐)、`for-me/rules/push-workflow.md`、`for-me/rules/git-repo-management.md`、相互参照 4 箇所 | hook の `skills=` を `reference/vcs/_index.md` の Read 指示に書き換え。`additionalContext` の文面も「Skill tool で invoke」→「Read」に変える |
| worker-fleet | `for-all/rules/work-principles.md`、`skills/load-role-main`、`skills/role-main-context`、`agents/*` は未参照 | load-role-main の 2 番目を reference の Read に変更。work-principles の「詳細は `worker-fleet` skill」を reference のパスに |
| orchestrate | `for-all/rules/design-priority.md` (Phase 0 の 3 行アンカーを名指し)、`skills/load-role-main`、`skills/role-main-context`、`skills/pre-clear` (継続作業指示の粒度基準) | design-priority と pre-clear は「Phase 0 の 3 行」を参照しているだけなので、参照先パスの置換で足りる |
| role-main-context | `for-me/rules/role-based-skill-loading.md`、`skills/questions-registry`、`skills/load-role-main`、`skills/design-spec-authoring` (§4.1 の正本として名指し) | design-spec-authoring 側の「= `role-main-context` §2.4」が節番号込みなので、移設時に節番号が変わるなら文言で書き直す |
| docs-structure の構造定義部 | `reference/app-file-placement.md`、`skills/docs-knowledge-flow`、`skills/load-role-main` | skill 側にはテンプレ索引だけ残るので、skill → reference の順参照を 1 本追加 |
| docs-knowledge-flow | `skills/docs-structure`、`skills/pre-clear` (§1.5 の分類先として名指し) | パス置換のみ |
| release-flow の手順部 | `skills/macos-signing-notarization` (SKILL.md と ci-release-pipeline.md の 2 箇所)、`skills/docs-structure`、`docs/runbooks/fleet-audit.md` | runbook 側も直す必要がある (docs 配下で唯一の被参照) |
| codex-bare-batch | `agents/codex-sol-worker.md` の **description 本文**、`skills/worker-fleet` | agent description は全セッションの context に載るので、文言を「reference の `agent-runtime/codex-bare-batch`」に変える。ここだけ plugin reload が必須 |
| sloppy-ai-patterns (skill) | `for-all/rules/sloppy-ai-patterns.md` (rule と同名)、`for-all/rules/_index.md` | rule 側の「詳細は `sloppy-ai-patterns` skill」を reference のパスに。**同名の rule が残るので、移設後の名前は `event-driven-alternatives` にして混同を避ける** |
| test-failure-no-tampering / tdd-and-test-design | `for-all/rules/sloppy-ai-patterns.md`、`for-all/rules/empirical-verification.md`、`for-all/rules/rule-writing-guidelines.md` (「該当なしを明示する勇気」の出典として名指し)、`skills/orchestrate`、相互参照 | rule-writing-guidelines は tdd 側の節タイトルを引用しているので、移設先でも同じ見出しを保つか文言を直す |
| gh-image-fetch / homebrew-tap-deploy-key / playwright-cli | `skills/gh-image-attach` (playwright の代替経路を名指し)、`skills/macos-signing-notarization` (homebrew-tap を名指し)、overlay 2 リポの `playwright-cli-*-profile.md` が `[[playwright-cli-chrome-beta-multi-profile]]` を wikilink | **overlay リポ (private) 2 本のリンクが切れる**。overlay は別リポなので同期して直す必要があり、移設の中で唯一リポをまたぐ追随 |

事故リスクの総評: **hook 経由の 4 本 (VCS 系) が最大**。hook を直し忘れると「skill を invoke してください」と案内された名前が存在せず、AI が探して失敗するか、案内を無視して手順書なしで jj を打つ。次点が `agents/codex-sol-worker.md` の description で、ここは plugin reload まで古い文言が全セッションに載り続ける。それ以外は wikilink / 本文参照なので、切れても「読みに行けない」で済み、誤った操作には直結しない。

### 境界例の両論

**`role-main-context` §2 の失敗パターン (3,729 bytes)** — 統括推しは reference へ移す。特定プロジェクトの実測 narrative であり、§1 の責務リストと §3 の立て直しの型を読めば再発防止としては足りる。反対の根拠: この skill は kawaz が「毎セッション同じ失敗と同じ叱りをするの面倒なので、肝に銘じて」と明示して作らせたもので、**症状の具体性こそが「肝に銘じる」の実装**になっている。抽象化した責務リストだけを常時に置いても、実際の失敗 (worker 起草 DR を監査せず land、Q をラベル貼りで並べる) は同じ形で再発しうる。移すなら §2 を丸ごと `reference/delegation/main-role-playbook.md` の先頭に置き、rule 側の (3) に「失敗の実例は reference を読む」の 1 行を足すのが折衷になる。

**`push-watch` (3,515 bytes)** — 統括推しは skill 維持。この skill が発火するのは push 直後に subscribe stream から「Monitor で `just watch` を起動して」が届いた瞬間で、**そのメッセージが skill の invoke を促す設計になっている** (旧 echo hint からの移行の動機そのもの)。reference にすると「reference を探す」という一段が挟まる。反対の根拠: 中身は完全な手順 (justfile の canonical 実装、jj での SHA の取り方) で実行資源を持たず、`for-me/rules/push-workflow.md` に既に「task 名そのまま Monitor で起動する」という行動が書かれている。つまり常時側だけで行動は完結しており、skill は根拠と応用例を持つだけなので `reference/justfile/` に同居させるのが構造的には正しい。

**`macos-signing-notarization` (SKILL.md 3,335 + 分割 md 5 本)** — 統括推しは skill 維持。分割ファイルを持つ 4 本のひとつで、SKILL.md が INDEX として機能している。反対の根拠: **分割ファイルが全部ただの md であって実行資源ではない**。`_index.md` + 分割 md というこの形は `knowledge-guide` が定める reference の階層化と完全に同型で、reference へ移せば plugin reload なしで更新できる。実行資源の定義を「テンプレのように置換して配置するファイル」に絞るなら、`docs-structure/templates/` と `questions-registry/QUESTIONS.template.md` と `gh-image-attach/instruction.md` (サブエージェントに絶対パスで渡す) の 3 本だけが真の実行資源で、これは移設対象になる。

**`itumono-*` 7 本 (33,163 bytes)** — 統括推しは skill 維持。`/itumono-nonstop` のようにユーザが名前で起動し、本文が投入プロンプトとして働く。反対の根拠: `itumono-review-claude` (665) / `itumono-review-codex` (3,494) / `itumono-review-gemini` (1,954) の 3 本は**外部 CLI の呼び方の手順書**で、`$ARGUMENTS` を受ける行が 1 行あるだけ。実質は reference で、`itumono-full-review` が「並列に起動して集約する」ときに読む素材にすぎない。この 3 本だけ `reference/external-review-cli/` へ移す案は成立する (6,113 bytes)。

**`tdd-and-test-design` の「真の仕様書」節 (3,742 bytes)** — 統括推しは reference。コメント様式の具体例が本体で、書く瞬間に開けばよい。反対の根拠: 冒頭の kawaz 引用「テストコード = 真の仕様書、ソースを捨てても再現可能」は**思想そのもの**で、これが context にあるかどうかでテストの書き方が変わる。1 文だけ (1) の rule に含める案が現実的で、その場合 (1) は +150 bytes になる。

### bytes の増減見積

**常時ロード側 (予算 81,920)**

| 前提 | 常時ロード bytes |
|---|---|
| 現状 (実測) | 74,652 |
| 推し 3 件を昇格 | 76,650 (+1,998) |
| 昇格候補を全部入れる (worker-fleet 禁則 / orchestrate 三原則 / release-flow 禁則 / 5 責務も) | 79,150 (+4,498) |
| 推し 3 件 + reference への誘導行を各 rule に追加 (12 本 × 約 80) | 77,610 |

推し 3 件を採ると残余は 5,270 bytes (予算の 6.4%)。全部入れると 2,770 (3.4%) しか残らないため、**昇格は推し 3 件に絞り、残りは reference の冒頭に思想を書いて発火語で引く**のが安全側。

**skill 側**

| 区分 | bytes |
|---|---|
| 現状の SKILL.md 合計 | 179,535 |
| reference へ移す分 (丸ごと 9 本 + 分割 7 本の手順部) | −126,600 |
| 常時 rule へ昇格する分 | −11,300 |
| skill 側に残る本文 (残す 18 本 + 分割後の残骸) | 41,635 |
| 付属ファイル (変化なし) | 65,601 |

skill 側の SKILL.md は **179,535 → 約 41,600 (−77%)**。うち最大の単独削減は `jj-tips` (23,463) で、これは jj を使わないセッションでも `description` が常時 context に載っている現状の是正にもなる。`reference/` 側は現状 9 ファイルから 8 トピック 30 ファイル程度に増えるが、索引経由で 1 ファイルずつ読む構造なので、実際に載る量はトピック索引ぶん (1 トピックあたり 300〜500 bytes) にとどまる。

### 移設の順序 (リスク順)

1. **hook を持たない純手順から**: `gh-image-fetch` / `homebrew-tap-deploy-key` / `codex-bare-batch` / `sloppy-ai-patterns` / `docs-knowledge-flow`。被参照が rule 1〜2 箇所で、切れても行動に影響しない
2. **rule 昇格 3 件**: 先に常時側を固めてから、対応する skill の手順部を移す (逆順だと昇格前の空白期間ができる)
3. **VCS 系 4 本**: hook の書き換えと同一 commit で。**hook を先に直して skill を残したまま動作確認**し、次の commit で skill を消すと空白が出ない
4. **load-role-main が指す 5 本**: loader の本文を skill invoke と reference Read の混在に書き換えるのが先
5. **overlay 参照を持つ `playwright-cli` は最後**: 別リポ (private) の wikilink 修正を伴うため、単独 commit にして overlay 側と同期する
