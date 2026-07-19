# CLIProxyAPI × codex 実行環境メモ

旧 `cliproxyapi-codex-usage` rule (2026-07-19 削除) からの知見保存。常時ロード
不要と判断 (agents の description に codex 名があるため rule 側で解説する必要
なし)。ただし後続セッション向けに事実は残しておく。

## 判明した事実

### CLIProxyAPI インスタンス構成

kawaz の Mac には CLIProxyAPI (サブスク認証を OpenAI/Claude 互換 API 化する
ローカルプロキシ) が 2 インスタンス常駐:

| 面 | endpoint | config | 常駐 |
|---|---|---|---|
| 個人 | `127.0.0.1:8317` | `~/.config/cliproxyapi/personal.yaml` | brew services |
| emeradaco | `127.0.0.1:8318` | `~/.cli-proxy-api-emeradaco/config.yaml` | LaunchAgent `com.kawaz.cliproxyapi-emeradaco` |

### 使い方の要点

- **通常の `claude` 起動で自動的にプロキシ経由**になる (`~/.claude-{personal,emeradaco}/settings.json` の env に `ANTHROPIC_BASE_URL` 込み)
- 面切替は `CLAUDE_CONFIG_DIR` (direnv で emeradaco 配下に入ると自動で 8318 に切替)
- プロキシは 127.0.0.1 のみバインドで api-keys は空 (ローカル信頼、`ANTHROPIC_AUTH_TOKEN` 不要)
- 副作用として claude.ai MCP コネクタは無効化される (kawaz は未使用のため許容)

### 公開モデル

- claude 系: `claude-{opus-4-7,sonnet-5,fable-5,haiku-4-5-*}` (+`[1m]` 可)
- 個人面のみ `-zun` / `-gmail` variant (アカウントピン留め、素の名前はレート時自動 failover のプール)
- codex 系: `gpt-5.6-{terra,sol,luna}` (通常/ハイエンド/軽量)
- codex の effort は Claude の thinking budget から自動変換 (1024/4000/16000/32000 → low/medium/high/xhigh)
- OpenAI 互換経路なら `reasoning_effort` パラメータ直指定
- `/model` 一覧は gateway discovery (`CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1`、ラッパに焼き込み済) がプロキシから自動取得

### codex モデル特性 (GPT-5.6 GA、gihyo.jp 2026-07 記事より)

- **sol**: フラッグシップ (コーディングも SOTA 級、`gpt-5.6` 指定時のデフォルト)
- **terra**: GPT-5.5 相当を低コストで (日常業務)
- **luna**: 高速・大量処理 (Ultra 不可)
- effort は low〜xhigh/max (Ultra はプラン限定・proxy 経由では実質 max まで)
- **出力が短くなる傾向があり「簡潔に」系の指示を重ねると必要な内容まで省略する** — 文字数上限で縛らず「残すべき要素」を指定する

### context 制約

- `CLAUDE_CODE_MAX_CONTEXT_TOKENS=1000000` を settings.json env に**常設済み** (kawaz 裁定 2026-07-15) — codex でも 200k を超えて使える
- **272K 超の入力は割増料金** (入力 2 倍・出力 1.5 倍がリクエスト全体に掛かり、quota 消費にも効く)。ただし割増後の sol ≒ fable 通常価格なので許容範囲 (kawaz 裁定 2026-07-15) — 270K 超が必要な作業を組む時は「このタスクは割増帯 (fable 級コスト)」と一言添えて進めれば OK、停止して確認までは不要
- subagent 経路はベースライン注入 ~67-77k で実効 ~120k のまま (常設 env は subagent の注入を減らさない)
- 大入力は `claude -p --bare` 経路 (開始時 ~1k) — 手順・罠は `codex-bare-batch` skill が正本
- 実測の根拠・切り分けの詳細は `docs/findings/2026-07-15-context-limits-and-agent-baseline-tokens.md`

### 経路の選び方

- settings.json で常時プロキシ経由なので、AI は `/model gpt-5.6-sol` 切替や subagent 呼び出しで完結
- emeradaco 業務リポは `CLAUDE_CONFIG_DIR=~/.claude-emeradaco` 起動 (direnv で自動) により 8318 側プロキシに流れる — 業務プロンプトを個人面プロキシに流さない、逆も禁止 (= 認証境界)

## 実用的な示唆

- 「codex にレビューさせて」「codex の意見」等は CLIProxyAPI 経由で codex モデルに依頼することを指す (agent 定義: `codex-sol-reviewer` / `codex-sol-worker` / `codex-terra-worker` / `codex-luna-worker`)
- レビュー・監査は `gpt-5.6-sol`、軽い二次意見は `gpt-5.6-terra`
- codex plugin (`openai/codex-plugin-cc`) は廃止済み — `codex:codex-rescue` subagent や `/codex:*` slash command を使わない

## 禁則 (この findings の適用範囲での注意)

- auth-dir 内の OAuth token 値を context・ログに出さない (secret-hygiene rule)
- `~/.cli-proxy-api` (無印) は perm 000 の罠 regular file。ディレクトリとして作り直さない
- emeradaco 以外の業務アカウントをプロキシに追加しない (サブスク API 転用は ToS グレー、影響範囲を kawaz 管理アカウントに限定する)

## 関連

- `worker-fleet` skill — codex 系 preset の使い分けと context 見積り
- `codex-bare-batch` skill — 大入力を渡す時の経路切替 (preset → bare)
- `claude-config-dir-isolation` rule — 面分離の原則
- `docs/findings/2026-07-15-context-limits-and-agent-baseline-tokens.md` — context 実測
