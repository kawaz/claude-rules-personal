# エコシステムレビュー指摘 — ccmsg / ccmsg-protocol (v2)

外部レビュー (2026-09-09〜10) のうち本リポ向けの指摘。温度感と共通指摘は [README](README.md) / [common](common.md) を参照。

優先度: ★3 (次の作業で) / ★2 (近いうちに) / ★1 (気づいた時に)。「裁定待ち」は kawaz の判断が要るもの。各項目は「指摘 → 修正案」。

単体評価 (9/10): 9/8 開始で 2 日 139 コミット、src 19.3k 行、test 36 ファイル 14k 行。DESIGN §11.3 の「増やさない M1〜M6 をテストで固定する」が全部実装されている (`no-role-branch.test.ts` = M1、`periodic.test.ts` = M3、`instance.test.ts` に M4 / M6、`single-push.test.ts` と `topics.test.ts` に M5)。時計を instance に注入して進め、WS が閉じるのを観測するテスト (期限の deterministic 化)、契約リポの fixture を daemon のテストが読む形 (§11.1) も入っている。protocol は 1.1k 行 + `conventions.test.ts` (表記規約の機械検査)。open issue 7 本は全部 9/9 起票で、設計 4 / bug 3。webui は別リポで着手したばかり (未確認)。

### C-1 ★2 契約の版付けを設計段階に合わせる

- 指摘: 9/9 だけで `@ccmsg/protocol` を 1.0.0 → 1.4.0 と 4 段 minor bump。設計中の契約に semver minor を連打すると、後から「どの minor が破壊的だったか」を辿れない。実際 1.2.0 (`endpoint` optional 化) は消費側の型が変わる
- 修正案 (裁定待ち): v2 が確定するまで `0.x` または `1.0.0-alpha.N` で回し、ccmsg 側の依存は `workspace:` か exact pin にする。1.0.0 は「daemon の主要経路がこの契約で e2e を通った」時点に打つ

### C-2 (削除)

- v13 の「mesh の信頼の根が実装ではまだ無い」は取り下げ。mesh は wss のみで、TLS 終端は canddy-app-proxy が担い、認証は passkey (人) と peer-auth (instance) の設計が済んでいて実装段階。issue `mesh-tls-trust-root` が既に作業 3 つを持っている。tailnet は経路の到達性だけで認証を保証しないことも設計 (canddy §7 の二層構造) に書かれている

### C-4 ★2 dump / TL におけるサブエージェント (sidechain) の扱い

- 指摘: csa から引き継ぐ論点。統括が委譲した worker の thinking / response を、diary 用 dump にどう出すか (統括の turn として畳む / 別セッションとして分ける / 除外)。日記の「私」が誰かに関わるので、dump の設計判断として決める
- 修正案: 実機の jsonl でサブエージェントの記録形式 (同一 jsonl に `isSidechain` で混ざるか、別ファイルか) を確認して findings に残し、dump の出力仕様 (DESIGN §3.3 の transcript fold の隣) に「sidechain の扱い」を 1 節。既定は「統括の turn には畳まず、A (Agent) の子として 1 段インデント」あたりが日記としては読みやすい (裁定待ち)

### C-5 ★2 テストが spawn した daemon が孤児で残る

- 指摘: issue `test-spawned-daemons-outlive-the-run` (9/9)。テスト基盤の問題で、CI で残存すると次の run の socket / port と衝突し、flaky に見える失敗を作る。hyoui の H-1 と同じ経路で「flaky」ラベルが付く前に潰す価値がある
- 修正案: `test/harness.ts` で spawn した daemon を必ず `afterAll` で SIGTERM → 猶予 → SIGKILL し、残存を harness 自身が検出して fail にする (残っていたら「テストが緑」にしない)。DESIGN §8.5 (停止の順序) をテストで踏む形にもなる

### C-6 ★2 「instance は対等、セッションは優劣付き」を前提に書く

- 指摘: mesh (§7) は instance 同士を対等に扱い、どこに繋いでも全部見える。一方セッション間の会話規約 (P-32) は優劣付きで、plugin の skill 側にだけある。この 2 層の違いは kawaz の来歴 (対等な会議が崩れた → 優劣付き、複数ホストは対等に統合) から出た判断だが、DESIGN には書かれていない
- 修正案: DESIGN §2 の前提に「instance 間は対等 (どの instance に繋いでも同じ集合が見える)。セッション間の会話は対等でなく、受け取り規約は plugin の skill が定める (基本サブエージェント扱い、社交辞令なし、人へのリレー報告なし)」を 1 行。後発が mesh の対等性を会話規約まで延ばさないための境界

### C-3 ★1 DESIGN-ja.md の hard-wrap

- 指摘: 69KB の設計文書が全面的に hard-wrap。`no-hard-wrap` は「rule / skill / docs のファイル」を対象に含む
- 修正案: v2 の設計が落ち着いたタイミングで 1 回 reflow (§12 の裁定表は表なので影響なし)。DESIGN.md (英訳ペア) も同時に
