# skill の reference 移設仕分け (2026-09-09)

kawaz 裁定「skill にある知識系は全部 `reference/` に移す」を前提に、`skills/*/SKILL.md` 34 本を全件通読し、付属ファイルの有無と被参照を実測したうえで **「reference へ移す」/「skill に残す」の 2 値**で仕分けた結果。読み取りのみで、skill ファイルは編集していない。

**結論 3 行**:

- **reference へ移すのは 21 本** (SKILL.md 本体 137,435 bytes + `macos-signing-notarization` の分割 md 27,677 bytes)。**skill に残るのは 13 本**で、内訳は付属ファイルを持つもの 3 本、frontmatter が harness 機能を使うもの 1 本、ユーザが `/名前` で起動する投入プロンプト 5 本、hook / loader が起動点として名指しするもの 4 本。
- 移設で壊れる被参照は **rule 8 箇所・hook 2 ファイル・agent frontmatter 1 本・他 skill 14 箇所・docs/runbooks 1 箇所・overlay リポ 2 本**。最も危険なのは `hooks/vcs-skill-autoload.sh` (VCS 系 4 本を skill 名で名指し) と `agents/codex-sol-worker.md` の description (plugin reload まで古い文言が全セッションに載り続ける)。
- 移設に伴って常時 rule へ昇格すべき思想は **3 件・約 2,000 bytes** (常時ロードは実測 74,652 → 76,650、予算 81,920 に対し残余 5,270)。これ以上入れると余裕が 3% を切るため、残りは reference 側の冒頭に置いて発火語で引く。

## 判明した事実

- 常時ロードの実測は **74,652 bytes** (`for-all/rules` 68,320 + `for-me/rules` 6,332)。指示にあった 73,016 との差 1,636 は、直近の降格作業で `knowledge-guide.md` が加わった分と見られる。予算 81,920 に対する残余は 7,268。
- skill 側の総量は **245,136 bytes** (SKILL.md 本体 179,535 + 付属ファイル 65,601)。付属ファイルの内訳は `docs-structure/templates/` 16,016 (19 ファイル)、`gh-image-attach/instruction.md` 20,061、`macos-signing-notarization` の分割 md 27,677 (5 ファイル)、`questions-registry/QUESTIONS.template.md` 1,847。
- **付属ファイルを持つ skill は 4 本だが、そのうち skill に残るのは 3 本**。`macos-signing-notarization` の分割 md 5 本は「置換して配置するテンプレ」でも「サブエージェントに渡す手順書」でもなく**ただの読み物**で、`SKILL.md` が INDEX として機能する構造は `knowledge-guide` の定める `reference/<topic>/_index.md` + 分割 md と完全に同型。よってこれは reference へ移す。
- 逆に、**付属ファイルを持たないのに skill でなければ機能しないものが 3 系統ある**。(a) frontmatter が harness 機能を使うもの (`decomposition-ja` の `context: fork` / `agent: general-purpose`)、(b) `$ARGUMENTS` を受けて本文がそのまま投入プロンプトになるもの (`eli5`、`itumono-*` の「引数:」冒頭)、(c) hook / loader が起動点として名指しするもの (`load-role-main` / `pre-clear` / `pre-compact`)。「実行資源 = ファイル」で機械判定するとこの 3 系統を取りこぼす。
- skill 一覧に出ているのに `skills/` に実体が無いものが 3 本ある (`app-file-placement` / `cross-env-ssh-signing` / `jj-rebase-options-reference`)。いずれも既に reference へ移した先行分で、**plugin reload 前なので description だけが context に残っている**状態。今回の移設でも同じラグが出る。
- 既存 `reference/` は平置き 9 ファイル。今回の移設で 8 トピック・約 30 ファイルが加わるが、`reference/_index.md` に載るのはトピック索引へのエントリ 8 件だけで済む。

## 実用的な示唆 / ベストプラクティス

- **分割の単位は「索引→本文の往復が 1 回で済むか」で決まる**。`jj-tips` を「commit 操作」「組み替え」「復旧」「アンチパターン」の 4 つに割ると、実際の作業 (例: 過去コミットから生成物を消す) が 1 ファイルで完結する。一方これを「split の説明」「rebase の説明」まで割ると、1 作業で 3 ファイル開くことになって索引の往復が増える。**「1 つの作業 = 1 ファイル」を分割の粒度にする**のが実用的な線だった。
- **hook で発火する skill は、移設しても hook の文言を直せば同じ経路が使える**。`vcs-skill-autoload.sh` は `additionalContext` で「Skill tool で invoke してください」と書いているだけなので、「`reference/vcs/_index.md` を Read してください」に置き換えれば成立する。むしろ reference のほうが階層化できるぶん、jj を使うだけのセッションが 23KB を丸ごと背負わずに済む。
- **`load-role-main` は skill と reference の混在ローダーにできる**。6 番目の項目が既に `reference/_index.md` と `memory/_index.md` を Read する指示になっており、混在は先例がある。「skill を invoke する項目」と「reference を Read する項目」を明示的に分けた 2 節構成にすれば、起動時ロードという単位を保ったまま中身を reference へ移せる。
- **同名の rule と skill が併存しているものは、移設時に改名しないと事故る**。`sloppy-ai-patterns` は rule (常時) と skill (詳細) が同名で、reference へ移すと `reference/.../sloppy-ai-patterns` と rule が同名になり「どちらが正本か」が読めなくなる。移設先は内容を表す名前 (`event-driven-alternatives`) にする。
- **思想の昇格は「量」でなく「その場面で読みに行く発想が出るか」で決める**。テスト改変の禁則や統括の自律進行は、場面が来たときには判断が終わってしまうので常時側が正しい。一方でテスト設計の網羅観点は「テストを書く」と決めた後に開けば足りるので reference が正しい。

## 検証の詳細

### 仕分け表 (2 値)

bytes は実測。「skill に残す」は理由を 1 行で示す。

| skill | bytes | 判定 | 理由 / 移設先 |
|---|---|---|---|
| jj-tips | 23,463 | reference | `reference/vcs/` |
| docs-structure | 19,200 + templates 16,016 | **両方** | 本文は `reference/docs-authoring/` と `reference/justfile/` へ。**skill には `templates/` 19 本とその索引だけ残す** (置換して配置する実行資源) |
| worker-fleet | 15,380 | reference | `reference/delegation/` |
| pre-clear | 14,630 | **skill に残す** | `/clear` 前に明示指示で起動する単位。`hyoui input` による自己 `/clear` 注入まで本文が実行手順として動く |
| tdd-and-test-design | 12,894 | reference | `reference/testing/` (思想部は rule へ昇格、後述) |
| jj-workflow | 12,383 | reference | `reference/vcs/` |
| role-main-context | 12,056 | reference | `reference/delegation/` (§1.4 は rule へ昇格、後述) |
| design-spec-authoring | 10,438 | reference | `reference/design-spec/` (§1・§2 の一部は rule へ昇格、後述) |
| decomposition-ja | 9,595 | **skill に残す** | frontmatter の `context: fork` / `agent: general-purpose` が harness 機能。reference にすると fork 実行しなくなる |
| playwright-cli-chrome-beta-multi-profile | 8,703 | reference | `reference/agent-runtime/`。**overlay 2 リポの wikilink 修正を伴う** |
| itumono-contribute | 8,587 | **skill に残す** | 「引数: upstream リポジトリ URL」で始まるユーザ起動ワークフロー |
| itumono-nonstop | 8,158 | **skill に残す** | ユーザが離席前に `/itumono-nonstop` で起動する動作モード定義 |
| gh-image-fetch | 7,884 | reference | `reference/gh-ops/` |
| test-failure-no-tampering | 7,221 | reference | `reference/testing/` (禁則は rule へ昇格、後述) |
| jj-colocate-workflow | 6,316 | reference | `reference/vcs/` |
| orchestrate | 6,058 | reference | `reference/delegation/` |
| docs-knowledge-flow | 5,923 | reference | `reference/docs-authoring/` |
| itumono-full-loop | 5,733 | **skill に残す** | 「引数: 開始フェーズ」を受ける起動ワークフロー。他 itumono から呼ばれる |
| itumono-full-review | 5,312 | **skill に残す** | ペルソナ 5 つを並列起動する実行手順。`$ARGUMENTS` でレビュー対象を受ける |
| gh-image-attach | 5,239 + instruction 20,061 | **skill に残す** | `instruction.md` を絶対パスでサブエージェントに渡す。SKILL.md はその委譲契約 |
| codex-bare-batch | 5,135 | reference | `reference/agent-runtime/`。**agent frontmatter の description が名指し** |
| homebrew-tap-deploy-key | 4,692 | reference | `reference/gh-ops/` |
| push-watch | 3,515 | reference | `reference/justfile/` |
| pre-compact | 3,514 | **skill に残す** | compaction 前の起動単位。pre-clear を正本として参照する差分定義 |
| itumono-review-codex | 3,494 | reference (境界) | 外部 CLI の呼び方。両論を後述 |
| macos-signing-notarization | 3,335 + 分割 md 27,677 | reference | 分割 md 5 本はただの読み物。`reference/macos-signing/` として `_index` + 5 本にそのまま移る |
| release-flow | 2,876 | reference | `reference/justfile/` (禁則は rule 昇格を見送り、後述) |
| questions-registry | 2,865 + template 1,847 | **skill に残す** | `QUESTIONS.template.md` をコピーして配置する実行資源 |
| sloppy-ai-patterns | 2,791 | reference | `reference/agent-runtime/event-driven-alternatives.md` へ**改名して**移す |
| git-worktree-workflow | 2,593 | reference | `reference/vcs/` |
| itumono-review-gemini | 1,954 | reference (境界) | 同上 |
| load-role-main | 1,783 | **skill に残す** | `hooks/hooks.json` の SessionStart が名指しする起動点 |
| eli5 | 751 | **skill に残す** | `Topic: $ARGUMENTS` を受ける投入プロンプトそのもの |
| itumono-review-claude | 665 | reference (境界) | 同上 |

集計: **reference へ移すのは 21 本** (SKILL.md 137,435 + macos 分割 md 27,677 = 165,112 bytes)。**skill に残るのは 13 本** (SKILL.md 88,116 のうち docs-structure は縮小して約 1,900 になるため実質 70,816 + 付属ファイル 37,924)。

### reference の配置案

分割は「1 つの作業 = 1 ファイル」を粒度にした。各ファイルは単独で意味を成し、索引から 1 回開けば作業が完結する。

**`reference/vcs/`** — jj-tips 23,463 + jj-workflow 12,383 + jj-colocate-workflow 6,316 + git-worktree-workflow 2,593 + 既存 `jj-rebase-options.md` を吸収

| ファイル | 要旨 |
|---|---|
| `_index.md` | 構成の見分け方 (colocate 新標準 / bare+workspace 旧 / git 専用) と各本文への索引 |
| `jj-commit-basics.md` | 覚えるべき 5 コマンド、commit と split の使い分け、パス指定の禁則、describe だけで終わる事故 |
| `jj-restructure.md` | split / squash / rebase / duplicate による組み替え、過去コミットからのパス除去、隔離 workspace 経由の送り込み |
| `jj-recovery.md` | op restore、bookmark 移動と push のハマりどころ、bookmark conflict、fork の upstream 追従 |
| `jj-antipatterns.md` | `--ignore-working-copy`、複数エージェントの同一 workspace、git コマンド混用 |
| `jj-colocate-setup.md` | colocate のレイアウト・新規作成・clone・旧方式からの移行・作業場所の使い分け |
| `jj-bare-workspace-setup.md` | 旧方式のセットアップ・PR 手順・署名・トラブルシュート ("stale info" / tag が見えない) |
| `git-worktree-setup.md` | git 専用リポの worktree 構成・命名・PR 手順 |
| `jj-rebase-options.md` | 既存を移動 (リビジョン指定オプションの完全リファレンス) |

トップ索引の要旨: 「jj / git の workflow 手順とコミット操作・復旧のパターン集。リポ構成で参照先が分かれる」
発火語: `jj commit, jj split, jj rebase, jj squash, jj workspace, bookmark, colocate, worktree, PR 作成, push が拒否される, op restore, stale info, tag が jj に見えない`

**`reference/testing/`** — tdd-and-test-design の手順部 8,677 + test-failure-no-tampering の手順部 4,496

| ファイル | 要旨 |
|---|---|
| `_index.md` | 「設計する」「失敗に対処する」の 2 入口 |
| `test-coverage-checklist.md` | RED 段階の観点 (境界・エッジ・デシジョンテーブル・同値分割・状態遷移・並行性・回帰)、観点×実行場所の表、やりがちな失敗 |
| `test-as-spec-comments.md` | コメント様式、DR 参照の書き方、self-contained にする portability の根拠 |
| `flaky-accountability.md` | flaky 認定で埋める 5 項目、NG/OK 例、timeout 延長を正当化する条件、`#[ignore]` の書式 |

要旨: 「テスト設計の網羅観点と、失敗テストに手を入れる時の説明責任」
発火語: `テスト設計, 境界値, 同値分割, デシジョンテーブル, 状態遷移テスト, テストコメント, flaky, たまに失敗する, timeout を伸ばす, ignore 化`

**`reference/delegation/`** — worker-fleet 15,380 + orchestrate 6,058 + role-main-context 12,056

| ファイル | 要旨 |
|---|---|
| `_index.md` | 「worker を選ぶ」「順序を決める」「統括として立て直す」の 3 入口 |
| `model-effort-matrix.md` | 課題の性質 × agent の表、判定の第一分岐・第二分岐、`rules-personal:` prefix 規約、agent を増やさない方針 |
| `model-characteristics.md` | sonnet5 / opus5 / fable / codex 系の特性差、effort の効き方、ベンチ数値の扱い |
| `context-budget.md` | 経路ごとの実効入力余地の表、見積り式、`[1m]` 固定の方針、割増帯のコスト序列 |
| `delegation-protocol.md` | 委譲プロンプトに必ず入れる規約、監査側の禁則 (メッセージ交錯の確認、潜在 writer) |
| `orchestration-phases.md` | Phase 0-4、適用ゲート、常時 rules との分担 |
| `main-role-playbook.md` | 統括の 5 責務、失敗パターンの実測、立て直しの型、codex 委譲時のルール、開始時チェックリスト |

要旨: 「サブエージェント選定・委譲規約・タスクの実行順序制御・統括の型」
発火語: `worker 選定, サブエージェント委譲, model と effort, context が足りない, Prompt is too long, Phase 0, 完了条件, 統括の立て直し, worker 起草の drift`

**`reference/docs-authoring/`** — docs-structure の構造定義部 11,541 + docs-knowledge-flow 5,923 (`templates/` は skill 側に残る)

| ファイル | 要旨 |
|---|---|
| `_index.md` | 「どこに置くか」「いつ書くか」の 2 入口 + テンプレ本体は `docs-structure` skill にある旨 |
| `docs-layout.md` | 命名規則、ディレクトリ構造、decisions / issue / journal / findings の運用、既存リポの移行 |
| `translation-pairs.md` | 日本語原本 + 英訳ペアの必須対象、push 時ガード、相互リンクの書式 |
| `knowledge-timing.md` | issue 解決時の記録先の表、DR / runbook / findings / journal を立てるタイミング、並列作業時の journal 習慣 |

要旨: 「kawaz リポの docs/ 構造標準と、何をどこに書き残すかの判断」
発火語: `docs 構造, DR を立てる, findings, journal, runbook, issue 起票, 翻訳ペア, README-ja, DESIGN-ja`

**`reference/justfile/`** — docs-structure の task runner 節 5,427 + release-flow 2,876 + push-watch 3,515

| ファイル | 要旨 |
|---|---|
| `_index.md` | 「recipe を書く」「リリースを通す」「push 後を監視する」の 3 入口 |
| `recipes.md` | 標準 recipe の並び、push 順序と mutating lint、just 変数を使わない理由、version bump gate、worktree からの push gate |
| `release-pipeline.md` | 禁則 (tag / release を手で作らない)、VERSION bump → push → workflow の標準ループ、標準型から外れたリポの直し方 |
| `push-watch.md` | `cmux-msg notify --self` からの Monitor 起動、backend 別の SHA 取得、hint echo の残存リポ、起動しない時の切り分け |

要旨: 「justfile の recipe 設計、リリース自動化、push 後の workflow 監視」
発火語: `justfile, just push, just watch, recipe, check-version-bumped, release.yml, リリースが出ない, tag が作られない, Monitor で watch`

**`reference/design-spec/`** — design-spec-authoring 10,438 のうち rule 昇格分を除いた 5,178

| ファイル | 要旨 |
|---|---|
| `_index.md` | 「着手前に固める」「仕上げに確認する」の 2 入口 |
| `spec-preflight.md` | スコープの粒度、前提条件と不成立時の併記、曖昧な数値の禁止、やらないことの書き方、不採用表、やらないことを守るテスト |
| `spec-finishing.md` | 通読、目的確定前の記述の疑い、相互参照の機械検証、廃止言及の削除、章立てと分量、削って良くなるかの試し |

要旨: 「設計文書 (DR / 仕様 / プロトコル) を書く・直す・レビューする時の確認項目」
発火語: `DR を書く, 仕様書, プロトコル設計, 節番号の参照, 不採用表, 設計文書のレビュー, 設計文書の通読`

**`reference/gh-ops/`** — gh-image-fetch 7,884 + homebrew-tap-deploy-key 4,692

| ファイル | 要旨 |
|---|---|
| `_index.md` | 2 本への索引 |
| `gh-image-fetch.md` | `body_html` 経由の JWT URL、README の camo、raw への手組み、TTL 5 分の注意、よくある勘違い |
| `homebrew-tap-deploy-key.md` | FROM リポごとの使い捨て鍵、生成 → secret 登録 → tap 登録、dotfiles の brews 登録忘れの徴候 |

要旨: 「GitHub まわりの運用 (画像取得、tap への自動 push 用 deploy key)」
発火語: `GitHub の画像を取得, user-attachments, camo, raw.githubusercontent, HOMEBREW_TAP_DEPLOY_KEY, Permission to homebrew-tap denied`

**`reference/agent-runtime/`** — sloppy-ai-patterns 2,791 + codex-bare-batch 5,135 + playwright-cli 8,703

| ファイル | 要旨 |
|---|---|
| `_index.md` | 3 本への索引 |
| `event-driven-alternatives.md` | sleep / polling の代替 primitive 表 (言語・環境別)、event-driven に倒す理由、正当な例外 4 種 |
| `codex-bare-batch.md` | `claude -p --bare` の定型コマンド、実測済みの罠 5 点、prompt.md の型、token 実測 |
| `playwright-chrome-profiles.md` | Chrome Beta マルチプロファイルの attach、token の扱い、タブグループによる可視範囲、トラブルシュート |

要旨: 「エージェント実行環境の運用 (待ち方の代替、codex への大入力、ブラウザ自動化)」
発火語: `sleep で待つ, polling, event-driven, Monitor tool, claude -p --bare, codex に大入力, playwright-cli, PLAYWRIGHT_MCP_EXTENSION_TOKEN, Chrome プロファイル`

**`reference/macos-signing/`** — SKILL.md 3,335 + 分割 md 27,677 を構造ごと移す

| ファイル | 要旨 |
|---|---|
| `_index.md` | 現 SKILL.md の内容 (AI がどこまでやるか、5 本への案内) をそのまま索引に |
| `setup-certificates.md` / `ci-release-pipeline.md` / `tcc-app-bundle.md` / `troubleshooting.md` / `system-extension.md` | 現状のまま移動 |

要旨: 「macOS 配布物の codesign + notarize (証明書投入・CI ステップ・TCC・障害対応)」
発火語: `codesign, notarize, notarytool, stapler, Gatekeeper, Developer ID, App-Specific Password, TCC, System Extension`

### 移設で壊れる被参照 (実測)

`rg` で全件走査した結果。archive 配下の docs は履歴なので追随不要と判断し、除外して列挙する。

| 移設対象 | 被参照箇所 | 種別 | 必要な追随 |
|---|---|---|---|
| jj-tips | `hooks/vcs-skill-autoload.sh` (3 分岐すべて) | hook | `skills=` の値を `reference/vcs/_index.md` の Read 指示に置換 |
| jj-tips | `for-me/rules/push-workflow.md` (「詳細は `jj-tips` skill」) | rule | パス参照に置換 |
| jj-tips | `skills/jj-workflow`、`skills/jj-colocate-workflow` | 他 skill | 両方とも reference へ移るので相対リンクで解決 |
| jj-workflow | `hooks/vcs-skill-autoload.sh`、`README.md`、`for-me/rules/git-repo-management.md` | hook / rule | hook と rule を置換。README も 1 箇所 |
| jj-workflow | `skills/git-worktree-workflow`、`skills/jj-colocate-workflow`、`skills/jj-tips`、`skills/itumono-contribute` | 他 skill | itumono-contribute は **skill に残る**ので、reference のパスを書く形になる |
| jj-colocate-workflow | `hooks/vcs-skill-autoload.sh`、`docs/issue/2026-08-21-colocate.md` (active issue) | hook / issue | hook を置換。active issue も追随 |
| git-worktree-workflow | `hooks/vcs-skill-autoload.sh`、`for-me/rules/git-repo-management.md` | hook / rule | 同上 |
| worker-fleet | `for-all/rules/work-principles.md` (「詳細は `worker-fleet` skill」) | rule | パス参照に置換 |
| worker-fleet | `skills/load-role-main` (必須ロード 2 番)、`skills/role-main-context` | 他 skill | loader を混在構成に (後述) |
| orchestrate | `for-all/rules/design-priority.md` (「orchestrate skill Phase 0 の 3 行アンカー」を名指し) | rule | 節名込みの参照なので、移設先でも「Phase 0」の見出しを保つ |
| orchestrate | `skills/load-role-main`、`skills/role-main-context`、`skills/pre-clear` (継続作業指示の粒度基準) | 他 skill | pre-clear は **skill に残る**ので reference のパスを書く |
| role-main-context | `for-me/rules/role-based-skill-loading.md` | rule | パス参照に置換 |
| role-main-context | `skills/questions-registry` (§2.2 / §1.4 を節番号で名指し)、`skills/load-role-main`、`skills/design-spec-authoring` (§2.4 を正本として名指し) | 他 skill | **questions-registry は skill に残る**ので、節番号込みの参照を文言に書き直す |
| tdd-and-test-design | `for-all/rules/rule-writing-guidelines.md` (「該当なしを明示する勇気」を出典として名指し) | rule | 移設先で同じ見出しを保つか、rule 側の文言を直す |
| tdd-and-test-design | `skills/orchestrate` (境界観点の正本として名指し) | 他 skill | 両方 reference へ移るので相対リンク |
| test-failure-no-tampering | `for-all/rules/sloppy-ai-patterns.md`、`for-all/rules/empirical-verification.md` | rule | 2 箇所とも置換 |
| test-failure-no-tampering | `skills/orchestrate`、`skills/tdd-and-test-design` | 他 skill | 相対リンク |
| sloppy-ai-patterns (skill) | `for-all/rules/sloppy-ai-patterns.md`、`for-all/rules/_index.md` | rule | **rule と同名なので `event-driven-alternatives` に改名**して参照を書き換える |
| codex-bare-batch | **`agents/codex-sol-worker.md` の `description` 本文** | agent frontmatter | description は全セッションの context に載る。文言を reference のパスに変え、**plugin reload が必須** |
| codex-bare-batch | `skills/worker-fleet` | 他 skill | 両方 reference へ |
| release-flow | `skills/macos-signing-notarization` (SKILL.md と `ci-release-pipeline.md` の 2 箇所)、`skills/docs-structure`、**`docs/runbooks/fleet-audit.md`** | 他 skill / runbook | runbook は docs 配下で唯一の被参照。**docs-structure は skill に残る**ので reference のパスを書く |
| push-watch | `for-me/rules/push-workflow.md` | rule | パス参照に置換 |
| docs-structure の本文 | `reference/app-file-placement.md`、`skills/docs-knowledge-flow`、`skills/load-role-main` (必須ロード 4 番) | reference / 他 skill | skill 側にテンプレ索引が残るので、skill → reference の順参照を 1 本追加。loader も混在構成へ |
| docs-knowledge-flow | `skills/docs-structure` (skill に残る)、`skills/pre-clear` (skill に残る、§1.5 の分類先として名指し) | 他 skill | 残る側 2 本から reference のパスを書く |
| gh-image-fetch | `skills/gh-image-attach` (skill に残る) | 他 skill | 残る側から reference のパスを書く |
| homebrew-tap-deploy-key | `skills/macos-signing-notarization` (SKILL.md と `setup-certificates.md`) | 他 skill | 両方 reference へ移るので相対リンク |
| playwright-cli | `skills/gh-image-attach` (skill に残る、代替経路を名指し) | 他 skill | 残る側から reference のパスを書く |
| playwright-cli | **overlay 2 リポの `playwright-cli-*-profile.md` が `[[playwright-cli-chrome-beta-multi-profile]]` で wikilink** | 別リポ (private) | **リポをまたぐ唯一の追随**。overlay 側を同期して直す |
| itumono-review-codex / gemini / claude | `skills/itumono-full-review` (並列起動の対象として名指し) | 他 skill | full-review は skill に残るので、reference のパスを書く |
| macos-signing-notarization | 被参照なし | — | 追随不要 |

事故リスクの総評: **hook 経由の 4 本 (VCS 系) が最大**。hook を直し忘れると、案内された skill 名が存在せず AI が探して失敗するか、案内を無視して手順書なしで jj を打つ。次点が `agents/codex-sol-worker.md` の description で、plugin reload まで古い文言が全セッションに載り続ける。overlay 2 リポの wikilink は private リポ側の作業になるため、単独 commit に切り出して同期するのが安全。それ以外は本文参照なので、切れても「読みに行けない」で済み、誤操作には直結しない。

### `load-role-main` のロード経路を保つ案

必須ロード 5 本のうち **4 本 (`role-main-context` / `worker-fleet` / `orchestrate` / `docs-structure` の本文) が reference へ移る**。`questions-registry` だけが skill に残る。loader を「invoke する項目」と「Read する項目」の 2 節構成に書き換えれば、起動時ロードという単位は保てる。

> ## 統括メインの必須ロード一覧 (必ず全部)
>
> **1. Skill tool で invoke する**
>
> - `rules-personal:questions-registry` — 裁定待ち (Q) / 確認待ち (C) の集約運用
>
> **2. Read する (参照知識。索引ではなく本文をそのまま読む)**
>
> - `<rules リポ>/reference/delegation/main-role-playbook.md` — 統括の 5 責務・失敗パターン・立て直しの型
> - `<rules リポ>/reference/delegation/model-effort-matrix.md` — worker 選定の表と判定の分岐
> - `<rules リポ>/reference/delegation/orchestration-phases.md` — Phase 0-4
> - `<rules リポ>/reference/docs-authoring/_index.md` — docs 構造の入口 (本文は必要時に 1 ファイル)
>
> **3. 索引だけ持っておく (本文は必要時に 1 ファイルだけ Read)**
>
> - `<rules リポ>/reference/_index.md` と `<rules リポ>/memory/_index.md`

この形の利点が 2 つある。**(a) 起動時に載る量を選べる**: 現状は `docs-structure` 19,200 が丸ごと載っているが、`docs-authoring/_index.md` (約 400) だけにすれば約 18,800 を節約できる。`model-characteristics.md` / `context-budget.md` / `delegation-protocol.md` も起動時に要るとは限らないので、索引経由に落とせる。**(b) plugin reload が要らない**: reference は git 上のファイルを Read するだけなので、内容を直した瞬間に反映される。

一方の懸念は、**Read の指示は skill invoke より履行が緩い**ことで、`role-based-skill-loading` rule が既に「本ルールは AI の指示履行に依存する」と断っている弱点がそのまま残る。ここは loader 本文で「3 節すべてを実行して初めて統括の知識が揃う」と現状どおり明記して補う。

### 常時 rule へ昇格すべき思想 (別枠)

移設に伴い、reference に置くと「場面が来たときには判断が終わってしまう」種類の思想だけを昇格させる。推しは 3 件。

**(1) 新設 `for-all/rules/test-integrity.md` — 約 850 bytes**

`test-failure-no-tampering` の禁則 (2,139) と `tdd-and-test-design` の対極節 (1,298) を統合する。既存 rule に足せる先が無く、`sloppy-ai-patterns` rule に混ぜると症状カタログの性格が崩れるため新設が素直。

> # テストの改変で green を作らない
>
> テストが fail したとき、**入力の書き換え・assert の緩和・timeout 延長・cfg での暗黙 skip・テスト削除で green に戻すのは禁則**。真因を直すか、`#[ignore = "<理由 + 追跡 ref>"]` で意図を保ったまま明示 skip し、追跡 issue を起票する。green は「直った証拠」、ignore 増は「直してないことの可視化」で、両者を混同しない。
>
> 「**flaky**」「たまに失敗」「環境依存」「timing 問題」は真因調査を打ち切る逃げ道として最も濫用される。そう書きたくなった瞬間が手抜きシグナル。不安定さの軸 / 再現条件 / 真因仮説 / 即直せない理由 / 追跡 issue を全部書けないなら flaky ではなく調査未完了。埋めるべき項目と例は reference の `testing/flaky-accountability`。
>
> 書く側の対極も持つ: 既存が同じ仕様輪郭を覆っているなら追加しない、直交する軸は直交性自体を 1〜2 case で固定する、仕様が要求しない厳密 assert は緩める、該当しない観点は「該当なし: 理由」と明示する。網羅観点は reference の `testing/test-coverage-checklist`。

**(2) 既存 `for-all/rules/design-thinking.md` に節を追加 — 約 700 bytes**

`design-spec-authoring` §1.1 / §1.2 / §1.4 / §2.1 / §2.2 を圧縮する。「ワークアラウンドフィールド禁止」と同じ層の判断なので節追加が正しい。

> ## 目的と責務から書く
>
> 目的は**手段を変えても文が変わらない**形で書く (「設定ファイルを JSON で読む」でなく「設定を外部から差し替えられるようにする」)。書かれた手順の量から目的を逆算しない — 基盤が既に満たしている保証は手順に現れないので、逆算すると目的から落ちて、基盤を差し替えた瞬間に消える。**手順に現れない保証こそ目的に明記する**。
>
> **何を増やしたくないかを目的と同格に置く**。制約より強く効き、後の判断がそこから導ける。増やしたくない対象が何を指すかも定義する (定義がないと「これは該当しない」で迂回される)。
>
> 論点に気づいたら「対処すべきか」でなく **「誰の責務か」から問う**。対処できるものは全部対処すべきに見えるため、前者で入ると正しいものが積み上がって芯が見えなくなる。責務外は無視でも対処でもなく**境界の記述として残す** (「扱わない、他者の責務だから」)。着手前・仕上げの確認項目は reference の `design-spec/`。

**(3) 既存 `for-me/rules/role-based-skill-loading.md` に節を追加 — 約 450 bytes**

`role-main-context` §1.4。統括専用なので `for-me` 側が適切で、`role-main-context` が reference へ移る以上ここだけは常時に残す必要がある。

> ## 統括は自律進行する (ボール渡しで止まらない)
>
> 依頼の範囲内で可逆かつ既定方針に沿う作業は確認せず着手する。**着手順そのものを自律判断する** — 候補を並べて選ばせない。**報告と着手は同一ターン**で、「準備に取り掛かります」の宣言だけで待ちに入らない。1 単位終わったらその場で次を探す (TODO の残り / `docs/QUESTIONS.md` の裁定済み / `docs/issue/` / 派生タスク)。止まってよいのは裁定が無いと進めないもの以外に何も残っていない時だけで、その時は `say` で呼びかける。例外は不可逆・外向きの操作と、前提を取り違えると全量やり直しになる分岐。

**昇格を見送った候補と理由**

| 候補 | bytes | 見送りの理由 |
|---|---|---|
| worker-fleet の禁則 (model 未指定 / 下位 tier へのレビュー委譲) | 897 | `work-principles` と `role-based-skill-loading` に既に同趣旨があり、重複を増やす |
| worker-fleet の選定第一原則 (難易度で選ぶ) | 996 | 同上。委譲の直前に reference を開く場面なので発火語も明確 |
| orchestrate の三原則 | 439 | `empirical-verification` と `design-priority` でほぼ覆える |
| release-flow の禁則 (tag / release を手で打たない) | 758 | push task の hook が実際のガードで、rule は保険にすぎない |
| role-main-context の 5 責務 | 2,590 | 圧縮しても 800 bytes 要る一方、失敗時の効き目が (3) ほど鋭くない |

### bytes の増減

**常時ロード (予算 81,920)**

| 前提 | bytes | 残余 |
|---|---|---|
| 現状 (実測) | 74,652 | 7,268 |
| 推し 3 件を昇格 | 76,650 | 5,270 |
| 推し 3 件 + 各 rule への reference 誘導行 (10 箇所 × 約 80) | 77,450 | 4,470 |
| 見送り候補も全部入れた場合 | 81,430 | 490 |

見送り候補まで入れると残余 490 bytes で実質満杯になる。**推し 3 件 + 誘導行までが実用線**。

**skill 側**

| 区分 | 現状 | 移設後 |
|---|---|---|
| SKILL.md 本体 | 179,535 | 約 70,800 |
| 付属ファイル | 65,601 | 37,924 (`templates/` 16,016 + `instruction.md` 20,061 + `QUESTIONS.template.md` 1,847) |
| 合計 | 245,136 | 約 108,700 (−56%) |

`reference/` は 9 ファイル約 20KB から、8 トピック約 30 ファイル約 185KB になる。ただし実際に context へ載るのはトピック索引ぶん (1 トピック 300〜500 bytes) と、その時に開く本文 1 ファイルだけなので、常時コストはトップ索引の 8 エントリ分だけ増える。単独最大の効果は `jj-tips` (23,463) で、jj を使わないセッションでも `description` が常時載っている現状の是正にもなる。

### 境界例の両論

**`itumono-review-codex` / `-gemini` / `-claude` (計 6,113 bytes)** — 推しは reference。中身は外部 CLI (codex / gemini / claude) の呼び方の手順で、`codex review` のスコープフラグと `[PROMPT]` が排他といった実測知識が本体。`$ARGUMENTS` を受ける行は 1 行だけで、実質は `itumono-full-review` が並列起動するときに読む素材。反対の根拠: **3 本ともユーザが `/itumono-review-codex` で直接起動できる形になっており**、reference にすると起動経路が消える。`itumono-full-loop` / `-full-review` / `-nonstop` / `-contribute` を skill に残す判断と非対称になる。移すなら full-review 側に「外部 CLI の呼び方は reference の `external-review-cli/` を読んでから起動する」と明記して、直接起動の経路が失われることを受け入れる必要がある。

**`push-watch` (3,515 bytes)** — 推しは reference (`reference/justfile/`)。中身は完全な手順で実行資源を持たず、`for-me/rules/push-workflow.md` に既に「task 名そのまま Monitor で起動する」という行動が書かれているので、常時側だけで行動は完結している。反対の根拠: この skill が発火するのは push 直後に subscribe stream から「Monitor で `just watch` を起動して」が届いた瞬間で、**そのメッセージが skill の invoke を促す設計**になっている (旧 echo hint からの移行の動機そのもの)。reference にすると「reference を探す」一段が挟まる。

**`macos-signing-notarization` (計 31,012 bytes)** — 推しは reference。分割 md 5 本は置換して配置するテンプレでもサブエージェントに渡す手順書でもない読み物で、`_index` + 分割 md の構造は reference の階層化と同型。反対の根拠: **付属ファイルを持つ 4 本のうちこれだけ扱いが違う**のは、外から見て「付属ファイルがあれば skill」という単純な線が引けなくなる。運用ルールの単純さを優先するなら skill 維持もありうる。

**`docs-structure` の分割 (本文 17,300 を reference、templates 索引 1,900 を skill)** — 推しは分割。テンプレの索引と placeholder の説明だけが skill に残り、構造定義・言語ポリシー・justfile は reference へ行く。反対の根拠: **分割すると `templates/` を使うたびに skill と reference の両方を開くことになる**。テンプレを配置する作業は必ず「どのディレクトリに何という名前で置くか」(= 命名規則と構造の節) を必要とするので、2 つの往復が常態化する。丸ごと skill に残す (= 知識系だが実行資源と不可分と見る) 判断もありうる。

### 移設の順序 (リスク順)

1. **被参照が rule 1〜2 箇所だけの純知識から**: `gh-image-fetch` / `homebrew-tap-deploy-key` / `macos-signing-notarization` / `sloppy-ai-patterns` (改名) / `docs-knowledge-flow`。切れても行動に影響しない
2. **rule 昇格 3 件を先に land**: 常時側を固めてから対応する skill を移す (逆順だと昇格前の空白期間ができる)
3. **`testing` / `design-spec` / `justfile` トピック**: rule からの参照置換を同一 commit で
4. **VCS 系 4 本**: **hook を先に直して skill を残したまま動作確認**し、次の commit で skill を消す。同時にやると案内先が消える窓ができる
5. **`delegation` トピックと `load-role-main` の書き換え**: loader を混在構成にしてから 3 本を移す
6. **`codex-bare-batch`**: agent description の書き換えと plugin reload をセットで
7. **`playwright-cli` は最後**: overlay 2 リポ (private) の wikilink 修正を伴うため単独 commit にして同期する
