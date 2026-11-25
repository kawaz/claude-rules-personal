# agy (Antigravity の CLI)

- [headless](headless.md) — `agy -p` と stream-json で非対話に仕事を出す時の、モデル、出力の形、会話の続け方、回の止め方、同じ会話の同時オープン、cache の寿命、失敗の見分け方、ログ。
  agy, Antigravity, Gemini, carbon, neon, agy -p, --output-format json, stream-json, --input-format, json-schema, structured_output, --conversation, conversation_id, not found, 中断, abort, SIGINT, SIGTERM, interrupted, 同時に開く, cache_read_tokens, cache の TTL, no output produced, Individual quota reached, 429, print timeout, DEADLINE_EXCEEDED, Please sign in
- [permissions](permissions.md) — モードごとにできること、特定のコマンドだけ許す `--settings`、効かない `--sandbox`、書ける範囲の囲い方、入力を守る。
  accept-edits, --mode plan, --mode auto is not available, --dangerously-skip-permissions, --settings, command(, permissions.allow, --sandbox, sandbox-exec, execvp, Operation not permitted, proceed-in-sandbox, --add-dir, コンテナ
- [agents](agents.md) — agent の定義 (`.agents/agents/`、frontmatter の `tools`)、`--agent`、組み込みの subagent、`run_workflow`、`agy acp`、`--remote-agent`。
  --agent, unknown agent, agy agents, .agents/agents, frontmatter, tools, run_command, commandExecutionPolicy, invoke_subagent, research, run_workflow, RunWorkflow, CancelCascadeInvocation, acp, --remote-agent
- [from-claude-code](from-claude-code.md) — Claude Code のセッションから agy を回す時の使い道と、classifier に止められない固定コマンドの台 (`scripts/exp-run.sh`)。
  Claude Code から agy, Blocked by fast classifier, 完全一致 allow, 固定コマンド, exp-run.sh, agy-exp, 実験, 別の系統のモデル, セカンドオピニオン
