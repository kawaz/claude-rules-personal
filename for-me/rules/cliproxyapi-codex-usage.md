# CLIProxyAPI 運用と codex レビューの意味

kawaz の Mac には CLIProxyAPI (サブスク認証を OpenAI/Claude 互換 API 化するローカルプロキシ) が 2 インスタンス常駐している。

| 面 | endpoint | apikey | config | 常駐 |
|---|---|---|---|---|
| 個人 | `127.0.0.1:8317` | `~/.cli-proxy-api-personal/apikey` | `~/.config/cliproxyapi/personal.yaml` | brew services |
| emeradaco | `127.0.0.1:8318` | `~/.cli-proxy-api-emeradaco/apikey` | `~/.cli-proxy-api-emeradaco/config.yaml` | LaunchAgent `com.kawaz.cliproxyapi-emeradaco` |

## 使い方

- 対話起動は `claude-proxy` (zsh 関数、`~/.config/zsh/rc.d/cliproxy.zsh`)。`CLIPROXY_FACE=emeradaco` で面切替
- 公開モデル: claude 系 `claude-{opus-4-7,sonnet-5,fable-5,haiku-4-5-*}` (+`[1m]` 可)、個人面のみ `-zun` / `-gmail` variant (アカウントピン留め、素の名前はレート時自動 failover のプール)、codex 系 `gpt-5.6-{terra,sol,luna}` (通常/ハイエンド/軽量)
- codex の effort は Claude の thinking budget から自動変換 (1024/4000/16000/32000 → low/medium/high/xhigh)。OpenAI 互換経路なら `reasoning_effort` パラメータ直指定
- `/model` 一覧は gateway discovery (`CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1`、ラッパに焼き込み済) がプロキシから自動取得

## 「codex レビュー」の意味 (再定義)

「codex にレビューさせて」「codex の意見」等は **CLIProxyAPI 経由で codex モデルに依頼する**ことを指す。レビュー・監査は `gpt-5.6-sol`、軽い二次意見は `gpt-5.6-terra`。

**codex plugin (openai/codex-plugin-cc) は廃止済み** — `codex:codex-rescue` subagent や `/codex:*` slash command を使わない。

AI からの実行経路 (headless claude をプロキシに向ける):

```bash
ANTHROPIC_BASE_URL=http://127.0.0.1:8317 \
ANTHROPIC_AUTH_TOKEN=$(cat ~/.cli-proxy-api-personal/apikey) \
claude -p --model gpt-5.6-sol "<対象パス/diff を含むレビュー依頼>"
```

対象リポを cwd にして実行すればファイル参照可。emeradaco 業務リポのレビューは 8318 + emeradaco 側 apikey に差し替える (業務プロンプトを個人面プロキシに流さない、逆も禁止 = 認証境界)。

## 禁則

- apikey / auth-dir 内の token 値を context・ログに出さない ([[secret-hygiene]])
- `~/.cli-proxy-api` (無印) は perm 000 の罠 regular file。ディレクトリとして作り直さない
- emeradaco 以外の業務アカウントをプロキシに追加しない (サブスク API 転用は ToS グレー、影響範囲を kawaz 管理アカウントに限定する)

## 関連

- [[worker-model-selection]] — Claude 系 worker のモデル選定 (本ルールは codex モデルの経路)
- [[claude-config-dir-isolation]] — 面分離の原則
