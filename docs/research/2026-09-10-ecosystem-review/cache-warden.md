# エコシステムレビュー指摘 — cache-warden (系譜: ssh-agent-router → authsock-filter → authsock-warden → cache-warden)

外部レビュー (2026-09-09〜10) のうち本リポ向けの指摘。温度感と共通指摘は [README](README.md) / [common](common.md) を参照。

優先度: ★3 (次の作業で) / ★2 (近いうちに) / ★1 (気づいた時に)。「裁定待ち」は kawaz の判断が要るもの。各項目は「指摘 → 修正案」。

系譜評価 (9/10、4 リポを clone):

| 世代 | 期間 | 規模 | 一般化の段 |
|---|---|---|---|
| ssh-agent-router | 2025-12-31〜01 | Rust 978 行 / 12 commits | 1 つの upstream agent から fingerprint 別の複数 socket を作る (ルーティング) |
| authsock-filter | 2026-01〜04 | 7k 行 / 156 commits | フィルタ (fingerprint / comment / 鍵種 / GitHub user / keyfile、glob・regex) + ログ。README の動機「agent は全鍵を出すので MaxAuthTries に当たる、意図しない identity 露出、GitHub で別アカウントに繋がる」がこの系譜の原点 |
| authsock-warden | 2026-04〜05 | 12k 行 / 151 commits | op (`op://`) からの鍵取得とローカル署名、process-aware access control (PID + プロセスツリー)、4 状態ライフサイクル (Not Loaded → Active → Locked → Forgotten)、remote re-auth、mlock / zeroize / ptrace 拒否、OS service。「daily use」に到達した最初の世代 |
| cache-warden | 2026-04-10〜08-16 | 79k 行 / 392 commits / 9 crates | コアを「秘密値のセキュア KV キャッシュ (soft/hard TTL、再認証で延長、プロセス認証)」に一般化し、SSH 鍵は authsock アダプタとして載せる。DR-0004 で後継宣言、v0.24 で authsock-warden と parity (Phase 2)、dogfood (Phase 3) |

1 世代ごとに問題を 1 段だけ一般化している (ルーティング → フィルタ → 鍵のライフサイクルと op → 秘密値全般) のが特徴で、各世代が前の世代を daily use で置き換えてから次に進んでいる。cache-warden は DR 29 + draft 5、テスト 1,635、`macos-process-inspect` / `macos-tcc` / `cache-warden-webauthn` を独立 crate に切っている。TouchID は draft-DR-0031 で 1Password の `.app` をリンク解析 (`otool`) して `LocalAuthenticationEmbeddedUI.framework` を突き止め、公開 API であること (macOS 12+、PrivateFrameworks ではない) を実機ヘッダで確認した上で `objc2-local-authentication-embedded-ui` crate を採る判断 = 「自作せずライブラリ」を選んだ側の実例。8/16 で停止。

### CW-1 ★1 [時期: ccmsg 安定後] passkey 設計を reference の形へ寄せる (バックポート)

- 判明: passkey の初出は cache-warden だが進捗が止まり、ccmsg 側で登録・複製・ゲートのケースが出揃った結果が reference。cache-warden の旧設計 (draft-DR-0032: WebRTC DataChannel + GitHub Pages を rpId、ブラウザから CLI を承認する向き、assertion 検証は `webauthn-rs`) は打ち消し候補
- 修正案: `docs/issue/` に backport issue を起票。中身は (1) draft-DR-0032 を supersede する DR (「向きを reference に合わせる: 登録は CLI 発行の URL、承認は host の生体認証を任意ゲート (b) として積む」)、(2) WebRTC / GitHub Pages 経路に supersede 注記、(3) 実装は再開時。R-12 の表へリンク
- 注意: cache-warden の「TTL 延長を生体認証で行う」は登録時でなく利用時の承認なので、reference の任意ゲート (b) で足りるか先に確認。足りなければ reference 側に「利用時の承認」を足す。`webauthn-rs` vs 自作は P-4 の比較フェーズで決める (ccmsg の自作を上げ切ってから)

### CW-2 ★1 [時期: ccmsg 安定後] `daemon register` → `service register` 体系へ寄せる (バックポート)

- 指摘: 現状は `cw daemon register` で OS 登録まで行い、`supervise` / `service` の分離が無い。README の FDA (Full Disk Access) 言及は、reference 末尾の「署名済み launcher を別途登録し supervise の起動と死活監視に徹する」構成そのもの
- 修正案: issue を起票し R-12 へリンク。`service register/unregister/status` を足して `daemon register` を alias 経由で非推奨化 → `daemon supervise` → FDA 回避の署名済み launcher 化

### CW-3 ★2 draft DR 5 本 (0030〜0034) の Status を実態に合わせる

- 指摘: draft-DR-0031 (TouchID dialog) と draft-DR-0032 (リモート承認) は「方向性 / 方式は kawaz 裁定済み (2026-07-10)」と Status 行に書きながら Draft のまま 2 か月。0030 (kv peer-identity guard) / 0033 (signed-by) / 0034 (暗号化永続 vault、tri-review 済み) も Draft。裁定済みなら Accepted (実装は未着手) にして良い。hyoui の DR-0025 / DR-0028 と同じ「裁定は済んだが DR が Proposed で止まる」形
- 修正案: 5 本を「Accepted (未実装)」か「Draft (裁定待ち: 何が)」のどちらかに振り分けて `draft-` prefix を外す。0032 は CW-1 の supersede 対象なので、Accept せずに backport issue へ

### CW-4 ★1 `cache-warden-cli` crate 44k 行 (全体の 55%)

- 指摘: DR-0002「lib は依存最小、cli は Homebrew 配布」の裏返しで、daemon 本体 (`handler.rs` 6.8k / `server.rs` 4.9k / `authsock.rs` 4.8k) が全部 cli crate に入っている。DR-0008 (単一デーモン直担) の設計としては正しいが、crate 名と中身 (daemon がほぼ全部) がずれている。stable-which DR-0013 / bump-semver B-2 と同じ「名前と実態」
- 修正案: 再開時に `cache-warden-daemon` crate を切り、cli は本当に CLI だけにする。急がない

### CW-5 ★1 e2e flaky 1 本

- 指摘: `2026-08-12-e2e-pin-reauth-flaky-once` (高負荷並列で 1 回だけ FAILED) が open。`test-integrity` の 5 項目 (不安定さの軸 / 再現条件 / 真因仮説 / 即直せない理由 / 追跡) を埋める対象。hyoui H-1、ccmsg C-5 と同じ経路
- 修正案: P-34 (clock 注入) の適用候補。pin / soft expiry は時間依存なので、`Date.now` 相当を注入して進める形にすれば並列負荷と無関係になる

### CW-6 ★1 系譜の終端を全部 cache-warden に向ける

- 指摘: ssh-agent-router と authsock-filter の README は「Successor: authsock-warden (in active daily use)」を指し (authsock-filter は 6/10 に本文で cache-warden に触れたが冒頭は warden のまま)、authsock-warden の README には後継表示が無い。DR-0004 の Phase 4 (authsock-warden 引退) に到達しているなら 3 リポとも cache-warden を指すべき
- 修正案: `docs/runbooks/repo-retirement.md` の手順で 3 リポの README 冒頭を「Successor: cache-warden」に統一し、authsock-warden に unmaintained 表示を足す。DR-0004 に Phase 4 到達の日付を書く
