# エージェント実行環境の運用

- [event-driven-alternatives](event-driven-alternatives.md) — sleep / polling の代替 primitive を言語・環境別に引き、正当な例外 4 種を判定する。
  sleep で待つ, polling, event-driven, 完了を待つ, Monitor tool, fswatch, inotify, wait $pid
- [playwright-chrome-profiles](playwright-chrome-profiles.md) — playwright-cli を Chrome Beta の複数プロファイルに attach する手順と後始末・トラブル対処。
  playwright-cli, PLAYWRIGHT_MCP_EXTENSION_TOKEN, Chrome プロファイル, ブラウザ自動化, attach --extension, タブグループ, Playwright Extension
- [agy-cli](agy-cli.md) — `agy -p` で Gemini 等の別のモデルに非対話で仕事を出す時の、オプション・権限・落とし穴・ログの見方。
  agy, Antigravity, Gemini, carbon, neon, 別のモデルに出す, agy -p, --add-dir, accept-edits, no output produced, Individual quota reached, CancelCascadeInvocation, run_workflow, stream-json, json-schema
- [auto-mode-classifier](auto-mode-classifier.md) — auto で始まるモデル、classifier が読むもの、`autoMode` の 4 区分、プロジェクト固有の完全一致 allow (`settings.local.json`)、誤拒否の直し方。
  auto mode, classifier, Blocked by classifier, This command requires approval, auto に入らない, Manual で始まる, haiku, canEnterAuto=false, server_no_result, We're changing auto mode, billed classifier, removes this fallback, Credential Materialization, Secret-Store Writes, autoMode, environment, allow, soft_deny, hard_deny, /auto-mode-setup, settings.local.json, permissions.allow, 完全一致, Edit(//, ~/ と / の違い, symlink の綴り, 誤拒否
