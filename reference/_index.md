# 参照知識の索引

## トピック (`<topic>/_index.md` を読んでから本文 1 ファイルへ)

- [vcs](vcs/_index.md) — jj / git でコミット・組み替え・復旧・セットアップ・越境 push をする時に読む (構成の見分け方から)。
  発火語: jj, colocate, worktree, PR 作成, push が拒否される, 壊した, 越境 push
- [delegation](delegation/_index.md) — サブエージェントに委譲する時 (worker 選定・入力量の見積り・作業順序・drift の立て直し) に読む。
  発火語: worker 選定, 委譲, Prompt is too long, 統括の立て直し
- [testing](testing/_index.md) — コードを新規に書く・修正する時 (何をどう検証するかを決める段階) と、テストが落ちた・不安定な時に読む。
  発火語: 実装する, コードを直す, テストを書く, flaky, たまに失敗する
- [typescript](typescript/_index.md) — TypeScript で型・スキーマ・lint を書く時に読む。
  発火語: valibot, zod, as を書きたい, unknown を受ける, oxlint
- [design-spec](design-spec/_index.md) — 設計文書 (DR / プロトコル / 仕様) を書く・レビューする時に読む。
  発火語: DR を書く, 仕様書, プロトコル設計, 設計文書のレビュー
- [docs-authoring](docs-authoring/_index.md) — `docs/` 配下に何かを書く・置き場に迷う時に読む (構造・テンプレ・翻訳ペア・裁定待ち)。
  発火語: docs 構造, どこに書く, 翻訳ペア, QUESTIONS.md
- [rules-authoring](rules-authoring/_index.md) — rule / skill / reference / memory を書く・移す・改廃する時に読む。
  発火語: rule を書く, skill を作る, reference に移す, 索引, ロードリスト
- [justfile](justfile/_index.md) — justfile を書く時と、push 後のリリース / watch で詰まった時に読む。
  発火語: justfile, recipe, リリースが出ない, just watch
- [gh-ops](gh-ops/_index.md) — GitHub 上の画像を取得・投稿する時と、homebrew tap への push 権限で詰まった時に読む。
  発火語: GitHub の画像, 画像を貼る, homebrew-tap denied
- [agent-runtime](agent-runtime/_index.md) — 待ち方 (sleep の代替)、ブラウザ自動化のプロファイル、auto mode classifier の設定で迷った時に読む。
  発火語: sleep で待つ, playwright-cli, Chrome プロファイル, classifier, 誤拒否
- [macos-signing](macos-signing/_index.md) — macOS 配布物に署名・notarize する時に読む。
  発火語: codesign, notarize, Gatekeeper, TCC
- [auth-patterns](auth-patterns/_index.md) — 認証 (passkey 登録、peer 間相互認証、自分の endpoint の確定) を設計する時に読む。
  発火語: passkey, peer 認証, 自分の endpoint
- [claude-mods](claude-mods/_index.md) — Claude Code の plugin / hook / mod (function hooks) を開発・修正する時に読む。
  発火語: Claude Mods, hooks module, plugin を作る, hook を書く
- [session-state](session-state/_index.md) — セッション境界 (clear / compact) で状態を引き継ぐ時に読む。
  発火語: pre-clear, 引き継ぎ, 状態ファイル
- [role-main](role-main/_index.md) — 統括メインがセッション開始時に読むロードリスト。
  発火語: セッション開始, 統括, ロードリスト
- [cli-design](cli-design/_index.md) — kawaz 製 CLI を設計する時に読む (好み、常駐プロセスの `daemon` / `service` サブコマンド体系)。
  発火語: CLI 設計, サブコマンド, --help, completion, daemon サブコマンド, 常駐

## 単独の本文

- [app-file-placement](app-file-placement.md) — アプリの設定 / データ / 状態 / キャッシュ / socket の置き場を決める時に読む (XDG)。
  発火語: どこに置く, XDG, socket path
- [direnv-exec-cwd](direnv-exec-cwd.md) — 別ディレクトリでコマンドを実行する時、.envrc が効かない時に読む。
  発火語: direnv exec, 別ディレクトリで実行, .envrc が効かない, git -C
- [op-run-secret-injection](op-run-secret-injection.md) — 1Password の secret をコマンドに渡す時に読む。
  発火語: op run, op://, secret を env に
- [say-katakana](say-katakana.md) — 音声通知の本文に略語を書く時に読む (カタカナ変換表)。
  発火語: PushNotification, 音声通知, 読み上げ
- [bark-push](bark-push.md) — iPhone / iPad の Bark アプリへ通知を送る時に読む。
  発火語: iPhone に通知, Bark, 端末に知らせる
- [artifacts-workspace](artifacts-workspace.md) — 生成物 (HTML / 画像) をブラウザで kawaz に見せる時に読む (`artifacts/` workspace と tmpspace.net)。
  発火語: artifacts, HTML を見せたい, 可視化を共有
- [findings-recording](findings-recording.md) — 調査・検証結果を `docs/findings/` に残す時に読む (テンプレと委譲プロンプト)。
  発火語: findings, 調査結果を記録

## private 層 (`~/.local/share/repos/github.com/kawaz/privacy-personal/main/reference/`)

本文は private リポにあり、索引だけをここに写す (privacy 側の `reference/_index.md` を更新したら同じ変更でこちらも更新する)。未 clone なら何もしない。

- [kawaz-identity](~/.local/share/repos/github.com/kawaz/privacy-personal/main/reference/kawaz-identity.md) — 対外文書で kawaz 本人を表記する時に読む (漢字 / かな / ローマ字 / アカウント名)。
  発火語: 署名, 対外メール, 実名表記, 業務用アカウント
