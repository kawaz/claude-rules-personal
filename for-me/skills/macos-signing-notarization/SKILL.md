---
name: macos-signing-notarization
description: kawaz の macOS 配布バイナリ / .app の codesign + notarize 関連作業時に読む。証明書取得・GitHub Secrets 投入・release.yml パターン・TCC/バンドル/notarize 障害対応の手順書 INDEX。Linux のみ配布や署名なし配布では不要。
---

# macOS 署名・notarization

kawaz の macOS 配布物 (CLI バイナリ / .app バンドル) を Apple Developer ID で codesign + notarize し、
Gatekeeper 警告なしで配布するための手順集。canonical 実装は `kawaz/cache-warden` /
`kawaz/authsock-warden` の `.github/workflows/release.yml` + `docs/runbooks/`。

リリースフロー全体 (VERSION bump → main push → CI が tag/release を作る) は
`release-flow` skill を参照。本 skill はその macOS 署名部分の詳細。

## リソース (作業に応じて読む)

- **`setup-certificates.md`** — 初回セットアップ。Apple Developer Program 登録、Developer ID /
  Apple Development 証明書の取得、p12 エクスポート → base64 → GitHub Secrets 6 種の投入。
  **プロダクト別に App-Specific Password を新規発行する方針**。署名 secrets が無くて CI が落ちた時もここ。
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
