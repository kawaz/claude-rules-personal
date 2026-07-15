# CLIProxyAPI 運用と codex レビューの意味

kawaz の Mac には CLIProxyAPI (サブスク認証を OpenAI/Claude 互換 API 化するローカルプロキシ) が 2 インスタンス常駐している。

| 面 | endpoint | config | 常駐 |
|---|---|---|---|
| 個人 | `127.0.0.1:8317` | `~/.config/cliproxyapi/personal.yaml` | brew services |
| emeradaco | `127.0.0.1:8318` | `~/.cli-proxy-api-emeradaco/config.yaml` | LaunchAgent `com.kawaz.cliproxyapi-emeradaco` |

## 使い方

- **通常の `claude` 起動で自動的にプロキシ経由**になる (`~/.claude-{personal,emeradaco}/settings.json` の env に `ANTHROPIC_BASE_URL` 込み)。面切替は `CLAUDE_CONFIG_DIR` (direnv で emeradaco 配下に入ると自動で 8318 に切替)
- プロキシは 127.0.0.1 のみバインドで api-keys は空 (ローカル信頼、`ANTHROPIC_AUTH_TOKEN` 不要)。副作用として claude.ai MCP コネクタは無効化される (kawaz は未使用のため許容)
- 公開モデル: claude 系 `claude-{opus-4-7,sonnet-5,fable-5,haiku-4-5-*}` (+`[1m]` 可)、個人面のみ `-zun` / `-gmail` variant (アカウントピン留め、素の名前はレート時自動 failover のプール)、codex 系 `gpt-5.6-{terra,sol,luna}` (通常/ハイエンド/軽量)
- codex の effort は Claude の thinking budget から自動変換 (1024/4000/16000/32000 → low/medium/high/xhigh)。OpenAI 互換経路なら `reasoning_effort` パラメータ直指定
- `/model` 一覧は gateway discovery (`CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1`、ラッパに焼き込み済) がプロキシから自動取得

## 「codex レビュー」の意味 (再定義)

「codex にレビューさせて」「codex の意見」等は **CLIProxyAPI 経由で codex モデルに依頼する**ことを指す。レビュー・監査は `gpt-5.6-sol`、軽い二次意見は `gpt-5.6-terra`。

### codex worker の preset と context 制約

codex は agent 定義 preset で使う: `codex-sol-reviewer` (レビュー特化) / `codex-sol-worker`
(高難度実作業) / `codex-terra-worker` (通常作業・二次意見) / `codex-luna-worker` (軽量定型)。

**モデル特性** (GPT-5.6 GA、gihyo.jp 2026-07 記事より): sol = フラッグシップ (コーディングも
SOTA 級、`gpt-5.6` 指定時のデフォルト) / terra = GPT-5.5 相当を低コストで (日常業務) /
luna = 高速・大量処理 (Ultra 不可)。effort は low〜xhigh/max (Ultra はプラン限定・
proxy 経由では実質 max まで)。**出力が短くなる傾向があり「簡潔に」系の指示を重ねると
必要な内容まで省略する** — 文字数上限で縛らず「残すべき要素」を指定する。

**context 制約**: GPT-5.6 の素の window は 1.05M (272K 超入力は割増料金境界) だが、
cliproxyapi 経由では 200k に見える。subagent のベースライン注入 (ツールスキーマ +
ハーネス機構、CLAUDE.md 由来ではない) が **~67-77k** (2026-07-15 実測) なので実効
~120k。大入力タスク (数万 token 級のレビュー対象・長大ファイル群) は agent 経由でなく
`claude -p --bare` 経路 (開始時 ~1k) で回す — **手順・罠 (auth env 必須 / tool set は
Bash,Edit,Read 固定 / read-only 縛りは disallowedTools 側) は `codex-bare-batch` skill
が正本**。

**codex plugin (openai/codex-plugin-cc) は廃止済み** — `codex:codex-rescue` subagent や `/codex:*` slash command を使わない。

経路はセッションの起動形態で決まる:

settings.json で常時プロキシ経由なので、AI は `/model gpt-5.6-sol` 切替や subagent 呼び出しで完結する。emeradaco 業務リポは `CLAUDE_CONFIG_DIR=~/.claude-emeradaco` 起動 (direnv で自動) により 8318 側プロキシに流れる — 業務プロンプトを個人面プロキシに流さない、逆も禁止 (= 認証境界)。

## 禁則

- auth-dir 内の OAuth token 値を context・ログに出さない ([[secret-hygiene]])
- `~/.cli-proxy-api` (無印) は perm 000 の罠 regular file。ディレクトリとして作り直さない
- emeradaco 以外の業務アカウントをプロキシに追加しない (サブスク API 転用は ToS グレー、影響範囲を kawaz 管理アカウントに限定する)

## 関連

- [[worker-model-selection]] — Claude 系 worker のモデル選定 (本ルールは codex モデルの経路)
- [[claude-config-dir-isolation]] — 面分離の原則
