# 参照知識の索引

- 単独ファイルが大きくなったら整理分割しトピックにする。
- トピックは `<topic>/_index.md` から個別ファイルを読む形。runbook用スクリプト等のリソースも含めて良い。rules-authoring/reference-layout

## エージェントの心得やユーザ特有文書

- [delegation](delegation/_index.md) — サブエージェントに委譲する時 (worker 選定・移譲・入力量の見積り・作業順序・drift の立て直し) に読む。
- [design-spec](design-spec/_index.md) — 設計文書 (DR / プロトコル / 仕様) を書く・レビューする時に読む。
- [session-state](session-state/_index.md) — 作業を新しいセッションへ引き継ぐ時に読む (既定は同 cwd に launch して send で渡すライブ引き継ぎ、clear / compaction 前は状態ファイル)。
- [rules-authoring](rules-authoring/_index.md) — LLM ハーネスの rule / skill / reference / memory を書く・移す・改廃する時に読む。
- [findings-recording](findings-recording.md) — 調査・検証結果を `docs/findings/` に残す時に読む (テンプレと委譲プロンプト)。
- [role-main](role-main/_index.md) — 統括メインがセッション開始時に読むロードリスト。

## 成果物の書き方

- [testing](testing/_index.md) — テストの書き方、考え方。テストに限らずコードを新規で書く・修正する・設計するなら読む。
- [docs-authoring](docs-authoring/_index.md) — `docs/` 配下に何かを書く・置き場に迷う時に読む (構造・テンプレ・翻訳ペア・質問・裁定待ち・QUESTIONS.md)。
- [webui-structure](webui-structure.md) — kawaz 製 webui の構成 (部品とトークンを 1 か所、ビルド可、hash 付き URL) と画面の組み方 (1 画面に置きすぎない、操作は dialog に分離、modal は背景 inert で狭い幅は全画面、中間幅の検証、状態ラベルと無効化の表現、textarea、複数案の選び方)。
  発火語: webui, 管理画面, dialog, モーダル, コンポーネント, デザイントークン, Bun.build, 1 画面に置きすぎ, 操作ボタンの置き場, 状態ラベル, デザイン案の比較
- [artifacts](artifacts/_index.md) — HTML / JS / CSS 等の生ファイルを動作する形でユーザに見せたい時、tailnet の外の人に期限付きの公開 URL で共有したい時に読む (`artifacts/` workspace, artifacts-share)。

## 設計パターン集

- [app-file-placement](app-file-placement.md) — アプリの設定 / データ / 状態 / キャッシュ / socket の置き場 (XDG)。
- [cli-design](cli-design/_index.md) — kawaz 製 CLI を設計する時に読む (好み、常駐プロセスの `daemon` / `service` サブコマンド体系)。
- [proxy-dump-design](proxy-dump-design/_index.md) — proxy / gateway / LB に通信の一時ダンプ (時限・容量上限・自動削除つきで request / response をファイルに残す口) を付ける実装パターン。
- [auth-patterns](auth-patterns/_index.md) — 認証 (passkey 登録、peer 間相互認証、webhook 署名、自分の endpoint の確定) の設計パターン。
- [bark-push](bark-push.md) — ユーザへのスマホ通知をアプリに組み込みたい時に読む。
- [local-translate](local-translate.md) — 英文をクラウドを使わずに日本語へ訳したい時に読む (translate-server、OpenAI 互換 API、`chat_template_kwargs`、段落分割の指針)。
  発火語: 翻訳, 英日, translate-server, PLaMo, thinking の翻訳, 日英混在, 常体 / 敬体, glossary
- [claude-mods](claude-mods/_index.md) — Claude Code の plugin / hook / mod (function hooks) を開発・修正する時に読む。

## 特定ツール・作業・言語

- [direnv-exec-cwd](direnv-exec-cwd.md) — プロジェクト外パスでのコマンド実行方法 (gh トークン、ssh key の不一致で困った時にも)。
- [macos-signing](macos-signing/_index.md) — macOS 配布物に署名・notarize する時に読む (codesign, notarize, Gatekeeper, TCC)。
- [default-convergence](default-convergence/_index.md) — Rust / Go / TypeScript のコードを書く前に読む、手癖のデフォルトに流れやすい書き方の言語別一覧。
- [typescript](typescript/_index.md) — TypeScript で型・スキーマ・lint を書く時に読む (valibot, zod, `as` を書きたい, unknown を受ける)。
- [vcs](vcs/_index.md) — jj / git でコミット・組み替え・復旧・リポジトリセットアップ・越境 push (構成の見分け方から)。
- [justfile](justfile/_index.md) — justfile を書く時と、push 後のリリース / watch で詰まった時に読む。
- [gh-ops](gh-ops/_index.md) — GitHub の画像添付・取得手順、homebrew tap への push で詰まった時に読む。
- [x-posts](x-posts/_index.md) — X（Twitter）の投稿原文・メディアと、最近の話題・動画内容を調べる時に読む (x.com, x_search, Grok)。
- [agent-runtime](agent-runtime/_index.md) — 待ち方 (sleep の代替)、ブラウザ自動化のプロファイル、auto mode classifier の設定で迷った時に読む。
- [op-run-secret-injection](op-run-secret-injection.md) — 1Password の secret をコマンドに渡す時に読む (op run, `op://`)。
- [jev](jev/_index.md) — TypeSafe AI の判断 API Jev に質問を組む・答えを読む時に読む (Choice / Score / Noul, state, confidence)。

## private 層 (`~/.local/share/repos/github.com/kawaz/privacy-personal/main/reference/`)

本文は private リポにあり、索引だけをここに写す (privacy 側の `reference/_index.md` を更新したら同じ変更でこちらも更新する)。

- [kawaz-identity](~/.local/share/repos/github.com/kawaz/privacy-personal/main/reference/kawaz-identity.md) — kawaz 本人に関する情報 (署名、所属、読み、メアド、各種サイトのアカウント等)。
- [home-router-unifi](~/.local/share/repos/github.com/kawaz/privacy-personal/main/reference/home-router-unifi/_index.md) — 自宅ルータの設定ガイド- [tailscale-exit-node](~/.local/share/repos/github.com/kawaz/privacy-personal/main/reference/tailscale-exit-node.md) — auditor を exit node に使う時の設定と DNS の罠
- [family](~/.local/share/repos/github.com/kawaz/privacy-personal/main/reference/family.md) — 家族の呼び名 (父 / こちゃ / なお) と family カレンダーの定例予定。
