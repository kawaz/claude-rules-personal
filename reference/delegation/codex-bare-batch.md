# codex を `~/.claude-bare` 経由の `claude -p` で使う (大入力バッチ経路)

## いつ使うか

codex 系の委譲はまず agent preset (`codex-sol-worker` / `codex-sol-reviewer`) を検討する。preset の実効 context は ~120k (200k − subagent ベースライン注入 ~67-77k)。**入力がそれを超える時だけ**本経路に切り替える。`~/.claude-bare` 経由の開始時消費は ~17k (実測 17,357 tokens、フル tool set 込み) で、window は 1M として認識される (272K 超は割増帯)。

`~/.claude-bare` は gateway 認証と 1M context env だけを持つ最小構成の `CLAUDE_CONFIG_DIR` (agents 無し、plugin は ccmsg のみ)。`--bare` フラグと違って settings.json の env が読まれるので、auth env や `CLAUDE_CODE_MAX_CONTEXT_TOKENS` を毎回明示する必要がない。

## 定型コマンド

```bash
SP=<scratchpad>   # prompt/結果の置き場。セッションの scratchpad を使う
(cd <repo> && \
  CLAUDE_CONFIG_DIR="$HOME/.claude-bare" \
  claude -p --model gpt-5.6-sol \
  < "$SP/prompt.md" > "$SP/result.md" 2>&1)
```

- model は用途で選ぶ: `gpt-5.6-sol` (レビュー・監査・高難度) / `gpt-5.6-terra` (通常) / `gpt-5.6-luna` (軽量)
- 272K 超入力は割増料金 (入力 2 倍・出力 1.5 倍が全体に掛かる) — 割増後 sol ≒ fable 通常価格なので許容、割増帯を使う時はその旨を一言添える。実測の詳細は `docs/findings/2026-07-15-context-limits-and-agent-baseline-tokens.md`
- 長い入力は必ずファイル (`prompt.md`) に書いて stdin リダイレクトで渡す (引数渡しは shell 引用の事故源)
- 実行は Bash tool の `run_in_background: true` が基本 (数分かかる)。完了通知後に `result.md` を Read で回収
- stderr に `[claude-code:unrecognized_model]` が 1 行出るが動作に影響しない (gateway 側モデルを Claude Code が内蔵表に持たないだけ)

## 必須の注意点

1. **read-only 縛りは `--disallowedTools Edit,Write,Bash`**。`--allowedTools Read,Glob,Grep` は「確認なし許可」リストであって制限では**ない** (Edit で普通に書けてしまう)。レビュー等で書き込みを禁じたい時は disallow 側で縛る
2. **kawaz ルール群 (rules-personal plugin) は届かない**。cwd のプロジェクト CLAUDE.md は通常どおり読まれるが、sanitize / 禁則が絡む出力 (commit message 案・公開文書) を書かせる場合は、必要な制約を prompt.md に明記する
3. **面の認証境界**: `~/.claude-bare` は personal 面の gateway namespace を向く。業務リポの内容を渡す用途には使わない

## prompt.md の型

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

## effort は gateway 越しでも効く (実測)

thinking budget 1024 vs 32000 で重い推論問題を比較 → output 925 vs 2,383 tokens (2.6 倍差)。budget → reasoning_effort 変換が upstream まで届いている。agent frontmatter の `effort` も同経路で有効。effort は「上限」であって強制消費ではない (簡単な問題では budget を上げても消費が増えない)。

## token 実測の根拠 (同一 ping タスク比較)

| 経路 | 開始時消費 |
|---|---|
| `CLAUDE_CONFIG_DIR=~/.claude-bare claude -p` | **~17k** (17,357) |
| Explore (built-in) | ~37k |
| custom agent preset | ~67-90k |

subagent 側の注入 (~67k) の正体はツールスキーマ + ハーネス機構で、CLAUDE.md ではない (CLAUDE.md 無し環境でも 67k を実測)。frontmatter でこれを削る手段は無い (`omitClaudeMd` はユーザ agent では無効を実測) ため、大入力の逃げ道は本経路のみ。
