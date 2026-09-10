# エコシステムレビュー指摘 — hyoui

外部レビュー (2026-09-09〜10) のうち本リポ向けの指摘。温度感と共通指摘は [README](README.md) / [common](common.md) を参照。

優先度: ★3 (次の作業で) / ★2 (近いうちに) / ★1 (気づいた時に)。「裁定待ち」は kawaz の判断が要るもの。各項目は「指摘 → 修正案」。

単体評価 (9/9、depth 350 で 5 月末以降を確認): 強みは (1) DR INDEX の Status 列 (✅ 実装済 / 🟡 部分 / ⬜ 未実装 / 🔁 Superseded) で DR ↔ 実装の双方向整合を INDEX 自体が持っていること (`design-impl-bidirectional-check` の実装例として他リポより進んでいる)、(2) CLAUDE.md の介入判断 self-check と「最低 3 category (alt screen / line-oriented / REPL) で検証」「観測道具に bug があれば道具を最優先で直す」という検証規律、(3) 実際にやらかした anti-pattern を名指しで残していること、(4) テスト 1,184 本と findings 21 本 (PTY / signal / job control の実測は資産)。課題は「検証主義を掲げるリポの CI が恒常 red を隠している」ことと、CLAUDE.md が rules-personal の今日の再編に追随していないこと。

### H-1 ★3 CI の恒常 red を止め、flaky 系 issue を `test-integrity` の形で片付ける

- 指摘: `ci.yml` の `ignored-tests` job は `continue-on-error: true` で、issue `2026-07-26-bug-ignored-tests-job-permanently-red` の集計 (直近 12 run) では ubuntu / macOS とも 100% fail。flaky ではなく恒常 red で、ubuntu 側は毎回 31.0s = テスト内 deadline hang、macOS 側は 0.14〜0.28s で即死する決定的失敗。issue は wip (8/21) だが 8/24 に「flaky サンプル 4 件目」を追記して止まっている。他に `06-02 flaky-serve-propagates-child-exit-code`、`07-03 macos-ci-flaky-pty-tests`、`07-25 flaky-serve-ro-lock-acquire-rejected` が open。今日常時ロードへ昇格した `test-integrity` の最大の違反者が、検証主義を CLAUDE.md に掲げる主力プロダクト
- 修正案: (1) `continue-on-error` を外す。緑を作るために外すのではなく、red を見えるようにするため。(2) 恒常 fail の固定 2 本 (`serve_backpressure_disconnects_slow_client` / `notify_default_does_not_resume_self_stopped_child`) は `#[ignore = "<理由 + issue ref>"]` で明示 skip にして、ignored job が「本当に flaky なもの」だけを回す状態に戻す。(3) 4 本の issue それぞれに `reference/testing/flaky-accountability` の 5 項目を埋める作業を worker (opus-high、実機必須なので macOS 側は kawaz 手元) に委譲。埋まらないものは「調査未完了」として真因調査に戻す。順番は (1)(2) を先に (gate として復活させる)、(3) はその後

### H-2 ★1 open issue 42 本の棚卸し (注記: 停滞は目的達成による優先順位低下。kawaz 談)

- 指摘: 8/25 以降更新なし。ccmsg v2 が `hyoui input` に依存し始めたので、hyoui の停滞は ccmsg に波及する
- 修正案: 42 本を「ccmsg v2 が必要とするもの / それ以外」で 2 値に仕分け (sonnet-medium で足りる)。前者だけを hyoui の次の作業単位にする

### H-8 ★1 README の位置付けを「ccmsg の実行基盤」に更新する

- 判明: hyoui の元々の目的「claude の TUI からの解放」は、TTY 分離 / detach・attach の安定 / webui / embed モードまで到達して達成。今は ccmsg の webui から new / continue / resume / fork を起動する launcher (`direnv exec "$CWD" hyoui run --detached -- claude …`) の裏で動く実行基盤で、hyoui を直接触ることは無くなった。単品の出来は本人も「雑にも程がある」と認めた上で、優先順位が下がっている
- 指摘: README は「`claude` / REPL / TUI を外側から CLI で」と単品ツールとして書かれ、ccmsg との関係 (launcher から呼ばれる、`hyoui input` が配送経路、embed モードが webui に載る) が無い。後発 (ccmsg v2 の launcher 設定を読む人) が hyoui の役割を README から掴めない
- 修正案: README の Status に「現在の主用途: ccmsg のセッション実行基盤 (launcher / input / embed)。単品 CLI としての改善は優先度低」を 1 段落。H-2 の仕分け (ccmsg が必要とするもの / それ以外) はこの位置付けを前提にする

### H-3 ★1 [時期: ccmsg 安定後] daemon/service 体系のバックポート (訂正)

- 訂正: v2 で「独自体系」と書いたが、DR-0031 で `hyoui web service register|unregister|status` が既にあり、常駐 (web gateway) 側は reference の `service` 体系にほぼ準拠している。差分は (a) `web service` → `service` への命名 (unit = web gateway 1 つなので `<tool> service` で足りる)、(b) `daemon` 系 (`run --detached` / `list` / `status` / `kill`) は unit = PTY session で reference の「1 instance = 1 unit」に乗るが、`supervise` (落ちたら上げる) は子プロセス寿命に従属するので適用外
- 修正案 (裁定待ち): reference の `cli-daemon-subcommands` に「unit の寿命が外部要因 (子プロセス) に従属する場合、`supervise` は対象外」を適用範囲として 1 行足す。hyoui 側は `web service` → `service` の改名だけを issue 化し、R-12 の表へ

### H-4 ★2 CLAUDE.md を rules-personal の再編に追随させる

- 指摘: CLAUDE.md (6.6KB、常時ロード) の「jj-workflow」節が `~/.claude-personal/rules/jj-workflow.md` / `jj-tips.md` を参照しているが、今日の再編で両方とも `reference/vcs/` に移設済み = dead reference。同節の「git bare + jj workspace 方式」は旧方式で、`vcs-guide.sh` が colocate 化を促す対象。「push」「言語」節は rules-personal の `push-workflow` / hook と重複。「検証主義」「撤退判断は最後の手段」も `empirical-verification` / `retreat-is-last-resort` と重複
- 修正案: hyoui 固有の内容だけ残す: hyoui とは / 必読 DR 表 / 介入判断 self-check / 3 category 検証 / 観測コマンド表 / partial state の規律 / Anti-patterns / 道具揃った段階の運用。「jj-workflow」「push」「言語」節は削除し rules-personal (hook + rule) に任せる。「検証主義」節は hyoui 固有部分 (3 category、マトリクス) だけ残し、一般論は rule への 1 行参照に。併せて colocate 化 (`docs/issue/2026-08-21-colocate` の対象)。約 2KB 減る見込み

### H-5 ★2 DR INDEX の Status 列から経緯を抜く

- 指摘: Status 列が「🟡 部分実装 (Phase A/B + scrollback layer 完了、Phase C 残: observe mode / multi-client resize モード / reflow / zstd 等)」「🚧 Active (2026-07-03、review 2 巡反映済 = 1 巡目 codex + ultracode 8 観点、2 巡目 ultracode 4 観点 + finding 別反…)」のように改訂履歴を抱えていて、`no-historical-noise` の history narrative そのもの。INDEX が 1 行 200 字を超えて一覧として読めない
- 修正案: Status 列は「ラベル + 最終判定日」だけ (例: `🟡 部分 (2026-08-21)`)。残りの経緯は各 DR 本文の Status 節に移す (既にある DR はそこへ寄せるだけ)。説明列も 1 文に。この Status 列の仕組み自体は良いので、rules-personal の `docs-authoring/templates/decisions/INDEX.template.md` に Status 列を足して他リポへ横展開する価値がある (裁定待ち)

### H-6 ★1 `docs/REVIEW-BACKLOG.md` の来歴節と `/tmp` symlink 互換

- 指摘: 619 行。「来歴」節 (Round 4 が `Prompt is too long` で落ちた経緯、Codex が jj を認識できなかった件) は journal 向きの narrative。`/tmp/itumono-backlog-hyoui.md` symlink は itumono skill の規約に依存しているが、その skill は今日の再編で `skills/itumono-*` に残ったので互換は生きている。ただし規約が `/tmp` 固定なのは再起動で消える
- 修正案: 来歴節を `docs/journal/2026-05-27-review-backlog-migration.md` へ移す。`/tmp` 互換は itumono skill 側で `docs/REVIEW-BACKLOG.md` を正本として読むよう規約を変え (rules-personal 側の変更)、symlink を廃止

### H-7 ★2 [時期: ccmsg 安定後] DR-0028 (daemon graceful upgrade) の優先順位を ccmsg 依存の観点で決め直す

- 指摘: DR-0028 は 7/21 起草・方式裁定済み・未実装 (Open Questions 3 件)。ccmsg v2 が `hyoui input` でセッションへ注入する構成になると、hyoui の upgrade でセッションが落ちる = ccmsg の配送が止まる。今は brew upgrade + gateway 再起動が前提 (QUESTIONS の LINK-C1)
- 修正案: H-2 の仕分けで「ccmsg v2 が必要とするもの」に入れるかを先に決める。入れるなら Open Questions 3 件を裁定して着手、入れないなら DR に「ccmsg 側は hyoui 再起動を許容する (再接続で復帰)」と前提を書き、ccmsg の DESIGN §8 と整合を取る
