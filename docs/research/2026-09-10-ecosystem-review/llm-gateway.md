# エコシステムレビュー指摘 — llm-gateway

外部レビュー (2026-09-09〜10) のうち本リポ向けの指摘。温度感と共通指摘は [README](README.md) / [common](common.md) を参照。

優先度: ★3 (次の作業で) / ★2 (近いうちに) / ★1 (気づいた時に)。「裁定待ち」は kawaz の判断が要るもの。各項目は「指摘 → 修正案」。

単体評価 (9/9): 強みは (1) README の「何をしないか」節で介入最小化を前身 (CLIProxyAPI) の実障害を根拠に言い切っていること、(2) DR-0014 の判定基準「core は provider の名前を 1 つも知らない」が実装でほぼ守られていること (core crate の非テスト部で provider 名が出るのは `RequestOrigin::Codex` = DR-0025 で正当化済みと config.rs の doc 例だけ)、(3) テスト密度 (1,091 tests。`gateway.rs` は実装 1,870 行に対しテスト 5,200 行)、(4) CI が os matrix + MSRV + cargo-audit で `just ci` が push gate、(5) findings の実測 (TTL refresh on hit、nonce 遵守率 32.6% → 98%) で自分の DR を覆す動きが速い。課題は「決めたのに実装が追いついていない DR」と「実装したのに未確定を閉じていない DR」の 2 つに集約される。

### L-1 ★1 README-ja の翻訳ペア

- 指摘: 他リポは README / README-ja のペアが標準だが、llm-gateway は日本語の README.md 1 本
- 修正案: `translation-pairs.md` の規約どおり README-ja.md を原本にし README.md を英訳にする。急がない

### L-3 ★3 DR-0027 (keepalive replay) を Accept して着手するか、見送りを明記する

- 指摘: DR-0027 は Proposed のまま (9/8)。「未確定」は 9/9 の findings で回答済み (再送は本文そのまま + max_tokens=1 に確定) なので Accept できる状態。一方で同日に合図方式のバグ修正 (`keepalive-foreign-standby-fires-immediately`、`spent` 語彙の追加) に工数を使っており、DR-0027 が通れば丸ごと消える機能を直している
- 併せて矛盾: `docs/issue/2026-09-08-keepalive-via-messaging-socket.md` (design、open) は合図の注入経路の改善案で、DR-0027 の「合図方式を廃す」と両立しない。同日に両方が open になっている
- 修正案: DR-0027 を Accepted にして実装に入る。順序は §3 (本文をファイルに置く) → §1 (replay) → §6 (観測に出す) → §7 (ccmsg 受け口と rules-personal の `llm-gateway-cache-keepalive` rule を落とす)。`keepalive-via-messaging-socket` は DR-0027 採択を理由に discard。見送るなら DR-0027 に「見送り理由と再開条件」を書き、合図方式の bug fix を続ける根拠にする
- 旧 L-2 (rule の 2 行圧縮) はここに統合: DR-0027 §7 で rule 自体が消えるので、圧縮は着手しないなら不要、着手するなら削除で済む

### L-4 ★2 DR-0028 の「未確定 (実装前に確かめる)」を実装後に閉じる

- 指摘: DR-0028 は 9/9 に実装完了し決定 7・9 を追加しているが、「未確定」節の 3 項目 (子のログの置き場と回転 / 監督者が落ちた時に子をどうするか / systemd 側の検証) が未回答のまま残っている。新 issue `daemon-restart-order-and-grace` と bug `service-status-running-false-while-loaded` はこの未確定の延長で出ている
- 修正案: 3 項目それぞれに実装がどう振る舞っているかを DR に書く (決定 10〜12 として)。「監督者が落ちた時の子」は実装を読んで確定した事実を書く (道連れか孤児か)。systemd は未検証なら「未検証、macOS のみ実証」と適用範囲外に書く。これは `cli-daemon-subcommands` reference の元ネタなので、ここで閉じた結論は reference にも効く

### L-5 ★1 `gateway.rs` 7,070 行 / `llm-gateway-server/src/lib.rs` 4,089 行

- 指摘: DR-0014 が ingress / egress / exchange の三境界を定めたが、`gateway.rs` (実装 1,870 行) と server crate (単一ファイル) はその境界で割れていない。テストが厚いので急がない
- 修正案: 次に gateway.rs を大きく触る時に、DR-0014 §1 の語彙でファイルを割る (ingress = server crate の parse / authorize、exchange = 観測フック)。分割だけの PR は作らない (テストの移動で diff が読めなくなる)
