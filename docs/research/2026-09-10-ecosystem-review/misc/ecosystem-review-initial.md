# kawaz エコシステム全体評価 (2026-09-09)

## 0. 対象と方法

GitHub から clone して直接読んだ: claude-rules-personal / claude-session-analysis / bump-semver / cache-warden / hyoui / claude-ccmsg / ccmsg / ccmsg-protocol / llm-gateway / stable-which / die / kuu / kuu.mbt の 13 リポ。`privacy-*` は public に無く (private と推定) 読めていない。overlay の `claude-rules-emrd` 等も同様。

「この数日のブラッシュアップ」は claude-rules-personal の 9/1 以降 50 コミット (v0.7.0 → v0.8.10) を対象にした。

## 1. 総評

個人のツールエコシステムとしては上位の完成度。特に (a) 13 リポで docs 標準 (DESIGN / DR / issue / findings / journal / QUESTIONS) が揃っていること、(b) `bump-semver` を全 justfile が dogfood するハブ構造、(c) ccmsg v2 の DESIGN が「増やさないもの M1〜M6 を目的と同格に置き、テストで固定する」ところまで実践していること、の 3 点は他人のリポで滅多に見ない。

一方で、ルールリポが掲げる規律 (no-hard-wrap / test-integrity / no-historical-noise) が、ルールリポ自身と主要プロダクトの実態に追いついていない箇所が目立つ。ルールの質は高いが「ルールが守られているか」を機械で見る層 (lint / push gate) の網が、ルールの進化速度に対して薄い。以下は優先順。

## 2. 横断的な課題

### 2.1 `no-hard-wrap` が自分のリポで効いていない (最優先)

行末が句読点でない文中改行を機械的に数えた結果:

| 場所 | hard-wrap を含むファイル |
|---|---|
| `for-all/rules` + `for-me/rules` (常時ロード) | 12 / 40 |
| `reference/` + `memory/` | 25 |
| ccmsg `docs/DESIGN-ja.md`、llm-gateway `README.md` | 全面的に hard-wrap |

`no-hard-wrap.md` は「既存ファイルは触ったついでに直す (一括 reflow はしない)」としているが、今日 skill から `reference/` へ移設した 25 ファイルは「触った」のに直っていない。方針が履行されない実例が同日に出ている。`lint-rules` にも hard-wrap 検査は無い。

提案: `lint-rules` に (h) 文中改行の warning を足す (句読点・記号で終わらない行の直後に地の文が続くケース、コード / 表 / 箇条書きは除外)。または「一括 reflow は 1 回だけ許す」と方針を変えて片付ける。今のままだと chat 応答やエージェント間メッセージにも hard-wrap の癖が学習源から伝播する。

### 2.2 メッセージング基盤が 3 世代並存している

| 世代 | リポ | 状態 |
|---|---|---|
| p2p | `claude-cmux-msg` (cmux-msg) | `for-all/plugins.json` に現役で入っている。`reference/justfile/push-watch.md` の `cmux-msg notify --self` が依存 |
| v1 中央 daemon | `claude-ccmsg` | src 約 41,700 行、README は「cmux-msg は parity まで維持」 |
| v2 契約ファースト | `ccmsg` + `ccmsg-protocol` | src 約 19,300 行 / test 約 14,000 行、9/9 に v0.2.1 |

3 つ全部が動いていて、他リポからの言及も分散している (claude-ccmsg → ccmsg 234 件、rules-personal → cmux-msg 7 件)。`docs/runbooks/repo-retirement.md` は存在するので、v2 の parity 条件と cmux-msg / v1 の退役順を issue 1 本に固定する時期。v2 の DESIGN §9 に「v1 との互換: 両受けしない」と書いてある以上、退役計画がないと 3 世代が恒久化する。

### 2.3 `test-integrity` ルールと hyoui の実態の乖離

hyoui は open issue 42 本、うち flaky 系が 3 本 (`06-02 flaky-serve-propagates-child-exit-code`、`07-03 macos-ci-flaky-pty-tests`、`07-25 flaky-serve-ro-lock-acquire-rejected`) と `07-26 ignored-tests-job-permanently-red` が 2〜3 か月放置。今日常時ロードへ昇格した `test-integrity.md` の「flaky と書きたくなった瞬間が手抜きシグナル」「全部書けないなら調査未完了」は正しいが、既存負債に遡及する日程がない。ルールを立てた日に、最大の違反者が自分の主力プロダクトである状態は、ルールの説得力を削る。

### 2.4 「常時ロード予算」が統括の実コストを表していない

`lint-rules` の予算 81,920 bytes は `for-*/rules` だけを数える。実測 78,597 (96%、余裕 3.3KB)。しかし統括セッションは起動時に `reference/role-main/_index.md` 経由で 5 ファイル + 索引 2 本 (計 36.7KB) を Read し、agent 定義 (22KB のうち description 分) と skill description も載る。統括の実効起動コストは約 120KB で、予算の 1.5 倍。overlay リポの rules も加算されるが lint からは見えない (justfile コメントで自認済み)。

「rules 予算」と「統括起動コスト」を別の数字として計測し、後者にも線を引くべき。今日 `docs-structure` (19KB) を `docs-layout` (数 KB) に置き換えたのは正しい方向で、`main-role-playbook` / `model-effort-matrix` の次の圧縮対象を決める材料になる。

### 2.5 hook のテストが push gate に入っていない

`hooks/tests/vcs-guide.test.sh` は 27 件全部通る (実行確認済み) が、`just push` の deps (`check-on-default-branch ensure-clean lint-rules lint-agents validate check-versions check-version-bumped`) に無い。9/9 に vcs-guide.sh を 5 回改訂しているので、この日にこそ gate が要った。加えてテスト冒頭コメントが「許可リスト (/github.com/kawaz/) を通るパス」と v0.8.2 で廃止した仕様に言及しており、`no-historical-noise` に触れる。

### 2.6 小さいもの

- `lint-rules` は wikilink / 越境 / サイズ / 索引 1:1 を検査するが、hook が名指しする reference パスの存在は検査しない (今回は 7 パス全部存在)。移設が続く間は (i) として足す価値がある
- `reference/justfile/recipes.md` に「bump-semver / cmux-msg / session-analysis の justfile が recipe の正本」とあるが、claude-session-analysis は 7/3 から更新が無く、正本にしておく理由が薄い

## 3. claude-rules-personal ブラッシュアップの個別評価

### 3.1 やったこと (9/1〜9/9)

- 3 分類原則を「常時 / skill / 参照知識」に改訂し、skill = ユーザ起動の実行系と定義し直した
- skill 34 本のうち 21 本を `reference/` の 8 トピックへ移設 (jj-tips 23KB 等)。skill は 11 本に減少
- 思想 3 件を常時ロードへ昇格 (`test-integrity` 新設、`design-thinking` に「目的と責務から書く」節、`role-based-skill-loading` に「自律進行」節)
- 常時ロード rule の knowledge 降格 14 件を精査・実施。常時ロードは 128KB → 78.6KB
- `vcs-skill-autoload` → `vcs-guide` に改名し、colocate 誘導を追加。許可リストをローカル設定に外出し
- agent 命名を `<role>-<model>-<effort>` に統一、description を最小化、モデル ID から版番号を除去
- delegation 系 reference を圧縮 (playbook 153 → 70 行、phases 83 → 58 行)
- `auth-patterns/` (passkey 登録 / peer 認証 / self 確定) を ccmsg の設計から汎用知識として切り出し

### 3.2 良い点

**判定基準を機械条件でなく意味に置いた。** 「付属ファイルがあれば skill」ではなく「この本文が invoke されること自体に意味があるか」。findings がその判定を機械化すると取りこぼす 3 系統 (`context: fork` / `$ARGUMENTS` / hook が名指し) を先に洗い出し、境界例 (itumono-review-*、push-watch、macos-signing、docs-structure 分割) に両論を付けている。裁定後の実装は findings の「skill に残す 13 本」からさらに 2 本減らしており (questions-registry / gh-image-attach も reference へ)、裁定が精査結果を機械的になぞらず上書きしている。

**移設の順序がリスク順。** 「hook を先に直して skill を残したまま動作確認 → 次の commit で skill を消す」「rule 昇格を先に land してから対応 skill を移す」の 2 点は、案内先が消える窓を作らない。実際のコミット列 (14:18 の一括移設 → 14:50 hook 改名 → 15:xx 手順書修正) もこの順になっている。

**vcs-guide.sh の設計。** ブロックしない / 状態確認 (status・log・diff) は除外 / 1 セッション 1 リポ 1 種別 1 回 / `cd` 先を解決して越境実行も判定 / git 専用運用の除外をリポでなくローカル設定に置く。「jj を使わないセッションでは 1 字も食わない」という目的が構造にそのまま出ている。テストが 27 件付いている hook はこのエコシステムで珍しい。

**findings 2 本の質。** 「降格の可否は事故の重大度と発火語がそのターンに必ず現れるかの 2 軸」「対極節を各 rule に書き足す運用は肥大を生むので対極を 1 本に集約」「`_index.md` は索引対象が全部常時ロードなら二重掲載」など、判断基準そのものが抽出されている。今後の rule 追加の判定に再利用できる。

**残件が消化されている。** findings が指摘した public リポへの業務固有名詞混入 (`kawaz-identity` / `git-repo-management`) と `role-based-skill-loading` の古い版注釈は、今日の版で除去済み。

### 3.3 気になる点

**予算の余裕が 3.3KB しか無い。** findings の見込みは「14 件全実施で約 68,100」だったが実測 78,597。`_index.md` (4.5KB) を残した判断と昇格 3 件 + `knowledge-guide` 新設で相殺された形。判断自体は妥当だが、次に思想を 1 本昇格したら超過する。§2.4 と合わせて予算の再定義が要る。

**`model-effort-matrix` は reference の水準を満たしていない。** `knowledge-guide` は「reference の本文の質は rule と同じ水準」「雑に扱ってよいのは memory だけ」と定めるが、この本文は「astra は sol の 2 倍コスト、未実測」「fable-medium が指揮では opus-high/xhigh より遥かに良い」「luna は xhigh にすると上位 tier と並ぶことが多い」と、モデル更新で腐る実測値と主観評価で構成されている。統括が起動時に必ず Read するファイルなので影響は大きい。判定分岐と禁則 (reference に残す) と、モデル別の実測 (memory または findings に落として日付を持たせる) を分けるべき。

**role loader の履行率が計測されていない。** hook の echo → `role-main/_index.md` → 5 ファイル Read の 3 段間接で、findings 自身が「Read の指示は skill invoke より履行が緩い弱点はそのまま残る」と認めている。session jsonl から「起動後 N ターン以内に 5 ファイルが Read されたか」を数えるのは `claude-session-analysis` の守備範囲で、ここで dogfood すると 7 月から止まっているリポにも用途が戻る。

**1 日 11 リリースと plugin 反映の非対称。** rules は symlink で即時反映、hooks / agents / skills は plugin として `claude plugin update` が要る。今日は hook を 5 回改訂して各回リリースしたが、各 `CLAUDE_CONFIG_DIR` で update を回さないと古い hook が動き続ける。findings も「plugin reload 前なので description だけが context に残る」ラグを観測している。`setup.sh` に update を含める、または hook 側を reference と同じく symlink 参照に寄せる、のどちらかで非対称を潰す価値がある。

**`vcs-guide.sh` の `git -C` 非対応。** `tooling-tips` が `git -C` を禁止しているので整合は取れているが、禁止を破った時こそ案内が要る場面で、この形だけ検出から漏れる。1 分岐で足せる。

**`design-thinking.md` の思考設定節。** claude.ai 側 userPreferences との一致は確認した (drift 無し)。ただし「正本: 本ファイル。claude.ai 側 userPreferences の「思考設定」は本節の手動\n複製」と、`no-hard-wrap` を書いた同じリポの常時ロード rule が文中改行している。§2.1 の象徴例。

## 4. リポ別の簡評

| リポ | 規模 / テスト | 評価 | 気になる点 |
|---|---|---|---|
| ccmsg (v2) + ccmsg-protocol | TS 19.3k 行 / test 14k 行、DR-0001 + 契約 v1.4.0 | DESIGN が最良。M1〜M6 → §9 責務外 → §10 不採用 → §11.3 で M1〜M6 をテストで固定、と目的から検証まで一本の線。contract-first で daemon 側に検証を持たない判断も一貫 | 9/9 だけで契約 1.0 → 1.4 の 4 段 bump。設計中の契約に semver minor を連打すると、後から「どの minor が破壊的だったか」を辿れない。0.x で回すか、v2 確定まで pre-release にする方が正直 |
| claude-ccmsg (v1) | TS 41.7k 行 / test 166 ファイル、DR 33 | v2 の一次資料 (daemon 棚卸し、socket 調査) を生んだ | §2.2。v2 parity 後の退役条件が無い |
| llm-gateway | Rust 50.9k 行 / 1,091 tests、DR 28、9/9 に v0.44.2 | 「何をしないか」節が README にあり、CLIProxyAPI の失敗を根拠に介入最小化を言い切っている。cache-warden / stable-which / ccmsg との依存が健全 | README-ja 無し (他リポは翻訳ペアが標準)。`llm-gateway-cache-keepalive` が常時 rule に残る (findings は「2 行に圧縮できる」と指摘) |
| hyoui | Rust 65.2k 行 / 1,184 tests、DR 33 | 最大のプロダクト。PTY / signal / job control の findings 21 本は資産 | §2.3。open issue 42 は多い。8/25 以降更新なし。ccmsg v2 が `hyoui input` に依存し始めたので、放置は ccmsg に波及する |
| cache-warden | Rust 79.4k 行 / 1,635 tests、9 crates、DR 37 | 最大のコードベース。passkey / WebRTC の設計は `auth-patterns/` として reference に汎用化された | 8/16 以降更新なし。issue 16 本 |
| bump-semver | Go / 68 test files、DR 43 | エコシステムのハブ。全 justfile が `vcs is clean` / `on-default-branch` を dogfood | メモリにある「`vcs commit` が存在しないパスを黙って落とす」既知バグの扱いが issue 5 本に見当たらない (確認を推奨) |
| kuu / kuu.mbt | 仕様 DR 140 / 実装 DR 6、conformance fixture | spec-as-core の構造は明快 | 8/17 以降停止。open issue 29 + 36 = 65 本は最多。仕様側 DR 140 に対し実装 DR 6 の非対称は、実装が仕様に追いついていない徴候 |
| stable-which | Rust 3.2k 行 / 163 tests、crates.io 公開 | 小さく完結。cache-warden / llm-gateway / hyoui が依存 | 特になし |
| die | Zig、DR 9 | 「shell 関数でなく OS の単体 binary」の目的が 1 行で言える。TDD の教訓源として rules に還流済み | メモリの「`buildArgOutput` vs `joinArgs` の重複が unit test で覆われていない」構造的ギャップが issue 化されていない (issue 0 本) |
| claude-session-analysis | TS / 11 test files | セッション jsonl の分析基盤 | 7/3 以降停止。§3.3 の loader 履行率計測に使えば復活の口実になる |

## 5. 読めていないもの

- `privacy-personal` / `privacy-<面>` 4 リポと overlay 3 リポ (private)。`knowledge-guide` の 3 層構造の第 3 層は構造だけ見えていて中身は未評価
- `claude-nandakke` / `claude-local-issue` / `claude-gh-*` 等の他 plugin 群は今回の指定外で未読
- 実際のセッションログ。ルールの「履行率」に関する指摘 (§3.3) は構造からの推定で、実測ではない
