# Claude Code の context 上限と agent 経路別ベースライン token の実測

検証日: 2026-07-15。Claude Code v2.1.210 / cliproxyapi (personal 面 8317) / GPT-5.6 GA 直後。

## 判明した事実

1. **200k の context 壁は Claude Code クライアント側の自己抑制**。proxy (cliproxyapi) にも
   upstream (codex) にも壁は無い。`CLAUDE_CODE_MAX_CONTEXT_TOKENS` env var で解除できる
2. env var は `--bare` 専用ではなく**対話・通常モードでも有効** (input 285k の成功を実測)
3. env var は**全モデル一律**に効く。モデル別に指定する仕組みは無い
4. subagent のベースライン注入 (~67-90k) の正体は**ツールスキーマ + ハーネス機構**で、
   CLAUDE.md/ルール由来ではない (CLAUDE.md 皆無の環境でも 67k)
5. built-in Explore の軽さ (~37k) は lean prompt + tool 削減 + `omitClaudeMd` + gitStatus
   除外の複合。**ユーザ agent の frontmatter からは再現できない** (`omitClaudeMd` を書いても
   無効: バイナリの消費側が `omitClaudeMd && !userContext` 条件で、userContext がある
   環境では常に素通り)
6. `claude -p --bare` の tool set は **Bash/Edit/Read の 3 つ固定**。`--allowedTools` で
   増やせない。`--allowedTools` は read-only 縛りにも**ならない** (allow は確認スキップ
   リスト)。縛りは `--disallowedTools Edit,Write,Bash` が正解 (書き込み拒否を実測)
7. `--bare` は settings.json の env を読まない → `ANTHROPIC_BASE_URL` +
   `ANTHROPIC_AUTH_TOKEN` の明示が必須 (無いと "Not logged in")
8. effort は cliproxyapi 越しでも upstream まで届く (thinking budget → reasoning_effort
   2 段変換)。effort は「上限」であり強制消費ではない
9. GPT-5.6 の素の window は 1.05M。272K は「入力 2 倍・出力 1.5 倍の割増料金境界」で
   あってエラー境界ではない (250k 直投げ HTTP 200)。割増はサブスク quota 消費にも効く

## 実用的な示唆

- 経路選択の数字: `--bare` ~1k / Explore ~37k / custom agent ~67-90k 始まり。
  大入力は bare、読み取り調査は Explore、ツールフル装備の実装は custom agent
- `CLAUDE_CODE_MAX_CONTEXT_TOKENS=1000000` の常設 (settings.json env) は
  「haiku をほぼ使わない + 大 context タスクを滅多にしない」環境ではデメリット実質なし
  (kawaz 裁定 2026-07-15 で常設化)。理論上のリスク: 200k モデルで auto-compact 不発 →
  API エラー / codex で 272K 割増帯への突入 — 後者は割増後 sol ≒ fable 通常価格なので
  許容と裁定済み (割増帯を使う時は一言添える運用)
- 割増帯 (272K 超) のコスト序列: sonnet5 `[1m]` 割増 < sol 割増 ≒ fable 通常

## 検証の詳細

### 同一 ping タスクの開始時 context 消費 (経路マトリクス)

| 経路 | model | tokens | 備考 |
|---|---|---|---|
| `claude -p --bare` (proxy env 明示) | gpt-5.6-luna | 989 | tools は Bash/Edit/Read の 3 つ |
| Explore (built-in) | haiku 4.5 | 36,632 | stream-json の task_notification で観測 |
| custom probe 最小定義 (headless, CLAUDE.md 無し) | gpt-5.6-luna | 67,417 | |
| custom probe + `omitClaudeMd: true` | gpt-5.6-luna | 67,400 | 差 −17 ≈ ノイズ = 無効 |
| custom probe 最小定義 | haiku 4.5 | 90,319 | 同一ハーネスで Explore の 2.5 倍 |
| codex-luna-worker (ルール入りセッション) | gpt-5.6-luna | 76,568-76,589 | omit 有無で差なし |

- 対話セッションの Agent tool は custom agent の usage を返すが built-in (Explore) では
  返さない。headless `--output-format=stream-json` の `task_notification.usage.total_tokens`
  なら両方観測できる
- セッション途中に新規追加した agent .md は Agent tool に即時認識されないことがある。
  headless `claude -p --agents '<inline JSON>'` が frontmatter 実験のクリーンな試験管

### 200k 壁の切り分け

| テスト | 結果 |
|---|---|
| proxy `/v1/chat/completions` に 250k token 直 POST | HTTP 200、prompt_tokens 250,318 を正常処理 |
| `--bare` + env var 1M + 240k 入力 | 成功 (input 200,787) |
| 通常モード (`-p`、bare なし) + env var 1M + 285k 入力 | 成功 (input 285,074) |

バイナリ (v2.1.210 Mach-O) の strings から `CLAUDE_CODE_MAX_CONTEXT_TOKENS` を発見して
実地検証した。なお anthropics/claude-code リポは issue+CHANGELOG のみでソース非公開のため、
バイナリ strings 掘りが一次資料になる。

### effort の proxy 越し有効性

Anthropic 互換 `/v1/messages` に thinking budget を変えて投げる:

| 問題 | budget 1024 | budget 32000 |
|---|---|---|
| 簡単 (137×249) | out 36 | out 38 (差なし = 上限であって強制でない) |
| 重い (円卓制約全列挙) | out 925 / thinking 171 chars | out 2,383 / thinking 440 chars (2.6 倍) |

OpenAI 互換 `/v1/chat/completions` の `reasoning_effort` 直指定も疎通確認済み。

### built-in agent 定義 (バイナリ strings より)

- general-purpose: model 指定なし・tools `["*"]`・effort なし (= 全部継承任せ)
- Explore: `model:"inherit"`, Edit/Write 系 6 tool disallow, `omitClaudeMd:!0`,
  lean prompt, gitStatus 除外 (Explore/Plan のみ)
- worker: tools `["*"]`, `maxTurns:200`
