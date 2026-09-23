---
title: エコシステム外部レビュー (2026-09) の指摘への対応検討
status: open
category: task
created: 2026-09-10T15:20:00+09:00
last_read:
open_entered: 2026-09-10T15:20:00+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: kawaz 依頼 (2026-09-10)
---

# エコシステム外部レビュー (2026-09) の指摘への対応検討

## 概要

外部レビューで本リポ (claude-rules-personal) 向けの指摘 (R-1〜R-16) と、全リポ共通のバックポート候補パターン (P-1〜P-48、反映先の多くが本リポの reference / rule) が出た。以下を読んで対応を検討する。

- 個別ファイル: `docs/research/2026-09-10-ecosystem-review/claude-rules-personal.md`
- 共通ファイル: `docs/research/2026-09-10-ecosystem-review/common.md`

## 背景

レビューは初版の指摘から個別プロジェクトの精読を進めるたびに認識が改まり、指摘が覆されたケースが多い。**全面的に鵜呑みにせず実物と照合してから採否を決めること**。「裁定待ち」項目は kawaz の判断が要る。R-3 (cmux-msg 残骸) は 2026-09-09 に対応済み。

## 受け入れ条件

- [ ] R-1〜R-16 を実物と照合し、採用 / 却下と理由を判定する (裁定が要るものは QUESTIONS.md へ)
- [ ] P-1〜P-48 のうち本リポの reference / rule に反映するものを選別し、反映先ごとに作業単位を切る
- [ ] 採否の結果を本 issue に追記して close する

## 仕分け (2026-09-23)

実物 (for-*/rules, reference, memory, skills, hooks, justfile) を grep / Read で照合した結果。P 系の「現状」は rules-personal 側に既存が無いことの確認までで、出所 (各リポの DR 等) の裏取りは反映時に行う。

### R 系

| ID | 要旨 | 現状 | 妥当性 | 推奨 | 規模 |
|---|---|---|---|---|---|
| R-1 | no-hard-wrap を lint で検査 | lint 未実装。簡易 awk で rules / reference / memory の約 19 ファイルに疑わしい行。裁定部分 (一括 reflow の可否) は commit 1be70b3 で「一括で直してよい」に変わり解消済み | 妥当 | 即やる (lint warning 追加 → 一括 reflow) | 中 |
| R-2 | hook テストを push deps に | 残存。`justfile` の `push:` deps に test-hooks 無し。`hooks/tests/vcs-guide.test.sh:15` に廃止仕様「許可リスト (/github.com/kawaz/)」の言及が残る | 妥当 | 即やる | 小 |
| R-3 | cmux-msg 残骸掃除 | 解消済み (for-all / for-me / reference / memory / skills / justfile で grep ヒット 0) | ― | 対応不要 | ― |
| R-4 | model-effort-matrix から実測・主観を分離 | 残存 (`reference/delegation/model-effort-matrix.md` の「モデル特性差」節に主観評価、「astra は sol の 2 倍コスト、未実測」) | 方向は妥当。ただし直近 (13a0ce4 / ab8549f) で kawaz がこの節周辺を活発に更新しており、判定と根拠の同居が意図的な可能性 | kawaz 裁定待ち | 小〜中 |
| R-5 | peer-auth に skew の扱い | 解消済み (前提表に P5、`exp` の説明にも P5 参照) | ― | 対応不要 | ― |
| R-6 | 統括起動時 Read 量を lint で数える | 残存 (justfile に role-main 関連の検査無し) | 妥当。80KB 予算と同じ「増えたら気づく」思想と一致 | 即やる | 小 |
| R-7 | auth-patterns / cli-daemon を「バックポート標準」と明示 | 残存 (knowledge-guide / 各 `_index.md` に backport の記述無し) | 妥当。ただし置き場を常時ロードの knowledge-guide にすると肥大。rules-authoring か auth-patterns の `_index.md` 冒頭が規約に合う | 即やる (置き場は reference 側) | 小 |
| R-8 | auth-patterns 本文の小さな穴 | 一部解消。`__Secure-` を選ぶ理由は記載済み。未対応: BE/BS フラグと extensions の扱い、topOrigin 拒否と crossOrigin の含意関係、self-endpoint の「設定に載せる peer を信頼する前提」、cli-daemon の `daemon start/stop` の意味、subprotocol で token を渡すことの理由付け (短命かつメモリ内) | 妥当 | 即やる | 小 |
| R-9 | hook の参照パス実在を lint 検査 | 残存 (`vcs-guide.sh` が `$ref_dir/*.md` を 7 本名指し、検査無し) | 妥当 | 即やる | 小 |
| R-10 | vcs-guide.sh で `git -C` 検出 | 残存 (`-C` の分岐無し) | 妥当 | 即やる (テスト 1 件追加) | 小 |
| R-11 | design-thinking.md の文中改行 | 残存 (「思考設定」節の「本節の手動 / 複製」) | 妥当 | 即やる (R-1 の reflow に含まれる) | 小 |
| R-12 | バックポート追跡 issue | 未起票 | 妥当。レビュー自身が「ccmsg 安定後」と時期条件付き | issue 化して後で | 小 |
| R-13 | rule の廃止基準 | 残存 (rule-writing-guidelines / rules-authoring に廃止基準無し) | 妥当 (追加側だけある片面)。期間・棚卸し周期は方針判断 | kawaz 裁定待ち | 中 |
| R-14 | rule → 踏んだ事故の逆引き | 残存 (`根拠:` 行を持つ rule は 0 本) | 常時ロード bytes 増と rule を短く保つ方針との緊張。全 rule 必須化は重い | kawaz 裁定待ち | 中 |
| R-15 | rule の節構成の最小型 | 残存 (型の規定無し) | R-14 の採否に依存 | kawaz 裁定待ち (R-14 と一緒に) | 中 |
| R-16 | itumono-review-* 3 本の skill 残置 | 残存 (skills/ に 3 本、`agent-runtime/external-review-cli.md` 無し) | 直接起動の実績次第 | kawaz 裁定待ち | 小 |

補足:

- R-1: 19 ファイルは誤検知を含む簡易推定。lint 実装後に正確な数を出す
- R-2: 「jq 不在時は skip でなく fail」も妥当 (hook 本体は jq 不在で黙って exit 0 するので、テストまで黙ると検出できない)

### P 系

| ID | 要旨 | 現状 | 推奨 | 規模 |
|---|---|---|---|---|
| P-1 | クロス OS の TTY 判定 | 無し | issue 化 (reference 新設) | 中 |
| P-2 | ゲートを足したら 1 回わざと落とす | 無し | 即やる (release-pipeline に節) | 小 |
| P-3 | default の意味を最小に定義 | 無し | 即やる (cli-design-preferences) | 小 |
| P-4 | 自作 vs ライブラリの選定手順 | 無し | 即やる (spec-preflight) | 小 |
| P-5 | DR INDEX に Status 列 | 無し | 即やる (テンプレ + rule に 1 行) | 小 |
| P-6 | category 横断検証 | rule 側に既存 (`empirical-verification` の「最低 3 種類の category」) | 却下寄り (testing には rule 参照 1 行で十分) | 小 |
| P-7 | 観測道具の bug は最優先で直す | 無し | 即やる (empirical-verification に 1 文) | 小 |
| P-8 | 禁則に踏んだ実例を添える | 無し | R-14 の裁定に従う | 小 |
| P-9 | 不変条件を grep で判定できる文で書く | 近い記述はあるが文の書き方は無い | 即やる | 小 |
| P-10 | optional capability を型で表す | 無し | issue 化 (design-patterns 新設) | 中 |
| P-11 | supersede する DR の書き方 | 無し | 即やる (spec-finishing) | 小 |
| P-12 | README に「何をしないか」節 | 無し | 即やる (テンプレ) | 小 |
| P-13 | hook の設計規律 | 無し | issue 化 (hook-design 新設、R-2 / R-10 と同時) | 中 |
| P-14 | 不変条件テストのカタログ | 半分 (design 側のみ) | issue 化 | 中 |
| P-15 | 時間の値の 4 分類 | 無し (「周期」は poll 遅延の文脈のみ) | 即やる (event-driven-alternatives) | 小 |
| P-16 | commit message の型 | 無し | kawaz 裁定待ち (本リポには英文の意図文の commit も混在) | 小 |
| P-17 | service register の焼き込みパスを stable-which で | 無し | 即やる (cli-daemon に 1 段落) | 小 |
| P-18 | allow-list 判定、未知は安全側 | 無し | 即やる (spec-preflight に 1 行) | 小 |
| P-19 | パッケージマネージャ配置表 | 無し | issue 化 (path-managers 新設) | 中 |
| P-20 | 述語コマンドの exit code | 無し | 即やる | 小 |
| P-21 | 安全側に倒した opinionated な層 | 無し | 即やる (「介入は最小限」と逆向きなので両方併記) | 小 |
| P-22 | recipe から `glob:` で引数を渡す | 無し | 即やる (recipes) | 小 |
| P-23 | 外部コマンド呼び出しの信頼境界 | 無し | 即やる (spec-preflight に節) | 小 |
| P-24 | 複数ファイルの all-or-nothing 書き込み | 無し | P-10 の design-patterns issue に統合 | 中 |
| P-25 | skill / hook の起動テスト | 無し | issue 化 | 中 |
| P-26 | 重なるオプションの併用規則を help に | 無し | 即やる | 小 |
| P-27 | transcript を渡す形 | 無し | 即やる (context-budget) | 小 |
| P-28 | 分類作業は残差駆動 | 無し | 即やる (findings-recording) | 小 |
| P-29 | claude-code-internals 新設 | 無し | issue 化 | 大 |
| P-30 | 裁定の逐語記録を research/ に | 無し | 即やる (knowledge-timing。memory の no-chat-refs-in-docs と整合確認) | 小 |
| P-31 | 設計文書の規範監査 | 無し | issue 化 (runbook + spec-finishing) | 中 |
| P-32 | セッション間通信の規約 | ccmsg skill にはある、本リポには無い | kawaz 裁定待ち | 小 |
| P-33 | SendMessage vs ccmsg の経路選択 | 無し | 即やる (P-32 と同じファイル) | 小 |
| P-34 | 時間依存テストは clock 注入 | 無し | 即やる (flaky-accountability) | 小 |
| P-35 | 契約 fixture の共有 | 無し | issue 化 (P-45 と同ファイル) | 中 |
| P-36 | 実行環境の前提 (Caddy + tailnet) | 無し | 即やる (auth-patterns `_index.md` に 3 行) | 小 |
| P-37 | eTLD+1 分離 | 一部 (passkey 文書に前提だけ) | issue 化 (origin-separation 新設) | 中 |
| P-38 | macOS 特権ポート bind | 無し | 即やる (memory) | 小 |
| P-39 | ACME DNS-01 最小権限 | 無し | 即やる (memory) | 小 |
| P-40 | nameConstraints 付きテスト CA | 無し | issue 化 (スクリプトの置き場未定) | 中 |
| P-41 | 先行製品のバイナリ解析 | 無し | issue 化 (macos-recon 新設) | 中 |
| P-42 | secret TTL の soft / hard | 無し | issue 化 (P-44 と同 issue) | 中 |
| P-43 | UDS peer 認証をプロセスツリーで | 無し | 即やる (cli-daemon に 1 段落) | 小 |
| P-44 | 秘密値の型設計 | 無し | issue 化 (design-patterns) | 中 |
| P-45 | green の規範 | 無し | P-35 の issue に統合 | 中 |
| P-46 | VISION.md の位置付け | 無し | 即やる (docs-layout) | 小 |
| P-47 | 実世界 CLI コーパスで仕様検証 | 無し | 即やる (test-coverage-checklist) | 小 |
| P-48 | session launcher テンプレ | 無し | issue 化 (ccmsg v2 安定後) | 中 |

補足:

- P 系の多くは kawaz 所有の他リポの DR が出所。反映前に出所で裏取りする
- P-36 / P-37 に出る個人ドメインは業務識別子リストに該当せず、サニタイズ対象外
- issue 化の単位: P-10 / P-24 / P-44 を「design-patterns 新設」1 本、P-35 / P-45 をテスト 1 本、P-32 / P-33 をセッション間通信 1 本にまとめると自然

### 即やる群

- R 系: R-1 (lint 追加 + 一括 reflow)、R-2、R-6、R-7 (置き場は reference 側)、R-8、R-9、R-10、R-11
- P 系: P-2、P-3、P-4、P-5、P-7、P-9、P-11、P-12、P-15、P-17、P-18、P-20、P-21、P-22、P-23、P-26、P-27、P-28、P-30、P-33、P-34、P-36、P-38、P-39、P-43、P-46、P-47
- 対応不要: R-3、R-5 (解消済み)、P-6 (rule に既存)

### kawaz 裁定待ち群

- R-4: model-effort-matrix のモデル特性差 (主観評価・実測値) を memory に分離するか、判定と根拠を同居させる現運用を続けるか。
- R-13: rule の廃止基準を設けるか。設けるなら「発火が無い期間」と棚卸し周期をどうするか。
- R-14 / P-8: 全 rule に `根拠:` 行を必須化するか (常時ロード約 2.3KB 増、肥大を避ける方針と衝突)。
- R-15: rule の節構成の最小型 (禁則 / 対極 / reference 誘導 / 根拠) を定めるか (R-14 の結論次第)。
- R-16: itumono-review-{claude,codex,gemini} を直接起動した実績はあるか、無ければ reference に降ろしてよいか。
- P-16: commit message の型を「`feat:` 等の prefix + 日本語の意図文」に標準化するか。
- P-32: セッション間通信の規約のうち「リレー報告不要」「社交辞令禁止」の 2 行を常時ロード rule (work-principles) に入れるか、reference に留めるか。
