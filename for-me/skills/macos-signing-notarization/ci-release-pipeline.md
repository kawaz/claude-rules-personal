# release.yml の署名・notarize パターン

macOS ジョブ (matrix の `*-apple-darwin`) に挿入する署名・notarize ステップ。
canonical: `kawaz/cache-warden` / `kawaz/authsock-warden` (.app あり)、`kawaz/jj-worktree` (bare binary)。

順序: **keychain セットアップ → codesign bottom-up → notarytool submit --wait →
(staple) → keychain クリーンアップ (always)**。`secrets` 6 種は `setup-certificates.md` で投入済み前提。

## 共通: 一時 keychain に証明書 import

`runner.os == 'macOS'` の各ステップに `if:` を付ける。

```yaml
- name: Import signing certificate (macOS)
  if: runner.os == 'macOS'
  env:
    APPLE_CERTIFICATE_BASE64: ${{ secrets.APPLE_CERTIFICATE_BASE64 }}
    APPLE_CERTIFICATE_PASSWORD: ${{ secrets.APPLE_CERTIFICATE_PASSWORD }}
  run: |
    CERTIFICATE_PATH=$RUNNER_TEMP/build_certificate.p12
    KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
    KEYCHAIN_PASSWORD=$(openssl rand -base64 32)

    echo -n "$APPLE_CERTIFICATE_BASE64" | base64 --decode -o $CERTIFICATE_PATH

    security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
    security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH

    security import $CERTIFICATE_PATH -P "$APPLE_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
    security list-keychain -d user -s $KEYCHAIN_PATH
    security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
```

## codesign のルール

- **bottom-up で署名**: ネストがある .app は内側のバイナリ → 外側の .app の順
- **`--deep` は使わない**: ネストの署名順序を保証せず Apple 非推奨
- **`--options runtime`** (Hardened Runtime) と **`--timestamp`** を付ける (notarize 必須要件)
- `--force` で既存署名を上書き

## 形態 A: .app バンドルあり (staple 可)

LaunchAgent 常駐サービス等で TCC の Bundle ID 永続化が必要なプロダクト (`tcc-app-bundle.md`)。
`.app` を作る → bottom-up 署名 → zip notarize → **staple できる**。

```yaml
- name: Sign .app bundle (macOS)
  if: runner.os == 'macOS'
  env:
    APPLE_SIGNING_IDENTITY: ${{ secrets.APPLE_SIGNING_IDENTITY }}
  run: |
    # bottom-up: バイナリ → .app
    codesign --sign "$APPLE_SIGNING_IDENTITY" --options runtime --force --timestamp \
      target/${{ matrix.target }}/release/MyApp.app/Contents/MacOS/my-bin
    codesign --sign "$APPLE_SIGNING_IDENTITY" --options runtime --force --timestamp \
      target/${{ matrix.target }}/release/MyApp.app
    codesign -dv --verbose=2 target/${{ matrix.target }}/release/MyApp.app

- name: Notarize (macOS)
  if: runner.os == 'macOS'
  env:
    APPLE_ID: ${{ secrets.APPLE_ID }}
    APPLE_APP_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
    APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
  run: |
    xcrun notarytool store-credentials "notary-profile" \
      --apple-id "$APPLE_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD" --team-id "$APPLE_TEAM_ID" \
      --keychain $RUNNER_TEMP/app-signing.keychain-db

    cd target/${{ matrix.target }}/release
    ditto -c -k --keepParent MyApp.app notarize.zip
    xcrun notarytool submit notarize.zip \
      --keychain-profile "notary-profile" --keychain $RUNNER_TEMP/app-signing.keychain-db \
      --wait --timeout 10m
    xcrun stapler staple MyApp.app    # .app には ticket を埋め込める
    rm notarize.zip
```

## 形態 B: bare binary のみ (staple 不可)

.app が不要な普通の CLI ツール。**単独バイナリには staple できない** (ticket 埋め込み先がない)
ため、notarize は submit までで完了。Gatekeeper はオンライン検証で公証を確認する。

```yaml
- name: Sign binary (macOS)
  if: runner.os == 'macOS'
  env:
    APPLE_SIGNING_IDENTITY: ${{ secrets.APPLE_SIGNING_IDENTITY }}
  run: |
    codesign --sign "$APPLE_SIGNING_IDENTITY" --options runtime --force --timestamp \
      target/${{ matrix.target }}/release/my-bin
    codesign -dv --verbose=2 target/${{ matrix.target }}/release/my-bin

- name: Notarize binary (macOS)
  if: runner.os == 'macOS'
  env:
    APPLE_ID: ${{ secrets.APPLE_ID }}
    APPLE_APP_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
    APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
  run: |
    xcrun notarytool store-credentials "notary-profile" \
      --apple-id "$APPLE_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD" --team-id "$APPLE_TEAM_ID" \
      --keychain $RUNNER_TEMP/app-signing.keychain-db

    cd target/${{ matrix.target }}/release
    zip notarize.zip my-bin
    xcrun notarytool submit notarize.zip \
      --keychain-profile "notary-profile" --keychain $RUNNER_TEMP/app-signing.keychain-db \
      --wait --timeout 10m
    rm notarize.zip       # staple なし (bare binary は ticket 埋め込み不可)
```

## 共通: keychain クリーンアップ (always)

署名/notarize が失敗しても一時 keychain を必ず消す。

```yaml
- name: Clean up keychain (macOS)
  if: always() && runner.os == 'macOS'
  run: |
    if [ -f "$RUNNER_TEMP/app-signing.keychain-db" ]; then
      security delete-keychain $RUNNER_TEMP/app-signing.keychain-db
    fi
```

## 形態の選び方

| 状況 | 形態 |
|---|---|
| LaunchAgent 常駐 + 他アプリ/保護リソースへアクセス (TCC 永続化が要る) | A: .app あり |
| 普通の CLI、TCC 関与なし | B: bare binary |

形態 A の .app バンドル作成手順・Homebrew Cask 配布・tar に bare binary も同梱する理由は
`tcc-app-bundle.md` を参照。

## 関連

- `setup-certificates.md` — 消費する 6 secrets の投入
- `tcc-app-bundle.md` — 形態 A を選ぶ判断と .app バンドル詳細
- `troubleshooting.md` — notarize 失敗時の診断
- [[release-flow-awareness]] — VERSION bump → release 全体フロー
