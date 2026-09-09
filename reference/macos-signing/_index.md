# macOS 署名・notarization

kawaz の macOS 配布物 (CLI バイナリ / .app バンドル) を Apple Developer ID で codesign + notarize し、Gatekeeper 警告なしで配布するための手順集。canonical 実装は `kawaz/cache-warden` / `kawaz/authsock-warden` の `.github/workflows/release.yml` + `docs/runbooks/`。

リリースフロー全体 (VERSION bump → main push → CI が tag/release を作る) は reference の `justfile/release-pipeline`。ここはその macOS 署名部分の詳細。

## AI が自分でどこまでやるか

**Secrets 6 種は AI がほぼ全部投入できる。** kawaz に回るのは、そのプロダクト用の App-Specific Password を**新規発行する**ときだけ (発行後は 1Password 経由で AI が受け取る)。Homebrew tap の `HOMEBREW_TAP_DEPLOY_KEY` も AI が全部できる。

新規プロダクトに署名を入れるときの動き方:

1. `setup-certificates.md` の「AI が先に済ませる」1〜3 を実行 (identity / Team ID / 証明書 / Apple ID / App-Specific Password)
2. reference の `gh-ops/homebrew-tap-deploy-key` で deploy key を作る (承認を 1 回取る)
3. App-Specific Password が未発行のときだけ、同 `setup-certificates.md` の「kawaz へ出す依頼文」をそのまま提示する

**「Secrets は人間の手作業」と丸ごと投げ返さない。** 取得元は表で確定している。特に `APPLE_ID` は **1Password の「Apple Signing and Notarization」** にあり、iCloud のアカウントや証明書からは取れない (どちらも実踏で外した)。

## 索引

- [setup-certificates](setup-certificates.md) — 初回セットアップ (実行者の分担表、AI が実行するコマンド列、kawaz へ出す依頼文のテンプレ、p12 エクスポート → base64 → GitHub Secrets 6 種の投入、プロダクト別に App-Specific Password を発行する方針)。
  発火語: APPLE_SIGNING_IDENTITY, APPLE_CERTIFICATE_BASE64, App-Specific Password, Developer ID Application, 署名 secrets が無くて CI が落ちた, p12 エクスポート
- [ci-release-pipeline](ci-release-pipeline.md) — release.yml の署名・notarize ステップ (keychain セットアップ → codesign bottom-up → notarytool submit --wait → stapler staple → keychain クリーンアップ always) と、.app あり / bare binary のみの 2 形態。
  発火語: release.yml に署名を入れる, codesign bottom-up, notarytool submit, stapler staple, Hardened Runtime, 一時 keychain
- [tcc-app-bundle](tcc-app-bundle.md) — TCC / responsible process の仕組みと、.app バンドル + AssociatedBundleIdentifiers による Bundle ID ベース TCC 許可の永続化、FDA が必要なケース、Homebrew Cask 配布。
  発火語: TCC, responsible process, FDA, フルディスクアクセス, LaunchAgent で許可が毎回消える, AssociatedBundleIdentifiers, Homebrew Cask
- [troubleshooting](troubleshooting.md) — notarize 403 PLA 再同意の即断診断 + 別系統エラーの切り分け表、その他既知エラー。
  発火語: notarize が失敗, A required agreement is missing or has expired, Invalid credentials, errSecInternalComponent, secure timestamp, spctl reject
- [system-extension](system-extension.md) — System/Network Extension 固有の要件 (プロビジョニングプロファイル、専用 entitlements、/Applications 配置必須)。
  発火語: System Extension, Network Extension, NETransparentProxyProvider, プロビジョニングプロファイル, systemextensionsctl
