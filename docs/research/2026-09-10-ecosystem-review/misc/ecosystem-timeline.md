# kawaz エコシステム年表 — 2025-12-17 → 2026-09-10 (9 か月) v2

v1 からの差分: 2 月の空白を「仕事が忙しかった月 (談)」に訂正 (設計が進んでいた月という v1 の推測は外れ)。ホームスピーカーを「談」節に追加。

clone した 24 リポの git 履歴 (計 8,309 commits) と、この 2 日の会話で kawaz から聞いた来歴を合わせた年表。日付は git の初回コミット / 該当コミット日。git に無い出来事 (セッションログ側の議論、転職、使い方の変化) は「談」と印を付けた。会話に出なかった claude-* plugin 群、kazahana-*、dotfiles、業務側 (private) は含まない。

## 月別の活動量

| 月 | commits | 主なリポ | 一言 |
|---|---|---|---|
| 2025-12 | 161 | markdown.mbt 137、csa 15、ssh-agent-router 9 | MoonBit と Claude Code の両方が始まる |
| 2026-01 | 164 | authsock-filter 143 | ssh agent フィルタ。claude ブランチの PR を人が merge する協働 |
| 2026-02 | 44 | csa 32 | 仕事が忙しく個人リポは静か (談) |
| 2026-03 | 675 | kuu.mbt (v0) 410、csa 92、grapheme.mbt 65 | kuu-v0 に集中。DR / research / ペルソナレビュー / raw log が始まる |
| 2026-04 | 182 | authsock-warden 141、stable-which 24 | warden 第 3 世代が daily use に |
| 2026-05 | 547 | hyoui 286、bump-semver 235 | docs 標準の原型 (bump-semver) と findings / journal (hyoui) |
| 2026-06 | 793 | bump-semver 193、cache-warden 147、hyoui 145、kuu.mbt 84 | 既存リポへ docs 標準を一斉適用。rules central と die が生まれる |
| 2026-07 | 3,612 | kuu 1,088、claude-ccmsg 986、kuu.mbt 717、hyoui 241 | 最多。kuu 再設計と ccmsg v1 が同時に走る |
| 2026-08 | 1,357 | kuu.mbt 304、claude-ccmsg 297、kuu 280、llm-gateway 186 | llm-gateway が CLIProxyAPI を置き換える |
| 2026-09 (10 日) | 774 | claude-ccmsg 252、llm-gateway 201、ccmsg 139、rules 113 | ccmsg v2、daemon / service 体系、rules 再編が 2 日に集中 |

## 年表

### 2025-12

- 12-17 **markdown.mbt** — CST ベースの増分 Markdown パーサ。MoonBit 系の最古
- 12-28 **claude-session-analysis** — Claude Code の jsonl を読む skill。当初は idea-storage 用 (セッションログから knowledge を拾う、業務日誌を書かせる) (談)
- 12-31 **ssh-agent-router** — 1 つの agent から fingerprint 別の socket を作る。warden 系譜の第 1 世代。動機は 1Password の agent が数十本の鍵を全部出して MaxAuthTries で出禁になること (談)

### 2026-01

- 01-01 **authsock-filter** — フィルタ + ログ。1 月だけで 143 commits。`claude/*` ブランチからの PR を kawaz が merge する形で、AI との協働が始まる
- 1 月頃 kuu の設計議論がセッションログ側で始まる (談)。git 上の実体は 3 月から

### 2026-02

- 仕事が忙しかった月 (談)。csa に 32 commits のみ

### 2026-03

- 03-04 **kuu.mbt (kuu-v0)**「initial empty commit」の直後に「既存 CLI パーサ調査」「色々調査」。research/ が始まる。同日 **sandbox-moonbit**、**kuu** (空コミットで確保)
- 03-04〜03-20 kuu-v0 に 410 commits。combinator ベースの引数パーサを実装。03-10 に **5 ペルソナ並列レビュー**を DR-0038 として記録、03-20 に `docs/records/` を `docs/decisions/` にフラット化して **DR 4 桁 + superseded 表 + raw chat log の archive DR**。DR 61 本。ここが docs 体系の発生源 (談: DR や findings を始めたのは kuu)
- 03-16 **timespec.mbt**、03-17 **grapheme.mbt** — kuu の周辺部品
- 03-31 **stable-which** — 4 つ目の常駐 CLI を作る中で「焼き込むパスが upgrade で壊れる」痛みから。dotfiles 整理で nix / mise / brew / go / npm の置き場を整理していた時期と重なる (談)

### 2026-04

- 04-02 **authsock-warden** — op 統合、プロセス認証、4 状態ライフサイクル、mlock / zeroize。5 月まで 151 commits で daily use に到達
- 04-09 stable-which DR-001: lib / cli の workspace 分離、DR-003「安定性は不安定パターンの不在で判定」
- 04-10 **cache-warden** — DR-0001 (外部 volatile ソケットの安定 symlink 提供) で開始。この時点ではまだ warden の後継ではない

### 2026-05

- 05-09 **bump-semver** — 初日から issue / DR / README-ja / justfile が揃う。docs 標準の原型。動機は justfile に書くと数十行になる version bump / vcs 操作を 1 行にすること (談)
- 05-11 bump-semver に「増やさない」の語が初出
- 05-27 **hyoui** — PoC を全削除して DR-0001 / 0002 から再開。findings / journal / REVIEW-BACKLOG (8 ペルソナ + Codex + Gemini の itumono レビュー) / CBOR protocol が初日から。前身は shimux → cmux-msg → die の TTY 実験 (談)。動機は「claude の TUI からの解放」(談)
- 05-29 csa「docs-structure 標準へ移行」— 標準の名前が付いた最初のコミット
- 05-30 bump-semver DR-0020: `vcs` サブコマンド群。ローカルは jj、CI は git、その差を吸収する層が要り、リモートとの version 比較と被るので分けない (談)

### 2026-06

- 06-01〜06-18 各リポの justfile が `bump-semver vcs` を dogfood する形に収束 (hyoui 06-02、cache-warden 06-10、stable-which 06-13、csa 06-18)
- 06-10 cache-warden DR-0004: authsock-warden の後継・吸収を宣言。コアを「秘密値のセキュア KV キャッシュ」に一般化。同日 authsock-filter に unmaintained 表示
- 06-13 stable-which DR-016: durability モデル (allow-list、Unknown は安全側)。findings に Homebrew / nix / mise / aqua / rye の実機調査
- 06-14 cache-warden DR-0022 に「Codex review」の記録
- 06-16 cache-warden DR-0024: capability-based access gate
- 06-25 **claude-rules-personal** — common / personal / work-overlay の 3 層 + install.sh で開始
- 06-27〜29 **die** — 3 日で完成。4 言語並行実装 → Zig 採用、unit 67 + e2e 133、3 OS matrix、わざと落とすリリースでゲートを実証。テストの実験場 (談)
- 06-29 **claude-ccmsg** — cmux-msg (p2p) の rewrite として DR-0001 (中央 daemon + room) で開始。room 概念は、対等な複数セッション会議が発言リレー・社交辞令・エコーチャンバーで崩れた実害から (談)
- 06-29 kuu-v0 の最終コミット (test / ci)。同日 arggen 第 0 フェーズ議論 (別セッション、談)

### 2026-07

- 07-03 hyoui DR INDEX に Status 列 (✅ / 🟡 / ⬜)。csa の最終コミット (v0.14.1)
- 07-03 claude-ccmsg research に **kawaz 設計発言の逐語集** —「DR はこれを正本として参照、パラフレーズで変質したら逐語優先」
- 07-04 **kuu 再設計** — 5 月の設計セッション (「全要素は同型」、2 層 AST) を docs へ投入。kuu-v0 を捨て、kuu (spec-as-core) + kuu.mbt main (参照実装) の 2 リポ体制に。`slice` 枝で垂直スライス PoC (07-04〜06)
- 07-09 claude-ccmsg DR-0004: webui の Origin 検証 (identity pinning)
- 07-10 cache-warden draft-DR-0031 / 0032: TouchID は 1Password の `.app` をリンク解析して `LocalAuthenticationEmbeddedUI` を採用 (ライブラリ側を選んだ例、談)、リモート承認は WebRTC DataChannel + passkey。同日 claude-ccmsg issue に WebRTC transport
- 07-12 **canddy-app-proxy** — Caddy + tailscale + LE DNS-01 で、ローカルアプリを `*.kawaz.jp` (apps) と `*.tmpspace.net` (sandbox) の 2 eTLD+1 で https 公開。「localhost で満足しない」の実体 (談)
- 07-14 / 07-20 claude-ccmsg と kuu に **QUESTIONS.md** と 👺 ラベル運用
- 07-15 **kuu-cli**
- 07-16 claude-ccmsg に docs/inbox (kawaz の雑メモを AI が拾う経路)
- 07-21 hyoui DR-0028 (graceful upgrade、未実装)
- 07-26 rules-personal に skills / agents (model × effort の worker 体系)。ssh-agent-router に unmaintained 表示
- 07-28 **llm-gateway** — DR-0001「スコープとアーキテクチャ」。前身 CLIProxyAPI の偽装が実障害の原因だったことから「介入は最小限」で開始。初日から docs 標準 + knowledge/ + MANUAL
- 07-29 hyoui DR-0031: `web service register` (常駐する gateway だけ OS 登録)

### 2026-08

- 08-01 bump-semver 最終 (v0.48.2)。hyoui DR-0027 web gateway 実装完了、DR-0033 leader takeover
- 08-04 llm-gateway DR-0014: 三境界 (ingress / egress / exchange) + provider preset、「core は provider の名前を 1 つも知らない」。provider が初めて複数になる (codex ネイティブ対応) 契機
- 08-11 llm-gateway に `ResponseAdmission` (本文先頭を見てからの採用判定)
- 08-12 claude-ccmsg の commit 密度が上がる (8 月 297、9 月 252)。TUI から Claude を触る機会が激減し、ccmsg 経由が主に (談: 開発開始から 1 週間経たずに)
- 08-14 cache-warden に tri-review、draft-DR-0034 (暗号化永続 vault)。08-16 が cache-warden の最終コミット
- 08-16〜17 kuu / kuu.mbt に issue 20 本を棚卸し起票して停止 (kuu.mbt v0.3.0、conformance green、decoded=317 / 733 cases)
- 08-16 canddy-app-proxy 最終 (SSE 中断 findings)
- 08-21〜25 hyoui: attach 初回 redraw の契約、terminal link、scrollback 保持。08-25 が最終。目的 (TUI からの解放) は達成し、ccmsg の launcher の裏で動く実行基盤に (談)
- 08-27 claude-ccmsg findings: Claude Code ネイティブの SendMessage を実機確認し ccmsg との差分を記録。SendMessage 用にプロセス毎の unix socket が生えたことから、TUI でもツール通知でもない第 3 の配送ルートを発見 (談)

### 2026-09

- 09-02 llm-gateway knowledge: prompt cache と thinking の事実
- 09-03 llm-gateway findings: prompt cache 調査
- 09-07 claude-ccmsg findings 3 本 (**daemon / protocol / webui component の inventory**) を同日に書き、DR-0032「リポ分離と規約ファーストの作り直し」。webui 37k 行の密結合を実測してから決定。multi-host cluster の構想 (MBP と自宅サーバ、instance 間は対等でどこに繋いでも全部見える) が背景 (談)。mesh のピア認証とセルフ判定の手順は kawaz が先に自分でまとめてから AI と問答 (談)
- 09-08 **ccmsg** (v2) + **ccmsg-protocol** — DESIGN の定型 (目的 → 増やさないもの M1〜M6 → 前提表 → 層と責務 → 責務外 → 不採用 → テスト方針 → 確定判断) が完成。「満たさない場合」列を持つ前提表は初出。claude-ccmsg は同日 design-principles-audit (規範で自分の DR 群を監査、61 件を 13 commit)
- 09-08 llm-gateway findings「cache TTL は hit で更新される」→ DR-0027 (keepalive を合図方式から replay に置き換える、Proposed)
- 09-09 llm-gateway DR-0028: `daemon` / `service` サブコマンド体系、`register` の冪等化、「置いてある版 / 走っている版」。同日 v0.44.0〜0.44.2
- 09-09 **claude-rules-personal 大幅整理** — findings 2 本 (skill 34 本の仕分け、rule 14 件の降格候補) → 3 分類 (常時 / skill / reference) → skill 21 本を reference 8 トピックへ移設 → 思想 3 件を常時に昇格 (`test-integrity` 新設) → `vcs-guide` hook → agents 命名統一 → `auth-patterns/` 3 本 (passkey / peer-auth / self-endpoint) と `cli-daemon-subcommands` を「後発で見えた形を先行へ戻す」標準として抽出。常時ロード 128KB → 78.6KB、v0.7.0 → v0.8.10 (11 リリース)。起動時 context 130〜150k → 115k (実測、談)
- 09-09 ccmsg v2 に DESIGN §11.3 の M1〜M6 テストが全部揃う。契約 1.0.0 → 1.4.0 (passkey の family / tombstone / 登録転送)。protocol と daemon で 2 日 208 commits
- 09-09〜10 このレビュー。指摘リスト v18 (R / C / V1 / H / CW / CA / B / SW / D / S / L / K 項目、バックポート候補 P-1〜P-48)、変遷レポート v4

## 数字で見る 9 か月

- リポ 24 (この年表の範囲)、commits 8,309、うち 7 月が 3,612 (43%)
- DR 総数: kuu 140 + kuu-v0 61 + bump-semver 43 + cache-warden 37 + hyoui 33 + claude-ccmsg 33 + llm-gateway 28 + authsock-warden 18 + stable-which 16 + die 9 + kuu.mbt 6 + csa 1 + ccmsg 1 = **426**
- 世代交代が起きた系譜: warden 4 世代 (12 月 → 4 月)、messaging 3 世代 (cmux-msg → claude-ccmsg 6 月 → ccmsg 9 月)、kuu 2 世代 (v0 3 月 → spec-as-core 7 月)、TTY (shimux → cmux-msg → die → hyoui 5 月)
- 「全部捨てて作り直した」回数: 2 (kuu-v0 07-04、claude-ccmsg 09-07)。どちらも捨てる前に実測がある
- 使わなくなったもの: cmux-msg (ccmsg に)、csa (ccmsg dump に、08 月)、CLIProxyAPI (llm-gateway に、07〜08 月)、ssh-agent-router / authsock-filter / authsock-warden (cache-warden に)、TUI で Claude を触ること (08 月、談)

## 談として聞いた背景 (git に無い)

- 1 年半前に emrd へ転職し、業務用 GitHub アカウントを分けたことが warden 系譜の 2 つ目の動機 (github.com で鍵だけ違う、ControlPath の再利用で個人鍵のまま業務リポへ、git はプロトコルに認証が無いので黙ってタイムアウト)。今は ssh config の `Match exec` で IdentityAgent と ControlPath を切り替え、その 2 つの agent socket を warden が出す
- diary: csa timeline (今は ccmsg dump) の出力を丸ごと渡して、セッションの出来事を日誌でなく「何を感じたか、kawaz への気持ち (ネガティブも可)」の日記として AI に書かせるレシピが一番楽しい
- 「いつかやるリスト = 絶対やらないリスト」が、この 1 年で AI のおかげで突然消化でき始めた。未知の領域は雑な IF を AI に投げ、形になった物への違和感で設計を出す「違和感駆動」、既知の領域は inventory → IF 規約 → 実装の「形式化してから」
- ホームスピーカー (リポ未公開、ローカルで進行中): 各部屋に ReSpeaker XVF3800 + XIAO ESP32S3 を 1/4 球のコーナー棚に設置 (5 部屋)。端で wake word を拾い、以降の音声はサーバ室にストリーミングして文字起こし → 家電操作のコンテキスト付き LLM (Nature Remo / SwitchBot / BLE 照明 / 自作 API / カレンダー)。調べ物や雑談も。TTS は発話元の部屋へ。既製品ホームスピーカーが「定型パターンしか対応できない融通の効かないデバイス」になったのに対し、「ハードだけ完成品、ソフトは自作」で自由度を取る。BLE RSSI の在室検知を raw + 変化点の 2 層 (Parquet / DuckDB) で蓄積する構想も。全部屋に設置済みで日常的に dogfood 中。BLE RSSI のデバイス別時系列と実地確認により、電池切れのスマホでも最後の電波から「どの部屋のどのあたりか」が 2m 程度で分かる。ホームスピーカーの LLM に音声で聞けば答える
- ccmsg は自慢したいが、セットアップが素人には無理な段階。配布するなら hyoui は単一バイナリなので同梱、llm-gateway は optional (usage / quota / keepalive が無いだけ)、canddy は `tailscale serve` を最小構成に。さらに先の構想として webui を Cloudflare の静的サイトにし、WebRTC DataChannel + candidate 付き URL + passkey で NAT 越しに 1 クリック接続 (signaling の帰り道は Worker + KV 等、拡張ポイントに)
