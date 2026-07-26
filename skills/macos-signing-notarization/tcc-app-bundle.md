# TCC / responsible process と .app バンドル化

LaunchAgent 常駐サービスが保護リソース (他アプリのデータ等) にアクセスすると、TCC 許可が
**毎回失われる/ダイアログが出る**問題への対処。**.app バンドル + Bundle ID** で永続化する。
canonical: `kawaz/authsock-warden` (DR-012/013/014, `docs/macos-tcc-fda.md`)。

## TCC と responsible process

TCC (Transparency, Consent, and Control) はアクセスを要求した **responsible process** に対して
許可を管理する。誰が responsible になるかは**起動経路で変わる**:

| 起動経路 | responsible process | 永続性 |
|---|---|---|
| Terminal.app → shell → bin | `com.apple.Terminal` (Bundle ID) | 一度許可で永続 |
| LaunchAgent → bin (素のバイナリ) | **バイナリの実体パス** | パスが変わると許可消失 |
| LaunchAgent → .app/Contents/MacOS/bin | **.app の Bundle ID** | パス非依存で永続 |
| `open MyApp.app` | .app の Bundle ID | 永続 + FDA リスト自動追加 |

**問題**: Homebrew はバージョン付きディレクトリ (`.../Cellar/x/0.1.11/bin/...`) に入れるため、
LaunchAgent 経由だと `brew upgrade` のたびにパスが変わり TCC 許可が失われる。

**解決**: .app バンドルにラップすると responsible process が Bundle ID になり、パス変更に強い。

> **symlink 案は効かない (実証済み)**: 「保護パスへの symlink を張って実体を避ける」案は、
> macOS が TCC チェック時に **symlink を実体パスに解決する**ため無意味 (authsock-warden v0.1.11 で
> 検証、根本解決にならず .app バンドル化に移行)。

## .app バンドルの作り方 (CI 内で mktemp 的に生成)

```
MyApp.app/Contents/
  Info.plist
  MacOS/my-bin          # 実行バイナリ
```

`Info.plist` の要点:

```xml
<key>CFBundleExecutable</key>   <string>my-bin</string>
<key>CFBundleIdentifier</key>   <string>com.github.kawaz.my-product</string>
<key>CFBundlePackageType</key>  <string>APPL</string>
<key>LSBackgroundOnly</key>     <true/>   <!-- Dock 非表示・GUI なしの常駐サービス -->
```

署名は bottom-up (バイナリ → .app)、`--deep` 不使用 (`ci-release-pipeline.md` 形態 A)。

## LaunchAgent plist 側の関連付け

LaunchAgent plist に `AssociatedBundleIdentifiers` を入れ、launchd がプロセスを .app の
Bundle ID と関連付けるようにする:

```xml
<key>AssociatedBundleIdentifiers</key>
<array><string>com.github.kawaz.my-product</string></array>
```

## FDA が必要になるケース (kTCCServiceSystemPolicyAppData)

.app バンドル化で Bundle ID 識別は得られるが、**カテゴリによっては .app 化だけでは永続化しない**:

| カテゴリ | 対象 | .app 化で永続? |
|---|---|---|
| `kTCCServiceSystemPolicyAppData` (他アプリのデータ) | `~/Library/Group Containers/` 等 | **しない** (LaunchAgent 経由でダイアログが毎回出る) |
| `kTCCServiceSystemPolicyAllFiles` (FDA) | ファイルシステム全体 | する (System Settings で ON にすれば永続) |

FDA は AppData を**包含する**。よって他アプリのデータ (例: 1Password の Group Containers) に
LaunchAgent から触る必要があるなら、AppData の個別許可ではなく **FDA を ON** にしてもらうのが
実用解 (authsock-warden DR-014)。FDA は名目上「全ディスク」だが実アクセスは限定的、という旨を
ユーザ案内に明記する。

FDA 状態のチェックは `/Library/Application Support/com.apple.TCC/TCC.db` の読み取り可否で判定
(読めれば ON。OFF と未登録は区別不能)。正しい responsible process で見るため `.app` として起動する:

```bash
open --wait-apps /Applications/MyApp.app --args internal fda-check --raw
# open で .app 起動すると FDA リストに自動追加される ("+" 不要、ユーザはトグル ON だけ)
# LSBackgroundOnly の .app は stderr に "Unable to ... block on" ノイズが出る → /dev/null へ
```

## Homebrew 配布は Cask のみ (Formula 不可)

**.app を含むプロダクトは Homebrew Formula で配布できない (実証)**: Formula の tarball stripping が
単一トップレベルディレクトリ (`MyApp.app`) を展開先ルートに strip して .app を壊す
(authsock-warden v0.1.12 で破損)。また Formula + Cask 同名共存は `formula requires at least a URL`
等で噛み合わない。→ **Cask 一本**で配布する (DR-013)。

```ruby
cask "my-product" do
  version "..."
  on_arm  { sha256 "..."; url ".../my-product-aarch64-apple-darwin.tar.gz" }
  on_intel { sha256 "..."; url ".../my-product-x86_64-apple-darwin.tar.gz" }
  app "MyApp.app"
  binary "#{appdir}/MyApp.app/Contents/MacOS/my-bin"   # CLI パスを通す symlink
end
```

CI 側で `Formula/<name>.rb` を `rm -f` してから Cask を書く (stale Formula 残留防止)。

> tar には **.app と bare binary を両方**入れる: 単一トップレベルディレクトリだと Homebrew が
> strip するため、bare binary を併置してトップレベルを 2 エントリにする (`ci-release-pipeline.md`
> 形態 A の Package ステップ参照)。

## Linux ユーザ

Cask は macOS 専用。Linux は GitHub Releases から `*-linux-*.tar.gz` を直接取得してもらう。

## 関連

- `ci-release-pipeline.md` — 形態 A の署名・staple ステップ
- `setup-certificates.md` — 署名 secrets
