---
name: sloppy-ai-patterns
description: AI の雑対応 anti-pattern (sleep / polling 等) の代替手段カタログと例外判定を確認する時に読む。常時側の症状・自警は sloppy-ai-patterns rule が正。
---

# 雑対応 anti-pattern の代替と例外 (詳細)

症状・自警の正本は sloppy-ai-patterns rule (常時ロード)。本 skill は
「では何を使うか」と「いつなら許されるか」の詳細。

## sleep / polling の代替 (言語 / 環境別の高レベル primitive)

| 環境 | 推奨 |
|---|---|
| shell | `inotifywait` (linux), `fswatch` (macOS), named FIFO `read` で blocking, `wait $pid` で子プロセス終了待ち, signal trap |
| Rust | `tokio::select!`, `notify` crate (file watch), `tokio::sync::Notify`, channel, `signal_hook` |
| JavaScript / Node | `await`, `Promise`, `EventTarget`, `AbortSignal`, `fs.watch` |
| Python | `asyncio` (`await`, `wait_for`), `selectors`, `inotify_simple` |
| Go | channel + `select`, `context.Done()`, `fsnotify` |
| Claude Code 自身 | **Monitor tool** (= `tail -f` + grep / inotify / WebSocket frame 等を event stream として扱える)、`Bash` tool の `run_in_background` + 完了通知 |
| HTTP / API | server-sent events (SSE) / WebSocket / long polling (= server 側で blocking)、純粋ポーリングは最終手段 |

なぜ event-driven に倒すか (rule 側の要約の補足):

- **正解時刻を捉え損ねない**: poll は最大「次の poll 周期」分遅れる。
  event-driven は真の遷移瞬間を観測する
- **CPU/IO トレードオフが消える**: 短間隔 idle 占有 vs 長間隔反応性低下の
  二択自体が無くなる
- **race を見逃さない**: poll 間に「進んで戻った」遷移は poll では観測不能

## sleep / polling が正当な例外

- **真の定期実行**: cron / heartbeat / health probe で「N 秒ごとに状態を
  確認する」が要件そのもの。これは「待ち」ではなく「定期的にやる」で別カテゴリ
- **外部 API がポーリングしか提供してない**: server 側が event push を実装
  してない第三者 API。interval は rate-limit / exponential backoff で正当化し
  根拠を明記
- **テスト中の deterministic sleep**: 時刻依存挙動のテストで明示的に N 秒
  経過後の状態を作る場合 (= 時間そのものが test 入力)
- **debugging で一時的に**: 「とりあえず動かしたい」段階の wip コード。
  commit / push 前に event-driven に置き換える

## 新パターンを本 skill に足すときの様式

「症状 / なぜ駄目 / 代替 / 例外 / AI 自警」の5項で書く。rule 側 (常時) には
症状+自警の ~10 行だけ、代替表と例外は本 skill 側に置く。
