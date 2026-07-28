---
name: macos-signing-notarization
description: macOS 配布バイナリ / .app の codesign + notarize 作業時に読む。証明書・Secrets 投入・障害対応の手順書 INDEX。
---

# macOS 署名・notarization

kawaz の macOS 配布物 (CLI バイナリ / .app バンドル) を Apple Developer ID で codesign + notarize し、
Gatekeeper 警告なしで配布するための手順集。canonical 実装は `kawaz/cache-warden` /
`kawaz/authsock-warden` の `.github/workflows/release.yml` + `docs/runbooks/`。

リリースフロー全体 (VERSION bump → main push → CI が tag/release を作る) は
`release-flow` skill を参照。本 skill はその macOS 署名部分の詳細。

## AI が自分でどこまでやるか

**Secrets 6 種のうち 4 種は AI が CLI で投入できる。** kawaz へ回すのは
`APPLE_ID` と `APPLE_APP_SPECIFIC_PASSWORD` の 2 つだけ。
Homebrew tap の `HOMEBREW_TAP_DEPLOY_KEY` は AI が全部できる
(`homebrew-tap-deploy-key` skill)。

新規プロダクトに署名を入れるときの動き方:

1. `setup-certificates.md` の「AI が先に済ませる」を実行 (4 種投入)
2. `homebrew-tap-deploy-key` skill で deploy key を作る (承認を 1 回取る)
3. 同 `setup-certificates.md` の「kawaz へ出す依頼文」をそのまま提示して残り 2 つを頼む

**「Secrets は人間の手作業」と丸ごと投げ返さない。** 分担は上記の表で確定している。

## リソース (作業に応じて読む)

- **`setup-certificates.md`** — 初回セットアップ。**実行者の分担表**、AI が実行する
  コマンド列、kawaz へ出す依頼文のテンプレ。Apple Developer Program 登録、p12 エクスポート →
  base64 → GitHub Secrets 6 種の投入。**プロダクト別に App-Specific Password を新規発行する方針**。
  署名 secrets が無くて CI が落ちた時もここ。
- **`ci-release-pipeline.md`** — release.yml の署名・notarize ステップ (keychain セットアップ →
  codesign bottom-up → notarytool submit --wait → stapler staple → keychain クリーンアップ always)。
  .app あり (staple 可) と bare binary のみ (zip notarize、staple 不可) の 2 形態。新設/移植時に読む。
- **`tcc-app-bundle.md`** — TCC / responsible process の仕組みと、.app バンドル +
  AssociatedBundleIdentifiers による Bundle ID ベース TCC 許可の永続化。FDA が必要なケース、
  Homebrew は Cask のみ配布。LaunchAgent 常駐サービスで TCC ダイアログが毎回出る時に読む。
- **`troubleshooting.md`** — notarize 403 PLA 再同意の即断診断 + 別系統エラーの切り分け表、
  その他既知エラー。CI の notarize ステップが失敗した時に読む。
- **`system-extension.md`** — System/Network Extension 固有 (プロビジョニングプロファイル、
  entitlements、/Applications 配置必須)。該当プロダクトを触る時のみ。
