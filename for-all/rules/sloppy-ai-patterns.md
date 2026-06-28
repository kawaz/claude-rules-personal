# AI がやりがちな雑な対応 anti-pattern 集

根本原因への深掘りを放棄して **症状を symptom-fix で誤魔化す** 振る舞いを集めた anti-pattern カタログ。
AI (= Claude) は特にこれらに流れやすい (= triage コストが高い / 退屈な調査を打ち切りたい衝動)。
書きたくなった瞬間が **手抜きシグナル**、深掘り省略の言い訳になっていないか自問する。

各 anti-pattern には:

- **症状**: どの言葉 / 構文を書きたくなった時に発動するか
- **なぜ駄目か**: 根本原因の隠蔽 / 誤魔化しがどう悪さするか
- **代替**: 高レベル primitive / 適切な道具で何ができるか
- **例外**: いつならその anti-pattern 自体が正当か (= `[[self-written-rule-blind-spots]]` 対極視点)
- **AI 自警**: 書きたくなった瞬間の自問

を揃える。

## sleep / polling で時間待ち

### 症状

```bash
sleep 5; check_ready          # shell: 「とりあえず 5 秒待つ」
while ! is_ready; do sleep 1; done  # bash: 1 秒間隔でポーリング
for i in 1..N: time.sleep(...)      # python: 同上
setTimeout(check, 500)               # JS: setTimeout で「そろそろ来てるはず」
```

### なぜ駄目か

- **間隔の根拠がない**: 5 秒 / 1 秒 / 500ms といった値は経験則で、対象の実態と無関係。早すぎれば false negative (= 未準備で測定)、遅すぎれば wall-clock 浪費 / SIGTERM 等で外側 timeout
- **正解時刻を捉え損ねる**: 真の準備完了瞬間を観測しておらず、最大「次の poll 周期」分遅れる
- **CPU/IO 浪費**: 短間隔だと idle 占有、長間隔だと反応性低下のトレードオフ、event-driven なら両方ゼロ
- **race**: poll の間に状態が変わって戻ったケース (= 進んでから戻った) は捉えられない、event-driven なら全 transition を観測

### 代替 (= 各言語 / 環境の高レベル primitive)

| 環境 | 推奨 |
|---|---|
| shell | `inotifywait` (linux), `fswatch` (macOS), named FIFO `read` で blocking, `wait $pid` で子プロセス終了待ち, signal trap |
| Rust | `tokio::select!`, `notify` crate (file watch), `tokio::sync::Notify`, channel, `signal_hook` |
| JavaScript / Node | `await`, `Promise`, `EventTarget`, `AbortSignal`, `fs.watch` |
| Python | `asyncio` (`await`, `wait_for`), `selectors`, `inotify_simple` |
| Go | channel + `select`, `context.Done()`, `fsnotify` |
| Claude Code 自身 | **Monitor tool** (= 既に道具がある、`tail -f` + grep / inotify / WebSocket frame 等を event stream として扱える)、`Bash` tool の `run_in_background` + 完了通知 |
| HTTP / API | server-sent events (SSE) / WebSocket / long polling (= server 側で blocking)、純粋ポーリングは最終手段 |

### 例外 (= sleep / polling が正当な場面)

- **真の定期実行**: cron / heartbeat / health probe で「N 秒ごとに状態を確認する」が要件そのものの場合。これは「待つ」ではなく「定期的にやる」、別カテゴリ
- **外部 API がポーリングしか提供してない**: server 側が event push を実装してない第三者 API。この場合は **interval を rate-limit / exponential backoff** で正当化し、根拠を明記
- **テスト中の deterministic sleep**: 時刻依存挙動のテストで、明示的に N 秒経過後の状態を作る場合 (= 時間そのものが test 入力)。これも「待ち」ではなく「時間を入力に渡す」
- **debugging で一時的に**: 「とりあえず動かしたい」段階の wip コード、commit/push 前に event-driven に置き換える

### AI 自警

「`sleep N` してから確認」「`while true; do ...; sleep ...; done`」と書きたくなった瞬間に:

1. その対象の状態変化を **直接通知してくれる primitive** はないか?
2. 言語 / 環境の **event-driven 抽象** (= 上表) を 1 度は探したか?
3. ポーリング interval の値に **根拠**を言えるか? (= 言えないなら勘で書いてる)

「ポーリングしか方法ない」と結論する前に 1 度は代替を探す。**Claude Code 自身の作業では Monitor tool が既に提供されている**、それを使わず Bash の `sleep` ループを書いたら原則 anti-pattern。

## 他に発見した anti-pattern の扱い

新しい AI 雑対応パターンに気づいたら、本 rule の追加検討対象。
ただし無制限に積むと常時 load サイズが肥大するので **閾値判断**:

- **追加して本 rule に収まる範囲なら追加** (= 各 pattern が「症状 / なぜ駄目 / 代替 / 例外 / AI 自警」5 項で記述できる程度に独立してる)
- **本 rule が肥大して常時 load を圧迫したら skill 化を検討** ([[rule-writing-guidelines]] 参照、目安は file 全体が常時 load に対して重く感じ始めたタイミング、数値閾値は持たない)
- **既に専用 rule がある anti-pattern は重複させない**、link で済ます:
  - **flaky 即断 / test timeout 延長で逃げる**: [[test-failure-no-tampering]] 「flaky と呼ぶ前の説明責任」セクション参照
  - **撤退 / 機能削除で逃げる**: [[retreat-is-last-resort]]
  - **テスト改変で green を偽装する**: [[test-failure-no-tampering]]
  - **言語 default に無自覚に流れる**: [[default-convergence-guard]]

## Why

- AI は **triage コストが高い** (= 長い調査 chain が context を圧迫する) ので、symptom-fix で **早く終わらせたい衝動** が強い
- 結果として「動いてるように見える」コードが残り、後続セッション / 別エンジニア / ユーザに bug を引き継ぐ
- 雑対応の言葉 (= 「とりあえず sleep」「flaky だから skip」「timeout 延ばす」「try-catch で何とか」) は **思考停止のシグナル**、AI 自身がそれを意識する必要がある
- kawaz スタンス: **手抜きで蓋をするくらいなら、調査未完了として可視化する方が誠実**

## 関連

- [[empirical-verification]] — 観測道具で実体確認 (= 推測ベースで sleep 間隔決めない)
- [[retreat-is-last-resort]] — 撤退判断は最後の手段 (= symptom-fix で逃げない)
- [[test-failure-no-tampering]] — flaky / timeout 延長 / test 改変の anti-pattern
- [[design-priority]] — 設計が正しいかをまず疑う (= sleep が必要に見えるのは設計の不整合の徴候かも)
- [[self-written-rule-blind-spots]] — 片面 rule の警戒 (= 本 rule も「例外」を明示することで両面化)
