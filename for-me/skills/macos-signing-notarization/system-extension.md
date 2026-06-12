# System / Network Extension 固有

System Extension (NetworkExtension の `NETransparentProxyProvider` 等) を含むアプリは、
通常の CLI/.app 署名に加えて **プロビジョニングプロファイル + 専用 entitlements** が要る。
該当プロダクトを触る時のみ読む。詳細手順は当該プロダクトリポの該当 PoC doc を参照する誘導とする。

## 通常の codesign/notarize との差分

| 項目 | 通常の .app | System/Network Extension |
|---|---|---|
| 証明書 | Developer ID Application | 同左 (推奨は Developer ID 方式) |
| entitlements | 不要 (Hardened Runtime のみ) | **専用 entitlement が必須** |
| プロビジョニングプロファイル | 不要 | **必須** (App ID ごとに作成) |
| 配置 | 任意 (Cask は /Applications) | **/Applications 必須** (SysExt 起動要件) |
| ユーザ承認 | TCC ダイアログ / FDA トグル | System Settings での **SysExt 許可** + 場合により再起動 |

## 署名方式 (2 つ)

| 方式 | 証明書 | entitlement 値 (例: app proxy) | 追加要件 |
|---|---|---|---|
| **Developer ID (推奨・配布用)** | Developer ID Application | `app-proxy-provider-systemextension` | ポータルで Developer ID プロファイル作成 |
| Apple Development (開発用) | Apple Development | `app-proxy-provider` | Recovery Mode で開発モード設定 |

## Developer ID 方式の手順 (配布向け)

1. <https://developer.apple.com/account> → Certificates, Identifiers & Profiles → Profiles → (+)
   - Type: **Developer ID**
   - App ID: ホストアプリ用 (Network Extension + System Extension capability 有効)
   - Certificate: 自分の `Developer ID Application` 証明書
   - **Network Extension ターゲット用の App ID 分のプロファイルも別途作成** (ホストと拡張で別 App ID)
2. ダウンロードしたプロファイルを Xcode に登録 (ダブルクリック)
3. ビルド設定の各ターゲットに `PROVISIONING_PROFILE_SPECIFIER` を指定

## Apple Development 方式 (ローカル開発のみ)

Recovery Mode で開発モードを有効化する必要がある:

1. Recovery Mode → 起動セキュリティユーティリティ → Reduced Security + kernel extension 許可
2. `csrutil disable` → 再起動 → `systemextensionsctl developer on`

## インストール / クリーンアップ

```bash
# 起動 (ホストアプリ実行 → SysExt インストールダイアログ → System Settings で許可)
open /Applications/<HostApp>.app

# 状態確認 / アンインストール (Team ID と拡張の Bundle ID を指定)
systemextensionsctl list
systemextensionsctl uninstall <TEAM_ID> <extension-bundle-id>
```

## サニタイズ注意

参考プロダクト (業務系) の doc には実 Team ID・法人名・業務 Bundle ID が載っているが、
**個人 skill には実値を書かない** (「自分の Team ID」「`<extension-bundle-id>`」等に一般化)。
具体値が要る時は当該プロダクトリポの PoC doc を直接見る。

## 関連

- `setup-certificates.md` — 証明書・Team ID の取得
- `ci-release-pipeline.md` — 署名・notarize の共通ステップ (SysExt でも keychain import 部分は共通)
