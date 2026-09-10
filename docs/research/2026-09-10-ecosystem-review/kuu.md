# エコシステムレビュー指摘 — kuu / kuu.mbt

外部レビュー (2026-09-09〜10) のうち本リポ向けの指摘。温度感と共通指摘は [README](README.md) / [common](common.md) を参照。

優先度: ★3 (次の作業で) / ★2 (近いうちに) / ★1 (気づいた時に)。「裁定待ち」は kawaz の判断が要るもの。各項目は「指摘 → 修正案」。

評価 (9/10、kuu-v0 / slice 枝も取得): エコシステム最大のプロジェクト (commits 1369 + 925 + 494、DR 140 + MDR 6 + v0 の 61)。趣味プロジェクトで v1 未リリース。構成は **spec-as-core**: kawaz/kuu が仕様 (DESIGN 1,622 行 / REFERENCE 933 / LOWERING 506 / CONFORMANCE 321 / PIPELINE / VISION) + JSON schema + conformance fixture 454 ファイル (query 別: parse 315 / definition_error 65 / complete 32 / lower 24 / help 18) + real-cli corpus (brew / curl / docker / dd / cut / die … の実 CLI を定義で再現) を持ち、kuu.mbt は「fixture を pass すること = 移植の定義」で作る参照実装 (MoonBit 75k 行、うちテスト 32k)。README に conformance green (decoded=317 / 733 cases / 0 mismatches、spec pin b44a650b) が明記されている。v1.0.0 の条件は「5 プロファイル全 green」(DR-113 §9) で、green の規範 (全 decode / 全 case / skipped=0 / mismatch=0 / spec commit pin) が CONFORMANCE §0.1 に定義されている。VISION は「v0 からの再出発」を kawaz の 07-14 の発言引用で書き、v0 (3 月、combinator パーサ、DR 61) と slice (7 月上旬、垂直スライス PoC) を枝としてアーカイブし README から辿れる。「幻影コマンド」(定義 JSON さえあればバイナリ無しで引数パース・補完・ヘルプが再現される独立コマンド) が構想の核。

### K-1 (訂正) conformance の pass 状況は README に既にある

- v1 の「fixture の pass 件数を README に出す」は既に達成 (green、decoded=317)。訂正
- 残る小さな指摘: decoded=317 は parse-core 主体で、5 プロファイル (parse-core / lowering / definition-error / completion / help) のどれが green かが README からは読めない。CONFORMANCE §0 の表に「kuu.mbt の現況」列を足すか、README の Status に 5 行の表を置く。v1.0.0 条件が「5 つ全 green」なので、残りがどれかは進捗表示として要る

### K-2 ★1 open issue 36 本の大半が 8/16〜17 の棚卸し起票

- 指摘: 36 本のうち 20 本が 08-16〜17 の 2 日で起票され、その直後に停止 (最終コミットは 08-17 の「stale issue 棚卸し」)。棚卸しで見えた残作業がそのまま凍結されている形。趣味なので優先度は kawaz 次第だが、再開時に「どこから」が分かる状態にはある
- 修正案: 再開時、K-1 の 5 プロファイル表を先に埋め、green でないプロファイルに紐づく issue から着手する (v1.0.0 条件に直結する順)。それ以外の 08-16 起票分は v1.0 後に回す印を INDEX に

### K-3 ★1 kuu-cli 構想と他リポの CLI パーサの接続

- 指摘: VISION §3 の「幻影コマンド」は、stable-which (SW-1: 手書きパーサ 266 行) や bump-semver (cobra) の CLI が `app.json` 1 つで kuu-cli 経由になる構想で、SW-1 の「kuu が使える段階になったら」の受け皿。real-cli corpus に `die.json` が既にある (die の定義を kuu で再現している)。ただし kuu-cli の実装 (kuu-cli リポ、07-15〜08-02、134 commits) の状態が VISION からは読めない
- 修正案: VISION §3 か ROADMAP に kuu-cli リポの現況 (どこまで動くか) を 1 行。die / stable-which を「幻影コマンド」の最初の適用先として corpus と対にする
