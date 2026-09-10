# エコシステムレビュー指摘 — claude-session-analysis

外部レビュー (2026-09-09〜10) のうち本リポ向けの指摘。温度感と共通指摘は [README](README.md) / [common](common.md) を参照。

優先度: ★3 (次の作業で) / ★2 (近いうちに) / ★1 (気づいた時に)。「裁定待ち」は kawaz の判断が要るもの。各項目は「指摘 → 修正案」。

単体評価 (9/9) → 前提変更: ccmsg の進歩で TUI から Claude を触る機会がほぼゼロになり、ユーザメッセージは ccmsg の subscribe プロセス (Monitor ツールでサイドカー) からツール通知として届く。csa はその形を拾えないので、diary の入力生成は `ccmsg dump` に役割が移った。ccmsg 側は webui の TL 表示のために jsonl のパターン分析を進めており (既分類は TL に見え、未分類は「N items」として残差表示、クリックで 1 個ずつ確認・pretty 化)、csa 時代の「分析済みも混ざった膨大な jsonl から未分類を手で探す」作業より格段に速い。csa 自体の評価 (テスト密度、TEST.md の skill 起動テスト) は変わらないが、製品としては退役候補。

### S-1 ★1 role loader の履行率計測 (主体を ccmsg dump に変更)

- 指摘: rules-personal の role loader の履行率が計測されていない点は変わらない。計測元は csa でなく `ccmsg dump` (または ccmsg の TL) になる
- 修正案: ccmsg dump の出力で「SessionStart 後の Read 対象パス」を数える 1 行を、rules-personal の `docs/runbooks/fleet-audit.md` に置く。ccmsg 側に Read の file path が TL 上で拾える形で出ていることが前提 (未分類なら残差から拾える)

### S-2 〜 S-5 (取り下げ)

- diary 用途の README 記載、sidechain 対応、jsonl 形式の追従、翻訳ペア命名は、いずれも csa を製品として維持する前提の指摘。役割が ccmsg dump に移った以上、csa 側に投資する理由が無い。sidechain の扱い (S-3 の「worker の thinking が日記に混ざるか抜けるか」) は ccmsg dump 側の論点として ccmsg v2 の issue へ移す (C-4)

### S-6 ★1 退役手順に載せる

- 指摘: csa は rules-personal の `for-all/plugins.json` と `reference/justfile/recipes.md` (「bump-semver / cmux-msg / session-analysis の justfile が正本」) に残り、hyoui の REVIEW-BACKLOG 来歴 (「csa の thinking ログから集約内容を抽出」) など参照も散っている
- 修正案: `docs/runbooks/repo-retirement.md` (rules-personal) の手順で退役。README 冒頭に「ccmsg dump に置き換え済み。TUI からの利用が主の環境では引き続き使える」を 1 段落、`plugins.json` から外し、`recipes.md` の正本一覧からも外す (R-3 と同じ commit で)。アーカイブは急がない (TUI 利用者向けには壊れていない)
