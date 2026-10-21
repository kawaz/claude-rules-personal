# macOS 署名・notarization

kawaz の macOS 配布物 (CLI バイナリ / .app バンドル) を Apple Developer ID で codesign + notarize し、Gatekeeper 警告なしで配布するための手順集。canonical 実装は `kawaz/cache-warden` / `kawaz/authsock-warden` の `.github/workflows/release.yml` + `docs/runbooks/`。

リリースフロー全体 (VERSION bump → main push → CI が tag/release を作る) は reference の `justfile/release-pipeline`。ここはその macOS 署名部分の詳細。

## 索引

- [setup-certificates](setup-certificates.md) — 初回セットアップ: AI の手順、kawaz への依頼文、GitHub Secrets 6 種とプロダクト別の方針。
  発火語: APPLE_SIGNING_IDENTITY, APPLE_CERTIFICATE_BASE64, App-Specific Password, Developer ID Application, 署名 secrets が無くて CI が落ちた, p12 エクスポート
- [ci-release-pipeline](ci-release-pipeline.md) — release.yml の署名・notarize ステップの並びと、.app あり / bare binary のみの 2 形態。
  発火語: release.yml に署名を入れる, codesign bottom-up, notarytool submit, stapler staple, Hardened Runtime, 一時 keychain
- [tcc-app-bundle](tcc-app-bundle.md) — TCC と responsible process、.app バンドルで TCC 許可を永続化する形、FDA、Cask 配布。
  発火語: TCC, responsible process, FDA, フルディスクアクセス, LaunchAgent で許可が毎回消える, AssociatedBundleIdentifiers, Homebrew Cask
- [troubleshooting](troubleshooting.md) — notarize 403 PLA 再同意の即断診断 + 別系統エラーの切り分け表、その他既知エラー。
  発火語: notarize が失敗, A required agreement is missing or has expired, Invalid credentials, errSecInternalComponent, secure timestamp, spctl reject
- [system-extension](system-extension.md) — System/Network Extension 固有の要件 (プロファイル・entitlements・配置先)。
  発火語: System Extension, Network Extension, NETransparentProxyProvider, プロビジョニングプロファイル, systemextensionsctl
