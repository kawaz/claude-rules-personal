# context 配分 — 経路ごとの実効入力余地と見積り

model×effort と同時に「タスクが運ぶ入力量 vs 経路の余地」を見積もる。委譲の context 超過死 (Prompt is too long) はモデル選定が正しくても起きる。

## 経路ごとの実効入力余地 (実測)

| 経路 | 上限 | ベースライン注入 | 実効余地 |
|---|---|---|---|
| claude 系 worker `[1m]` (sonnet5/opus5 preset) | 1M | ~70-90k | **~900k** |
| fable (メイン/subagent) | 1M | メインはルール類で大 | 大 |
| codex (preset / 対話。MAX_CONTEXT_TOKENS=1M 常設済) | 1M (272K 超は割増) | preset ~67-77k | 割増境界まで **~200k** |
| codex bare batch (`CLAUDE_CONFIG_DIR=~/.claude-bare claude -p`) | 同上 | ~17k | ~250k (割増境界まで) |
| Explore (built-in、読み取り調査) | 継承 | ~37k | 広い |

## 見積り式

委譲プロンプト + 対象ファイル群 + 作業中の Read/Grep 蓄積 (対象の 2-3 倍を見込む) + 報告。**合計が実効余地の ~50% を超えるなら、粒度を割るか window の大きい経路へ**。実例として、13 issue の一括棚卸しは 200k で死亡し、4 issue × 3 分割で完走した。

## 割増帯 (272K 超) の扱い

- codex の 272K 超は割増料金 (入力 2×・出力 1.5×、quota にも効く) だが**割増後 sol ≒ fable 通常価格**なので許容する。割増帯が必要な構成はその旨を一言添えて進める
- 割増帯のコスト序列: sonnet5 `[1m]` 割増 < sol 割増 ≒ fable 通常。200k 超の大 context 帯で最安の高品質枠は sonnet5 `[1m]`
- codex に大入力を渡す時の経路切替 (preset → `~/.claude-bare` 経由の `claude -p`) と `CLAUDE_CODE_MAX_CONTEXT_TOKENS` による 200k 解除 (壁はクライアント自己抑制、272K 超は割増料金) は reference の `delegation/codex-bare-batch` が正本
