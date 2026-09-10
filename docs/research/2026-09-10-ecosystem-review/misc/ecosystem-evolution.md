# kawaz エコシステム — 設計・デザインパターンの変遷 (2025-12 → 2026-09) v4

v3 からの差分: §11 に「違和感駆動開発」(kawaz の自己説明) と、その痕跡としての DR supersede 数、「いつかやるリスト」の消化を追加。

v2 からの差分: §10 に kawaz 自身が自覚している設計パターン 4 つを、リポ上の証拠と照合して追加。§9 の「2 つ目が来た時に境界を引く」は kawaz が意識していないとのことなので「規律」から「観察」に格下げ。

v1 からの差分: kuu.mbt の `kuu-v0` ブランチ (2026-03-04〜06-29、494 commits、DR 61 本、捨てた v0) と `slice` ブランチを取得し、3 月の設計活動を年表に組み込んだ。DR 体系・ペルソナレビュー・逐語記録の発生源が 4〜5 月から **3 月の kuu-v0** に繰り上がる。MoonBit 系の前史 (markdown.mbt 2025-12-17 / sandbox-moonbit 03-04 / timespec.mbt 03-16 / grapheme.mbt 03-17) も追加。kuu の議論自体は 1 月から (git 外、セッションログ側) と kawaz から補足あり。

clone した 17 リポの git 履歴から、各パターンの初出コミット日を取って時系列に並べたもの。日付は `git log -G` / `--diff-filter=A` で機械的に取った初出で、設計セッション自体はそれより前にあることが多い (kuu は 5 月の設計セッションを 7/4 に docs へ投入している)。

## 0. リポ作成順の年表

| 初回 commit | リポ | 最終 | commits | DR | 一言 |
|---|---|---|---|---|---|
| 2025-12-28 | claude-session-analysis | 07-03 | 163 | 1 | jsonl を読む。docs 標準の移行先になった最初のリポ |
| 2025-12-31 | ssh-agent-router | 07-26 | 12 | 0 | warden 系譜の第 1 世代 |
| 2026-01-01 | authsock-filter | 06-10 | 156 | 0 | 第 2 世代。claude ブランチからの PR merge (3 件) = AI 協働の最初の形 |
| 2025-12-17 | markdown.mbt | 04-10 | 171 | 0 | MoonBit 系の最古 |
| 2026-03-04 | **kuu.mbt `kuu-v0`** | 06-29 | 494 | 61 | 3 月に 410 commits。既存 CLI パーサ調査 (mega-survey)、shimux 分析、combinator ベースのパーサを実装。**DR 4 桁、superseded 運用、5 ペルソナ並列レビュー (03-10)、raw chat log を archive DR に、research/ が全部ここで始まる**。07-04 にトップダウン再設計で捨てる |
| 2026-03-04 | kuu (spec) | 08-17 | 1369 | 140 | 空コミットで確保、実体は 07-04。「5 月の設計セッション (全要素は同型、2 層 AST)」を 07-04 に docs へ投入。議論は 1 月から (git 外) |
| 2026-03-16 / 17 | timespec.mbt / grapheme.mbt | 06 | 69 / 94 | 0 | kuu の周辺部品 (引数に時刻、サロゲートペア → DR-0049) |
| 2026-03-31 | stable-which | 07-09 | 43 | 16 | 最初の DR (04-09)、最初の lib / cli workspace、最初の「不採用」節 |
| 2026-04-02 | authsock-warden | 05-09 | 151 | 18 | 第 3 世代。daily use 到達 |
| 2026-04-10 | cache-warden | 08-16 | 392 | 37 | 第 4 世代。9 crates |
| 2026-05-09 | bump-semver | 08-01 | 459 | 43 | docs 標準 (issue / DR / README-ja) が初日から揃う最初のリポ |
| 2026-05-27 | hyoui | 08-25 | 735 | 33 | findings / journal / REVIEW-BACKLOG / CBOR が初日から |
| 2026-06-25 | claude-rules-personal | 09-09 | 421 | 0 | ルールの central。skills / agents は 07-26 |
| 2026-06-27 | die | 06-29 | 69 | 9 | 3 日で完成。テストの実験場 |
| 2026-06-29 | claude-ccmsg | 09-09 | 1539 | 33 | 最多 commit。逐語 research (07-03)、origin pinning (07-09)、QUESTIONS 👺 (07-20)、inbox (07-16) |
| 2026-07-04 | kuu.mbt `main` | 08-17 | 925 | 6 | v0 を捨てて spec の参照実装として作り直し。conformance fixture 駆動。`slice` ブランチ (07-04〜06、97 commits) は v0 の一部を spec に合わせて切り出す中間試行 |
| 2026-07-12 | canddy-app-proxy | 08-16 | 22 | 0 | eTLD+1 2 本、wss 前段 |
| 2026-07-28 | llm-gateway | 09-09 | 531 | 28 | 三境界 + provider preset、daemon / service 体系の元ネタ |
| 2026-09-08 | ccmsg | 09-09 | 139 | 1 | v2。DESIGN の定型が完成 |
| 2026-09-08 | ccmsg-protocol | 09-09 | 69 | 0 | 契約リポ |

活動の重心: 3 月は kuu-v0 (410 commits、この月の活動のほぼ全部)、4〜5 月は warden 系譜と bump-semver、5 月末〜6 月は hyoui と docs 標準の一斉適用、7 月は claude-ccmsg と kuu、8 月は llm-gateway と cache-warden、9 月は rules 再編と ccmsg v2。

## 1. 文書体系の変遷

| 時期 | 段階 | 初出 |
|---|---|---|
| 03-04 | research/ に調査文書 (既存 CLI パーサの mega-survey、shimux 分析、utf8 実験)。「不採用」節も同日 | kuu-v0 |
| 03-10 | 5 ペルソナ並列コードレビューを DR (type: review) として記録 | kuu-v0 DR-0038 |
| 03-20 | `docs/records/` を `docs/decisions/` にフラット化、DR 4 桁、INDEX に superseded 表、Phase 1-3 の PoC 記録と raw chat log を archive DR に。DR 61 本 | kuu-v0 |
| 04-02 / 04-09 | 他リポで DR 単発。番号は 3 桁 (kuu-v0 の 4 桁より退行) | authsock-warden、stable-which |
| 05-09 | docs 標準の原型: issue / DR / README-ja / justfile が初日から揃う | bump-semver |
| 05-27 | findings / journal / REVIEW-BACKLOG が加わる。DR INDEX に Status 列 (✅ / 🟡 / ⬜) | hyoui |
| 05-29 | 「docs-structure 標準へ移行」を明示したコミット。既存リポへの適用が始まる | claude-session-analysis |
| 06-10〜06-18 | 既存リポへ一斉適用 (cache-warden 06-10、stable-which 06-13、csa 06-18)。README-ja と `vcs outdated` の翻訳ペア検出が同時に入る | — |
| 07-03 | research に kawaz 発言の逐語集。「DR はこれを正本として参照、パラフレーズで変質したら逐語優先」 | claude-ccmsg |
| 07-14 / 07-20 | QUESTIONS.md (裁定待ち / 確認待ち)、👺 ラベル運用 | claude-ccmsg、kuu |
| 07-16 | docs/inbox (kawaz の雑メモを AI が拾う経路) | claude-ccmsg |
| 07-28 | 初日から docs 標準 + knowledge/ + MANUAL | llm-gateway |
| 09-08 | DESIGN の定型が完成: 目的 → 増やさないもの (目的と同格、定義 + 反例) → 前提表 (満たさない場合) → 層と責務 → 責務外 (理由 + 目的への紐づけ) → 不採用表 → テスト方針 (増やさないをテストで固定) → 確定した判断 (裁定表)。「満たさない場合」列を持つ前提表はこれが初出 | ccmsg |
| 09-08 | 規範 (design-spec-authoring) で自分の DR 群を監査 (61 件、13 commit) | claude-ccmsg |
| 09-09 | rules の 3 分類 (常時 / skill / reference)、design-spec / testing / delegation を reference 化 | claude-rules-personal |

観察: 「不採用」節・DR・superseded・ペルソナレビュー・raw log の記録は全部 3 月の kuu-v0 が初出で、4 月以降の他リポはそれを薄い形 (DR 3 桁、単発) で持ち込み、5〜6 月に bump-semver / hyoui で docs 標準として再構成された。kuu-v0 は docs 体系の**原型**であり、捨てた実装と一緒に docs の形だけが生き残っている。「不採用」節は 03-04 (kuu-v0) が最古で、以後ほぼ全リポにある。「増やさない」は 05-11 (bump-semver) に出て、hyoui (05-27)、cache-warden (06-11)、claude-ccmsg (06-29) と続くが、「目的と同格の表 + 定義 + 反する変更の例 + テストで固定」の形になるのは 09-08。4 か月かけて「書く」から「検出する」へ移った。

## 2. アーキテクチャ様式の変遷

| 時期 | 様式 | リポ |
|---|---|---|
| 12〜01 | 単一 crate、`src/` 平置き | ssh-agent-router、authsock-filter |
| 04-09 | lib (依存最小、crates.io) / cli (Homebrew) の workspace 分離 | stable-which DR-001 → cache-warden DR-0002 が踏襲 |
| 04〜08 | 多 crate。汎用部品を独立 crate に切る (`macos-process-inspect` / `macos-tcc` / `cache-warden-webauthn`) | cache-warden (9 crates) |
| 05〜06 | Go 単一 `package main` 110 ファイル (分割は DR-0036 で意図的に見送り) | bump-semver |
| 07-28 | core / server / cli の 3 crate、core は provider 名を知らない (grep で検査可能な不変条件) | llm-gateway DR-0014 |
| 09-07 | protocol / daemon / webui の **リポ分離**、規約ファースト、契約に版 | claude-ccmsg DR-0032 → ccmsg + ccmsg-protocol |

観察: 境界の置き場が crate 内 → crate 間 → リポ間へ 1 段ずつ外に出ている。転機は llm-gateway で「provider が初めて複数になる」時に境界を語彙 (ingress / egress / exchange) で定めたこと、次に claude-ccmsg で「version の違う daemon 同士が同じ契約で話す」必要が出て契約をリポに出したこと。どちらも「2 つ目が来た時」に境界を引いている。

## 3. プロトコル / wire の変遷

| 時期 | 形 | リポ |
|---|---|---|
| 01〜05 | SSH agent protocol 準拠 (既存プロトコルの中で filter) | warden 系譜 |
| 05-27 | CBOR framing + cap flags。debug tooling (cbor-diag、EDN、Wireshark dissector) を選定理由にする | hyoui DR-0008 |
| 06 | JSON Lines over UDS、0600、stale 検知、二重起動拒否 | cache-warden DR-0009 |
| 07-09 | WebSocket + Origin 検証 (identity pinning) | claude-ccmsg DR-0004 |
| 07-28〜08-04 | 内部正規形 = Anthropic Messages、upstream 方言は `Wire` trait の変換表に閉じる | llm-gateway DR-0014 |
| 09-08 | JSON schema + op 属性表 + topic 属性表 + fixture。daemon は「引数はもう検証済み」の状態から始まる (M1) | ccmsg-protocol |

観察: wire 形式の選択 (CBOR / JSON Lines / WS) より、「検証と認可をどこに 1 回だけ置くか」の方が変遷として一貫している。cache-warden の control socket → llm-gateway の `Wire` 変換表 → ccmsg の属性表 dispatch と、「方言 / 認可を 1 箇所に集める」場所が明確になっていく。

## 4. 認証・認可の変遷

| 時期 | 形 | リポ |
|---|---|---|
| 01 | fingerprint / comment / 鍵種でフィルタ | authsock-filter |
| 04 | process-aware (PID + プロセスツリー遡上)、socket 層と key 層の 2 層 `allowed_processes` | authsock-warden → cache-warden DR-0012 |
| 06-16 | capability-based access gate (raw 値の読み出し API を gate)、`with_exposed<F>` の scope 限定アクセサ | cache-warden DR-0024 / DR-0028 |
| 07-09 | ブラウザ側は Origin 検証 (identity pinning)、後に「許可する origin の設定」へ緩和 (DR-0032) | claude-ccmsg DR-0004 |
| 07-10 | TouchID (LocalAuthenticationEmbeddedUI、ライブラリ採用)、リモート承認 (passkey、WebRTC / GitHub Pages rpId) の draft | cache-warden draft-DR-0031 / 0032 |
| 07-12 | eTLD+1 を 2 本に分ける (apps / sandbox)、passkey は各アプリで個別実装、forward-auth ゲート不採用、Related Origin Requests 禁止 | canddy-app-proxy |
| 09-08〜09 | 人: passkey (登録は CLI 発行 URL の jwt、token は opaque + family、単一 writer + tombstone)。instance: TLS を根にした peer 相互認証、id と endpoint の分離、probe による self 確定。op: 属性表 dispatch (M1) | ccmsg DR-0001、reference/auth-patterns |

観察: 「誰が来たか」の判定単位が、鍵 → プロセス → capability → origin → 人 (passkey) / instance (peer-auth) と広がり、9 月に reference として横断化された。一貫しているのは「前段 (VPN / forward-auth / IdP) に認証を寄せない、自分で判定する」で、canddy の「forward-auth ゲート不採用 (SPOF、SMTP 依存、全 YAML)」と ccmsg の「前段の構成が利用者ごとに違うので daemon が『誰か』を知る形が揃わない」は同じ判断を別の理由で書いている。

## 5. 常駐・運用の変遷

| 時期 | 形 | リポ |
|---|---|---|
| 05 | launchd plist 手書き、runbook で `reload vs register` を説明 | authsock-warden |
| 06 | `daemon register / unregister / status`、macOS 署名 + notarize + `.app` (FDA 誘導、`macos-tcc` crate) | cache-warden DR-0019 / DR-0020 |
| 06-13〜 | stable-which で焼き込むパスを選ぶ (3 リポで同じ判断) | stable-which DR-016 → hyoui / cache-warden / llm-gateway |
| 07-21 | graceful upgrade (self-exec) の DR、未実装 | hyoui DR-0028 |
| 07-29 | `web service register` (常駐する gateway だけ OS 登録) | hyoui DR-0031 |
| 08 | supervisor が daemon を抱える | claude-ccmsg DR-0002 |
| 09-09 | `daemon` (instance 操作、`run` / `supervise` / `add` / `list`…) と `service` (OS 登録は監督者 1 つだけ) の分離、unit = 設定ファイル、`register` の冪等化、「置いてある版 / 走っている版」の 2 面 | llm-gateway DR-0028 → reference/cli-daemon-subcommands |

観察: 「常駐するものは何か」の答えが、daemon 自体 → 監督者 1 つ、に収束した。macOS の FDA / TCC (バージョンアップごとに要求される) が「署名済み launcher を別途登録し supervise に徹する」構成を要求し、それが reference 末尾の 1 段落になっている。

## 6. テスト・レビューの変遷

| 時期 | 形 | リポ |
|---|---|---|
| 01 | claude ブランチからの PR を人が merge | authsock-filter |
| 03-10 | 5 ペルソナ並列レビュー (MoonBit イディオム / コード品質 / …) を DR に記録 | kuu-v0 DR-0038 |
| 05-27 | 8 ペルソナ + Codex + Gemini の並列レビュー (itumono)、REVIEW-BACKLOG に集約、dedup、CRITICAL / HIGH をバッチ消化 | hyoui |
| 06-14 | Codex review を DR の Status に記録 | cache-warden DR-0022 |
| 06-27〜29 | unit 67 + bash e2e 133 expect、3 OS matrix、わざと落とすリリースでゲートを実証 | die |
| 07-03 | DR INDEX の Status 列 (✅ / 🟡 / ⬜) で DR ↔ 実装の双方向整合 | hyoui |
| 07-26 | CI の ignored-tests job が恒常 red を隠していることを GitHub API 集計で発見 (issue、未解決) | hyoui |
| 08-14 | tri-review (3 系統レビュー) | cache-warden |
| 09-08 | 規範を物差しにした設計文書の監査 | claude-ccmsg |
| 09-08〜09 | 不変条件テスト M1〜M6、clock 注入、契約 fixture を実装テストが読む | ccmsg |
| 09-09 | `test-integrity` を常時 rule に昇格、flaky-accountability を reference に | claude-rules-personal |

観察: レビューは「複数の目で見る」(05 月) から「規範と照合する」(09 月) へ、テストは「振る舞いを確かめる」から「設計の不変条件を固定する」へ移った。die (06 月) だけが「テストの意味論」を先に完成させていて、それが 09-09 の rule 昇格まで 2 か月半、他のリポに遡及していない (hyoui の恒常 red)。

## 7. AI との協働の形の変遷

| 時期 | 形 | 痕跡 |
|---|---|---|
| 01 | Claude が branch を切って PR、人が merge | authsock-filter の `claude/*` branch merge |
| 03 | 1 か月 410 commits の高密度セッション。設計議論の生ログを archive DR に残す (DR-0002 「Phase 4 設計議論ログ」、DR-0003 「raw chat log」)。逐語 research (07-03) の原型 | kuu-v0 |
| 05〜06 | jj + justfile の push gate (`check-version-bumped` 等) で AI の push を機械で縛る。`bump-semver vcs` が全リポの justfile に入る (06-01〜06-18) | bump-semver、各 justfile |
| 05-27 | ペルソナレビューの並列化 (AI を複数の目にする) | hyoui |
| 06-25 | rules を central リポに集約、overlay で面 (personal / 業務) を分ける | claude-rules-personal |
| 07-03 | kawaz の発言を逐語で残し、AI のパラフレーズより優先 | claude-ccmsg research |
| 07-14〜20 | QUESTIONS.md と 👺: 裁定を待つ間に AI が別作業へ進める | claude-ccmsg、kuu |
| 07-16 | docs/inbox: 人が雑メモを置き AI が拾う | claude-ccmsg |
| 07-26 | rules に skills / agents を追加、model × effort の worker 体系 | claude-rules-personal |
| 08 | ccmsg の room で人と AI が同じ場にいる。会話規約を優劣付きに (対等にしたら崩れた) | claude-ccmsg |
| 09-08〜09 | TUI をほぼ使わず ccmsg 経由に。統括 / worker の分業を agents 10 本に固定、role loader、reference の遅延ロード | claude-rules-personal、ccmsg |

観察: 3 月の kuu-v0 で「議論の生ログを DR に残す」「複数ペルソナで見る」が既に出ていて、7 月の逐語 research と 5 月の itumono はその再発明ではなく継承。AI の位置が「PR を出す相手」→「ゲートで縛る対象」→「複数の目」→「裁定を仰ぐ部下」→「統括と worker の組織」と変わり、それに合わせて人の側の道具 (justfile gate → QUESTIONS → inbox → ccmsg webui) が増えている。7 月の逐語記録と 👺 は「AI が人の言葉を変質させる」「AI が人を待たせる」の 2 つの摩擦への対処で、同じ月に出ているのは偶然ではないと思う。

## 8. パターンの発生源と流れ

各パターンの初出リポ → 広がった先。矢印の向きが「バックポート」。

- lib / cli 分離: stable-which (04) → cache-warden → llm-gateway
- docs 標準: bump-semver (05) → csa (05-29) → 全リポ (06)
- 不採用節: stable-which (04) → 全リポ
- 増やさない: bump-semver (05) → hyoui → cache-warden → claude-ccmsg → ccmsg で「表 + テスト」に (09)
- Status 列: hyoui (05〜07) → (未展開、P-5)
- stable-which で焼き込む: stable-which (06) → hyoui / cache-warden / llm-gateway (未 reference 化、P-17)
- 逐語 research: claude-ccmsg (07-03) → kuu (07-21) → kuu.mbt (08-02) → cache-warden (07-11)
- QUESTIONS 👺: claude-ccmsg / kuu (07) → hyoui / bump-semver / cache-warden / llm-gateway → reference/docs-authoring
- eTLD+1 2 本: canddy (07-12) → claude-ccmsg DR-0030 → ccmsg / reference の RP ID 節
- daemon / service: cache-warden DR-0019 (06) → hyoui DR-0031 (07) → llm-gateway DR-0028 (09-09) → reference (09-09、逆向きに cache-warden / hyoui へ戻る予定)
- passkey: cache-warden draft (07-10) → canddy §7 (07-12) → ccmsg DR-0001 (09-08) → reference (09-09、逆向きに cache-warden へ戻る予定)
- 前提表「満たさない場合」: ccmsg (09-08) → reference/auth-patterns (09-09)。今後 DESIGN テンプレへ

観察: 2026-09-08〜09 の 2 日に、DESIGN の定型 (ccmsg)、daemon / service 体系 (llm-gateway)、rules の 3 分類と reference 化、auth-patterns の抽出が同時に起きている。これは偶然の集中ではなく、「後発で見えた形を標準にして先行へ戻す」という運用が、この 2 日で初めて仕組み (reference/) を得たということ。それ以前のバックポートは各リポの justfile や docs 標準のように「手で全リポを直す」形だった。

## 9. 変遷から見える癖 (感想)

- **(観察、本人は意識していない) 2 つ目が来た時に境界を引いているように見える。** provider が 2 つ目 (llm-gateway)、daemon の version が 2 つ (claude-ccmsg)、Claude 環境が 2 つ (ccmsg v2 の mesh)。1 つの時に抽象化しない、という規律が結果として守られている。逆に言うと 2 つ目が来るまで境界を引かないので、来た時の作り直しは大きい (webui 37k 行)。
- **ボトムアップで作り切ってから捨て、トップダウンで作り直す。** kuu-v0 (3 月、494 commits、combinator パーサ) → kuu (7 月、spec-as-core、「全要素は同型」)。claude-ccmsg (6〜9 月、1539 commits) → ccmsg (9 月、契約ファースト)。どちらも「捨てる」時に前版の docs (DR 61 本 / DR 33 本) は残し、次版の DESIGN は前版の実測 (v0 の divergence 台帳 / webui 37k 行の負債) を根拠にしている。捨てるのは実装であって知見ではない。
- **問題を 1 段ずつ一般化する。** warden 系譜 (ルーティング → フィルタ → ライフサイクル → 秘密値全般) も、messaging 系譜 (p2p → 中央 daemon + room → 契約 + mesh) も、1 世代で 2 段進めていない。各世代を daily use で置き換えてから次に行くので、前世代の README に「Successor」が書ける。
- **「やらないこと」の書き方が 4 か月で「宣言」から「検出」に変わった。** 04 月の不採用節 → 05 月の「増やさない」→ 09 月の M1〜M6 + テスト。この変化は、AI に実装させる時に「文章で禁じても止まらない」ことを繰り返し観測した結果に見える (ccmsg DESIGN §11.3 の 1 行目がそう書いている)。
- **道具は自分の痛みからしか作らない。** stable-which (4 つ目の常駐 CLI)、bump-semver (justfile のスクリプト化)、csa (jsonl が読めない)、canddy (localhost が嫌い)、warden (MaxAuthTries と業務アカウント)。どれも「世に無いから」ではなく「自分が n 回目に踏んだから」で、n が 3〜4 になった時にリポができている。
- **AI との摩擦がそのまま文書体系になっている。** 逐語 research (変質)、QUESTIONS 👺 (待ち)、inbox (雑指示)、REVIEW-BACKLOG (Prompt is too long で消えた)、Status 列 (設計済み ≠ 実装済み)。docs 標準の各要素に、それを必要にした事故が 1 つずつ対応している。
- **一番古いパターンが一番弱い。** 「不採用節」(04 月) は全リポにあるが、hyoui の恒常 red や cache-warden の draft DR 5 本のように、宣言だけで止まっている場所は最古のパターンの周辺に残っている。09 月の仕組み (reference + テストで固定) が遡及するかどうかが、次の数か月の見どころだと思う。

## 10. kawaz が自覚している設計パターン (2026-09-10 の本人の言葉) と、リポ上の証拠

本人が「行動パターンとして何度もやっている」と挙げた 4 つを、git 上のどこに現れているかで照合した。

### 10.1 形式化してから進める — 必要なパーツを個別に詰め、集め終わってから組む

| 証拠 | 内容 |
|---|---|
| kuu (07-04〜) | 仕様 + fixture 454 + corpus を core にし、実装は「fixture を pass すること」で作る。パーツ (grapheme.mbt / timespec.mbt) を先に別リポで詰めている |
| ccmsg-protocol (09-08) | 契約リポを先に作り、daemon は「引数はもう検証済み」の状態から始まる |
| bump-semver DR-0028 | glob-backref を言語非依存 spec v0.1.0 として `docs/specs/` に置いてから実装 |
| die (06-27〜29) | 仕様確定 (DR-0001) → 4 言語並行実装 → 選定、の順 |
| cache-warden (04-10) | `macos-process-inspect` / `macos-tcc` / `cache-warden-webauthn` を独立 crate に切ってから組む |

### 10.2 責務の明確化と IF 規約を先に作って徹底する — IF 以外の越境密結合は発見次第理由を詰め、根本問題なら全部壊して再設計する

| 証拠 | 内容 |
|---|---|
| llm-gateway DR-0014 (08-04) | 三境界 (ingress / egress / exchange) の語彙を先に定め、「core は provider の名前を 1 つも知らない」を grep で検査できる不変条件にした。越境が機械的に見つかる形 |
| ccmsg DESIGN §3 (09-08) | 4 層 + 永続化、「上の層は下の層を知らない」。M1〜M6 の「増やさない」を目的と同格に置き、テストで固定 |
| claude-ccmsg DR-0032 (09-07) | webui 37k 行の密結合を実測 (全状態購読 7 個、`AppState` 39 フィールド、store 外のミニ store 10 箇所、参照 0 の export 37 個) してから、リポ分離 + 契約ファーストで作り直し。「発見次第理由を詰めて、根本なら壊す」の最大の実例 |
| kuu-v0 → kuu (07-04) | combinator パーサ 494 commits を捨て、AST 設計から再出発。「v0 のまま進めても今の形には辿り着けなかった」 |
| hyoui DR-0025 (07-03) | daemon を単一 reducer + IO boundary に形式化。flaky の真因が境界の曖昧さにあったことから |

### 10.3 アクション / メッセージを先に定義する — 内部と外部でどんな通信・操作が要り、どんなデータが要るかを列挙し尽くし、全体を見て共通パターンで IF を決める

| 証拠 | 内容 |
|---|---|
| claude-ccmsg findings (09-07) | `daemon-inventory` / `protocol-inventory` / `webui-component-inventory` の 3 本を同日に書き、翌日 DR-0032 → 翌々日 ccmsg v2 DESIGN。「列挙し尽くしてから決める」の手順そのもの |
| claude-ccmsg `protocol-v2-op-table.md` | op × role × capability × 転送先の表 (163 行) を先に作り、それが ccmsg-protocol の `OP_ATTRIBUTES` / `TOPIC_ATTRIBUTES` になる |
| hyoui DR-0008 (05-27) | protocol を先に (CBOR framing + cap flags)、PtyMux の語彙を借りて将来互換の枠を確保 |
| cache-warden DR-0009 (06) | control socket protocol v1 を先に (UDS / JSON Lines / ping・status・kv.*)、以降の DR が拡張 |
| llm-gateway DR-0012 / DR-0020 | 「転送のたびに起きたこと」を events として先に定義し、`skipped` / `denials` を optional 追加のみで足す |

### 10.4 コンポーネントがメッシュにアクセスするのを切る — 全てを同じルートに、形式化した operation として投げて繋ぐ

| 証拠 | 内容 |
|---|---|
| ccmsg M1 / M2 (09-08) | 認可・capability・転送は 1 箇所の dispatch。「同じ情報の 2 経路目」を禁止。旧 daemon の実測「role 比較 95 箇所、同じ情報の 3 経路、push 抑制キャッシュ 3 実装」がメッシュアクセスの記録 |
| llm-gateway DR-0014 exchange | 1 転送の生涯を持つ型に観測フック (usage / stats / events) を全部掛ける。観測がモジュールごとに散らない |
| hyoui DR-0025 | 全 IO イベントを単一 reducer に通し、Effect layer で実 IO に戻す |
| bump-semver DR-0031 | rev 翻訳を共通基盤化し、`vcs:` 入力と `vcs` サブコマンドの全 rev 受け口で同じ `translateRev` を通す |
| cache-warden DR-0024 | core の raw 値読み出しを capability gate 1 箇所に集める |

### 10.5 照合して分かったこと

- 4 つとも 2026-09-07〜08 の claude-ccmsg → ccmsg で **同時に全部** 現れている (inventory 3 本 → op table → DR-0032 → DESIGN の M1〜M6 → 契約リポ)。本人が「自覚している」と言えるのは、この 3 日間で 4 つを意識的に順番どおり実行したからだと思う
- それ以前は 1 リポに 1〜2 つずつ現れていた (llm-gateway は 10.2 と 10.4、hyoui は 10.3 と 10.4、kuu は 10.1 と 10.2)。ccmsg v2 が「全部入り」の最初
- 10.2 の「壊して再設計」は kuu-v0 (07-04) と claude-ccmsg (09-07) の 2 回で、どちらも壊す前に実測 (divergence 台帳 / inventory) がある。「厭わない」は「根拠が数字で出たら」の条件付き
- 10.4 は、ccmsg の会話規約 (セッション間は優劣付き) とは別の層の話。op の経路を 1 本にするのは daemon 内部の設計で、セッション同士が対等か否かとは独立
- 名前を付けるなら、10.3 + 10.4 は単一 dispatch (action / reducer、CQRS の command 側) の形で、10.2 の「越境を grep で検出」は architectural fitness function。10.1 は spec-first。ただし本人はこれらの名前で考えていない (「そういうとこかな?」) ので、名前より「inventory → op table → DESIGN → 契約」という手順の方が、後発リポへの指示として再利用しやすい

## 11. 違和感駆動開発 — AI をガラポンの出汁にする (2026-09-10 の本人の言葉)

§10 の 4 パターンは「形式化してから」だが、kuu のような未知の領域では逆で、本人の説明はこう:

> ふわっとした IF (人間が渡されたらブチ切れるレベルの雑さ) を AI にぶん投げ、AI が四苦八苦して無理矢理形にしてきたのを見て、違和感を持ったところに「これは違う、こうすりゃいいんじゃね?」を返す。これを繰り返す (ガラポン) となんとなくできてくる。自分で手を動かしていたら何年経っても何もできない。「いつかやるリスト = 絶対やらないリスト」がここ 1 年で突然消化でき始めた。

### 痕跡

- **DR の supersede 数**: kuu-v0 (3 月) 61 本中 7、kuu (7〜8 月) 140 本中 17、claude-ccmsg 33 本中 19 (v2 移行の「置き換わる予定 / 契約に吸収」を含む)。hyoui 5、bump-semver 4、llm-gateway 3、cache-warden 2。kuu と ccmsg で突出しているのは、この 2 つが「ふわっとした IF から始めた」領域で、他は問題が既に見えていた (warden 系譜、bump-semver、llm-gateway) 領域
- **archive DR に raw chat log** (kuu-v0 DR-0002 / DR-0003、3 月): ガラポン 1 回分の生ログを捨てずに残している。7 月の逐語 research の原型
- **kuu-v0 → kuu の VISION 引用**: 「v0 のまま進めても今の形には辿り着けなかった」= ガラポンの結果を捨てて、違和感の側から再設計した記録
- **findings の「判明した事実」形式**: AI が形にした物に対する「違和感」を、感想でなく実測で返す形。design-principles-audit (09-08) の 61 件は「AI が書いた DR に kawaz の規範を当てて出た違和感」の一覧

### §10 との関係

§10 (形式化してから進める) と §11 (雑に投げて違和感で直す) は矛盾ではなく、対象の既知度で使い分けている:

| 領域 | 既知度 | 進め方 |
|---|---|---|
| warden 系譜、bump-semver、llm-gateway、canddy | 問題が自分の痛みとして既に見えている | §10: inventory → IF → 実装。壊すのは実測が出た時 |
| kuu、ccmsg のルーム / mesh、hyoui の TTY | 「こんな処理マシーンに流し込めば全部同じ形に落ちるのでは」という直感だけ | §11: 雑に投げ、形になった物の違和感で IF を発見し、§10 に移行する |

kuu-v0 (§11 で 3 か月) → kuu (§10 で spec-as-core) と、claude-ccmsg (§11 で 2 か月) → ccmsg (§10 で契約ファースト) は、どちらも §11 から §10 への移行がリポの切り替えとして現れている。§9 の「ボトムアップで作り切ってから捨て、トップダウンで作り直す」は、この移行の外形。

### 感想

「いつかやるリスト = 絶対やらないリスト」が消化され始めた、というのは、この 1 年のリポの密度 (2026-03 以降で 17 リポ、commits 約 6,000) を見ると数字として実在する。ただ、消化の速さの代償として、kuu (v1 未リリース)、cache-warden (draft DR 5 本)、hyoui (open 42) のように「ガラポンの途中で次の違和感に移った」状態のリポが並んでいる。それ自体は §11 の方法の性質 (違和感が出なくなったら止まる) で、止まっている = 今は違和感が無い、と読める。逆に言うと、hyoui の恒常 red や kuu の 5 プロファイルのような「違和感が出にくい種類の残作業」は、この方法では拾われにくい。そこは §10 の側 (テストで固定、green の規範) が受け持つ形になっていて、9 月にその仕組みができたのは、§11 で作った物を §10 で仕上げる手が揃った、ということだと思う。
