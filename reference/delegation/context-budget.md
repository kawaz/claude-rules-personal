# context 配分 — 経路ごとの実効入力余地と、超えた時の経路

model×effort と同時に「タスクが運ぶ入力量 vs 経路の余地」を見積もる。委譲の context 超過死 (Prompt is too long) はモデル選定が正しくても起きる。

## 経路ごとの実効入力余地 (実測)

| 経路 | 上限 | ベースライン注入 | 実効余地 |
|---|---|---|---|
| claude 系 worker `[1m]` (sonnet/opus preset) | 1M | ~70-90k | ~900k |
| fable (メイン/subagent) | 1M | メインはルール類で大 | 大 |
| codex (preset / 対話) | 1M (272K 超は割増) | preset ~67-77k | 割増境界まで ~200k |
| codex 大入力経路 (`CLAUDE_CONFIG_DIR=~/.claude-bare claude -p`) | 同上 | ~17k | 割増境界まで ~250k |
| Explore (built-in、読み取り調査) | 継承 | ~37k | 広い |

subagent 側の注入 (~67k) の正体はツールスキーマ + ハーネス機構で、CLAUDE.md ではない。frontmatter で削る手段は無い (`omitClaudeMd` はユーザ agent では無効)。

## 見積り式

委譲プロンプト + 対象ファイル群 + 作業中の Read/Grep 蓄積 (対象の 2-3 倍を見込む) + 報告。合計が実効余地の ~50% を超えるなら、粒度を割るか window の大きい経路へ。

## 割増帯 (272K 超) の扱い

- 200k の壁は Claude Code クライアント側の自己抑制で、`CLAUDE_CODE_MAX_CONTEXT_TOKENS=1000000` (settings.json に常設済み) で解除される。実測の詳細は `docs/findings/2026-07-15-context-limits-and-agent-baseline-tokens.md`
- codex の 272K 超は割増料金 (入力 2×・出力 1.5×、quota にも効く) だが割増後 sol ≒ fable 通常価格なので許容する。割増帯を使う時はその旨を一言添える
- 割増帯のコスト序列: sonnet `[1m]` 割増 < sol 割増 ≒ fable 通常

## codex 大入力経路 (`~/.claude-bare`)

codex 系の委譲はまず agent preset (`worker-sol-high` / `reviewer-sol-high`) を使い、入力が実効余地 ~200k を超える時だけ本経路に切り替える。`~/.claude-bare` は gateway 認証と 1M context env だけを持つ最小構成の `CLAUDE_CONFIG_DIR` (agents 無し、plugin は ccmsg のみ)。

```bash
SP=<scratchpad>   # prompt/結果の置き場
(cd <repo> && \
  CLAUDE_CONFIG_DIR="$HOME/.claude-bare" \
  claude -p --model sol \
  < "$SP/prompt.md" > "$SP/result.md" 2>&1)
```

- model: `sol` / `astra` (高度) / `luna` (軽作業、または xhigh で穴探し)
- 長い入力は必ずファイル (`prompt.md`) に書いて stdin リダイレクトで渡す
- Bash tool の `run_in_background: true` で実行し、完了通知後に `result.md` を Read で回収
- stderr の `[claude-code:unrecognized_model]` 1 行は無害
- read-only 縛りは `--disallowedTools Edit,Write,Bash`。`--allowedTools` は確認スキップリストであって制限ではない
- kawaz ルール群 (rules-personal plugin) は届かない。cwd の CLAUDE.md は読まれる。sanitize / 禁則が絡む出力は prompt.md に制約を明記する

prompt.md の型:

```markdown
# 依頼: <1 行タスク>

## 前提 (kawaz ルール群はこのセッションに届かない。必要な規約をここに書く)
- <リポ規約・出力言語・禁則>

## 対象
<レビュー対象コード・diff・ファイル本文をここに直接貼る>

## 出力形式
- <総評 / Critical / Major / Minor 等、期待する構造>
- 出力はそのまま result.md になる。前置き・後書き不要と明記
```
