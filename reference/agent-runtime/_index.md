# エージェント実行環境の運用

- [event-driven-alternatives](event-driven-alternatives.md) — sleep / polling の代替 primitive を言語・環境別に引き、正当な例外 4 種を判定する。
  発火語: sleep で待つ, polling, event-driven, 完了を待つ, Monitor tool, fswatch, inotify, wait $pid
- [playwright-chrome-profiles](playwright-chrome-profiles.md) — playwright-cli を Chrome Beta の複数プロファイルに attach して自動化する (token 取得・タブグループ・後始末・トラブルシュート)。
  発火語: playwright-cli, PLAYWRIGHT_MCP_EXTENSION_TOKEN, Chrome プロファイル, ブラウザ自動化, attach --extension, タブグループ, Playwright Extension
- [auto-mode-classifier](auto-mode-classifier.md) — auto mode classifier が読むもの、`autoMode` の 4 区分と課金、面横断 entries の例、プロジェクト固有の `classifier.local.md` (privacy 正本 + symlink) の設置と型、誤拒否の直し方。
  発火語: auto mode, classifier, Blocked by classifier, Credential Materialization, Secret-Store Writes, autoMode, environment, allow, soft_deny, hard_deny, /auto-mode-setup, classifier.local.md, 誤拒否
