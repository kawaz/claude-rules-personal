# 参照知識の索引

## トピック (`<topic>/_index.md` を読んでから本文 1 ファイルへ)

- [vcs](vcs/_index.md) — jj / git の構成の見分け方と、コミット操作・組み替え・復旧・各方式のセットアップ・越境 push。
  発火語: jj commit, jj split, jj rebase, jj workspace, bookmark, colocate, worktree, PR 作成, push が拒否される, op restore, stale info, 越境 push
- [delegation](delegation/_index.md) — サブエージェント委譲の選定・context 見積り・Phase による順序制御・統括の立て直し。
  発火語: worker 選定, サブエージェント委譲, model と effort, context が足りない, Prompt is too long, Phase 0, 完了条件, 統括の立て直し, codex に大入力
- [testing](testing/_index.md) — テスト設計の網羅観点、テストを仕様書にするコメント様式、失敗時の説明責任。
  発火語: テスト設計, 境界値, 同値分割, デシジョンテーブル, テストコメント, flaky, たまに失敗する, timeout を伸ばす, ignore 化
- [design-spec](design-spec/_index.md) — 設計文書 (DR / プロトコル / 仕様) の着手前チェックと仕上げチェック。
  発火語: DR を書く, 仕様書, プロトコル設計, スコープの粒度, 不採用表, 節番号の参照, 設計文書のレビュー
- [docs-authoring](docs-authoring/_index.md) — `docs/` の構造標準・テンプレ・翻訳ペア・何をいつ書き残すか・裁定待ちの管理。
  発火語: docs 構造, DR を立てる, findings, journal, runbook, 翻訳ペア, README-ja, QUESTIONS.md, 裁定待ち
- [justfile](justfile/_index.md) — task runner の recipe 設計、リリースの標準ループ、push 後の watch 運用。
  発火語: justfile, just push, recipe, check-version-bumped, release.yml, リリースが出ない, tag が作られない, just watch
- [gh-ops](gh-ops/_index.md) — GitHub 上の画像の取得・投稿と、homebrew tap への自動 push 用 deploy key。
  発火語: GitHub の画像を取得, 画像を貼る, user-attachments, camo, raw.githubusercontent, HOMEBREW_TAP_DEPLOY_KEY, Permission to homebrew-tap denied
- [agent-runtime](agent-runtime/_index.md) — sleep / polling の代替 primitive と、ブラウザ自動化のプロファイル運用。
  発火語: sleep で待つ, polling, event-driven, Monitor tool, playwright-cli, PLAYWRIGHT_MCP_EXTENSION_TOKEN, Chrome プロファイル
- [macos-signing](macos-signing/_index.md) — macOS 配布物の codesign + notarize (証明書・Secrets・CI・TCC・トラブルシュート)。
  発火語: codesign, notarize, Developer ID, App-Specific Password, stapler, Gatekeeper, TCC, System Extension
- [role-main](role-main/_index.md) — 統括メイン (main role) がセッション開始時に順に Read する必須ロード一覧。
  発火語: セッション開始, 統括, main role, 必須ロード, load-role-main

## 単独の本文

- [cli-daemon-subcommands](cli-daemon-subcommands.md) — kawaz 製 CLI 共通の `daemon` / `service` サブコマンド体系 (1 instance = 1 unit、JSON 出力規約、OS 常駐登録)。
  発火語: daemon サブコマンド, service サブコマンド, supervise, 常駐プロセスの status / restart / log, launchd / systemd --user 登録, unit
- [app-file-placement](app-file-placement.md) — アプリのファイル置き場 (設定 / データ / 状態 / キャッシュ / socket・pid) を XDG Base Directory で判定する。
  発火語: config / data / state / cache / runtime の使い分け, XDG_CONFIG_HOME, XDG_STATE_HOME, XDG_RUNTIME_DIR が無い, unix socket path 長制限
- [direnv-exec-cwd](direnv-exec-cwd.md) — 別ディレクトリでコマンドを実行する形と、cd だけ / direnv exec だけで踏む罠。
  発火語: direnv exec, 別ディレクトリでコマンド実行, cd したのに .envrc が効かない, SSH_AUTH_SOCK が切り替わらない, git -C, direnv allow
- [op-run-secret-injection](op-run-secret-injection.md) — op run で secret を env に注入する形と、masking の 2 段運用。
  発火語: op run, 1Password CLI, op://, --no-masking, env-file, secret を env に注入
- [say-katakana](say-katakana.md) — `say` に渡す頭字語のカタカナ変換表と変換の適用範囲。
  発火語: say, 音声通知, 読み上げ, 頭字語のカタカナ化
- [cli-design-preferences](cli-design-preferences.md) — kawaz の CLI 設計の好み (サブコマンド構成 / `--help` の節構成 / bool フラグ / 引数位置 / completion)。
  発火語: CLI 設計, サブコマンド, --help, オプション, bool フラグ, completion, 引数パーサ
- [findings-recording](findings-recording.md) — findings ファイルの構成テンプレと、記録をサブエージェントに委譲するプロンプトの型。
  発火語: findings, 調査結果を記録, 検証記録, docs/findings, 記録委譲

## private 層 (`~/.local/share/repos/github.com/kawaz/privacy-personal/main/reference/`)

本文は private リポにあり、索引だけをここに写す (privacy 側の `reference/_index.md` を更新したら同じ変更でこちらも更新する)。未 clone なら何もしない。

- [kawaz-identity](~/.local/share/repos/github.com/kawaz/privacy-personal/main/reference/kawaz-identity.md) — kawaz 本人の表記正本 (漢字 / かな / ローマ字 / GitHub アカウント / 用途別の選び方 / 誤記)。
  発火語: 署名, 対外メール, 実名表記, 差出人名, ローマ字表記, GitHub アカウント名, 業務用アカウント
