---
name: codex-bare-batch
description: codex (gpt-5.6-*) に大入力タスクを claude -p --bare で投げる手順。agent preset (codex-*-worker) の context が足りない時 (レビュー対象が数万 token 級・長大ファイル群) に使う。auth env・tool set・read-only 縛り・出力回収の定型を含む。
---

# codex を claude -p --bare で使う (大入力バッチ経路)

## いつ使うか

codex 系の委譲はまず agent preset (`codex-sol-reviewer` / `codex-sol-worker` /
`codex-terra-worker` / `codex-luna-worker`) を検討する。preset の実効 context は
~120k (200k − subagent ベースライン注入 ~67-77k)。**入力がそれを超える時だけ**
本経路に切り替える。`--bare` の開始時消費は ~1k (2026-07-15 実測 989 tokens) で、
実効 ~199k がプロンプトに使える。

## 定型コマンド

```bash
SP=<scratchpad>   # prompt/結果の置き場。セッションの scratchpad を使う
(cd <repo> && \
  ANTHROPIC_BASE_URL=http://127.0.0.1:8317 ANTHROPIC_AUTH_TOKEN=local \
  CLAUDE_CODE_MAX_CONTEXT_TOKENS=1000000 \
  claude -p --bare --model gpt-5.6-sol \
  < "$SP/prompt.md" > "$SP/result.md" 2>&1)
```

- `CLAUDE_CODE_MAX_CONTEXT_TOKENS`: 200k の壁はクライアント側の自己抑制 (settings.json
  env に 1M 常設済みだが、`--bare` は settings.json を読まないのでここでも明示する)。
  272K 超入力は割増料金 (入力 2 倍・出力 1.5 倍が全体に掛かる) — 割増後 sol ≒ fable
  通常価格なので許容 (kawaz 裁定 2026-07-15)、割増帯を使う時はその旨を一言添える。
  実測の詳細は
  `docs/findings/2026-07-15-context-limits-and-agent-baseline-tokens.md`

- model は用途で選ぶ: `gpt-5.6-sol` (レビュー・監査・高難度) / `gpt-5.6-terra`
  (通常) / `gpt-5.6-luna` (軽量)
- 業務面 (emeradaco) では port を **8318** に変える (認証境界、面ごとの
  proxy 構成は `docs/findings/2026-07-19-cliproxyapi-codex-runtime-notes.md`)
- 長い入力は必ずファイル (`prompt.md`) に書いて stdin リダイレクトで渡す
  (引数渡しは shell 引用の事故源)
- 実行は Bash tool の `run_in_background: true` が基本 (数分かかる)。完了通知後に
  `result.md` を Read で回収

## 必須の注意点 (実測済みの罠、2026-07-15 検証)

1. **auth env は必須**。`--bare` は settings.json の env を読まないため、
   `ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN` を明示しないと
   `Not logged in · Please run /login` で落ちる (OAuth 経路は試されない)
2. **tool set は Bash / Edit / Read の 3 つ固定**。`--allowedTools` を足しても
   増えない (Glob/Grep/Write を指定しても無効)。ただしコード作業はこの 3 つで
   完結する: 検索は Bash 越しの `grep`/`ls`、新規ファイル作成は Edit が兼ねる
3. **read-only 縛りは `--disallowedTools Edit,Write,Bash`**。
   `--allowedTools Read,Glob,Grep` は「確認なし許可」リストであって制限では
   **ない** (Edit で普通に書けてしまうことを実測確認済み)。レビュー等で
   書き込みを禁じたい時は disallow 側で縛る
4. **CLAUDE.md / ルール類は一切注入されない**。リポ規約・前提知識が必要なら
   prompt.md に自分で埋め込む。参照ディレクトリを足す場合は `--add-dir <dir>`
   (bare 時は CLAUDE.md 探索 dir を兼ねる)
5. **kawaz ルール群も届いていない**。sanitize / 禁則が絡む出力 (commit message
   案・公開文書) を書かせる場合は、必要な制約を prompt.md に明記する

## prompt.md の型

```markdown
# 依頼: <1 行タスク>

## 前提 (このセッションには CLAUDE.md が届かない。必要な規約をここに書く)
- <リポ規約・出力言語・禁則>

## 対象
<レビュー対象コード・diff・ファイル本文をここに直接貼る>

## 出力形式
- <総評 / Critical / Major / Minor 等、期待する構造>
- 出力はそのまま result.md になる。前置き・後書き不要と明記
```

## effort は proxy 越しでも効く (2026-07-15 実測)

thinking budget 1024 vs 32000 で重い推論問題を比較 → output 925 vs 2,383 tokens
(2.6 倍差)。budget → reasoning_effort 変換が upstream まで届いている。agent
frontmatter の `effort` も同経路で有効。effort は「上限」であって強制消費ではない
(簡単な問題では budget を上げても消費が増えない)。

## token 実測の根拠 (2026-07-15、同一 ping タスク比較)

| 経路 | 開始時消費 |
|---|---|
| `claude -p --bare` | **~1k** (989) |
| Explore (built-in) | ~37k |
| custom agent preset | ~67-90k |

subagent 側の注入 (~67k) の正体はツールスキーマ + ハーネス機構で、CLAUDE.md では
ない (CLAUDE.md 無し環境でも 67k を実測)。frontmatter でこれを削る手段は無い
(`omitClaudeMd` はユーザ agent では無効を実測) ため、大入力の逃げ道は本経路のみ。

## 関連

- `docs/findings/2026-07-19-cliproxyapi-codex-runtime-notes.md` — codex の経路・面分離・特性メモ
