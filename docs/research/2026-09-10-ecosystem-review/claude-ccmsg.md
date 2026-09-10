# エコシステムレビュー指摘 — claude-ccmsg (v1)

外部レビュー (2026-09-09〜10) のうち本リポ向けの指摘。温度感と共通指摘は [README](README.md) / [common](common.md) を参照。

優先度: ★3 (次の作業で) / ★2 (近いうちに) / ★1 (気づいた時に)。「裁定待ち」は kawaz の判断が要るもの。各項目は「指摘 → 修正案」。

単体評価 (9/9、depth 450 で 8/12 以降全部): 4 週間で 450 コミット、daemon src 20k / test 31k、webui src 16k / test 26k と、テストが実装を上回る。DR 33、findings 25、research に kawaz 本人の設計発言を逐語で収録した一次資料 (「DR はこれを正本として参照し、パラフレーズで意図が変質したらこちらが優先」)。DR INDEX には全 DR に v2 での行き先 (「契約に吸収」「webui へ移管」「置き換わる予定」「据え置き」) が付いていて、v1 → v2 の移行計画は INDEX 自体が持っている。DR-0032 (作り直し) は webui 37k 行の負債を実測 (全状態購読 7 個、参照 0 の export 37 個…) してから踏み切っており、`design-principles-audit` (9/8) は自分の DR 群を kawaz の設計規範で監査して 61 件の指摘を 13 commit で直している。findings の半分 (transcript の形、empty thinking signature、task notification の truncation、checkpoint rewind、messaging socket、ネイティブ SendMessage との比較) は Claude Code 内部の実測記録で、ccmsg に閉じない価値がある。

### V1-1 (訂正) 退役条件は DR INDEX が持っている

- v1 で「v1 の退役条件がどこにも無い」と書いたが、DR INDEX の「v2 での扱い」列 (契約に吸収 / webui へ移管 / 置き換わる予定 / 据え置き / 対象外) がそれに当たる。残る作業は「v1 を止める条件」の 1 行 (v2 の webui が DR-0010/0020/0021/0022/0027 相当を持った時点、等) を DR-0032 §2.2 か README の Status に書くことだけ。issue は要らない
- README の「cmux-msg は parity まで維持」は cmux-msg 退役済みなので書き換え (R-3 と同時)

### V1-2 ★2 open issue 18 本を INDEX と同じ 4 値で仕分ける

- 指摘: 18 本のうち webui 機能要望 (hover toolbar、session list sections、connection log id、keepalive pause button) と v2 設計 (multi-host-cluster、messaging-socket-direct-write) が混ざっている。DR は 4 値で行き先が付いたが issue には付いていない
- 修正案: issue INDEX に「v2 での扱い」列を足し、「v2 リポへ移す (ccmsg / webui のどちらか) / v1 で対応 / discard」で仕分け。移すものは v2 側に同名 issue を立てて v1 側は archive。sonnet-medium の作業

### V1-3 ★1 「Proposed (実装済み)」の 3 本を閉じる

- 指摘: DR-0015 / DR-0025 / DR-0028 が「Proposed (実装済み)、webui へ移管 (裁定待ち)」で止まっている。実装済みなら Accepted、webui へ移管するなら移管先が決まるまで Proposed のままにする理由が無い
- 修正案: 3 本を Accepted にして「webui へ移管」だけ残す。裁定待ちの中身が別にあるなら QUESTIONS.md へ

### V1-4 ★1 `docs/inbox/` の運用を rules-personal 側へ

- 指摘: 「kawaz が雑なメモ・指示を置き、AI が手が空いた時に拾って issue 化か即対応し、処理後は削除」という運用が v1 リポの README にだけある。v2 リポや他リポに同じ経路が無い
- 修正案: 使い続けるなら `reference/docs-authoring/docs-layout.md` に `docs/inbox/` を「先行運用」として 1 節。使わないなら v2 に持ち込まず消す (裁定待ち)
