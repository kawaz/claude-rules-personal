# 証明書取得と GitHub Secrets 投入

macOS の codesign / notarization に使う証明書を取得し、release.yml が消費する
**6 種の GitHub Secrets** を投入する手順。Apple ID / Keychain Access の手操作が必要なため
**kawaz の手作業** (CI からは同名で参照され、workflow 側の変更は不要)。

## 証明書の種類

| 種類 | 費用 | Gatekeeper | 用途 |
|---|---|---|---|
| Apple Development | 無料 | 警告が出る | 個人・テスト用 |
| **Developer ID Application** | $99/年 (Apple Developer Program) | 警告なし | **配布用 (これを使う)** |

notarization には **Developer ID Application** 証明書が必須。Apple Development は warning が残る。

## Apple Developer Program 登録 (初回のみ)

1. Apple ID を作成 (<https://appleid.apple.com>。Apple デバイス不要)
2. Apple Developer Program に登録 ($99/年)。法人は D-U-N-S Number が必要
3. <https://developer.apple.com/account> → Certificates, Identifiers & Profiles で
   **Developer ID Application** 証明書を作成 (またはローカルの Keychain Access から CSR 経由で発行)

## 投入する Secret 一覧 (6 種)

| Secret | 値の性質 | 取得元 |
|---|---|---|
| `APPLE_ID` | Team 共通 | Apple ID のメールアドレス |
| `APPLE_TEAM_ID` | Team 共通 | Team ID (10 文字)。Membership details で確認 |
| `APPLE_APP_SPECIFIC_PASSWORD` | **プロダクト別に新規発行** | appleid.apple.com |
| `APPLE_CERTIFICATE_BASE64` | p12 を base64 化 | Keychain Access からエクスポート |
| `APPLE_CERTIFICATE_PASSWORD` | p12 エクスポート時に自分で決める | (自分で設定) |
| `APPLE_SIGNING_IDENTITY` | Team 共通 | `Developer ID Application: 名前 (TEAMID)` |

> **secrets はプロダクト別 (方針)**: 別プロダクトの secrets を使い回さず、新プロダクト用に発行する。
> 漏洩時の rotate 単位と影響範囲がプロダクトに閉じる。**主対象は `APPLE_APP_SPECIFIC_PASSWORD`**
> (rotate 単位)。`APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_SIGNING_IDENTITY` は Team 共通値なので
> 既存プロダクトの値をそのまま再利用してよい。証明書 (p12) も既存 Developer ID Application を
> 流用できるが、p12 は再エクスポートする。

以降 `REPO` = `kawaz/<product>` (例: `kawaz/cache-warden`) とする。

## 1. App-Specific Password の新規発行 (プロダクト用)

1. <https://appleid.apple.com> にサインイン
2. 「サインインとセキュリティ」→「App 用パスワード」→「App 用パスワードを生成」
3. ラベルに **`<product> notarytool`** 等の識別名 (= 他プロダクトと区別して個別 rotate するため)
4. 表示された `xxxx-xxxx-xxxx-xxxx` を控える (画面を閉じると再表示不可)

```bash
gh secret set APPLE_APP_SPECIFIC_PASSWORD --repo "$REPO"
# プロンプトに xxxx-xxxx-xxxx-xxxx を貼り付けて Enter
```

## 2. Developer ID Application 証明書を p12 でエクスポート

Team に既存の Developer ID Application 証明書がある前提。

1. **Keychain Access** を開く →「ログイン」キーチェーン →「自分の証明書」カテゴリ
2. `Developer ID Application: 名前 (TEAMID)` を展開し、**証明書と秘密鍵の両方**を選択
3. 右クリック →「2 項目を書き出す...」→ フォーマット **「個人情報交換 (.p12)」**
4. 保存先を決め、**エクスポートパスワード**を設定 (= `APPLE_CERTIFICATE_PASSWORD` になる)

```bash
# p12 を base64 化して投入 (改行なし)
base64 -i /path/to/cert.p12 | gh secret set APPLE_CERTIFICATE_BASE64 --repo "$REPO"

# エクスポート時に設定したパスワード
gh secret set APPLE_CERTIFICATE_PASSWORD --repo "$REPO"
```

> p12 は secret 投入後に削除する (`rm /path/to/cert.p12`)。リポや `~/.ssh` 等に残さない。

### CLI でエクスポートする場合の罠 (実踏 2026-06-12)

`security export -t identities` は **login keychain の全 identity を一括で p12 に含める**
(特定 identity だけ選ぶオプションは無い)。Apple Development 等の無関係な秘密鍵を CI secret に
上げてしまうので、**1 identity だけの p12 は一時 keychain 経由で作る**:

```bash
T=$(mktemp -d); KC="$T/tmp.keychain-db"
trap 'security delete-keychain "$KC" 2>/dev/null; rm -rf "$T"' EXIT
P1=$(openssl rand -base64 24); P2=$(openssl rand -base64 24); KCPASS=$(openssl rand -base64 24)

security export -k login.keychain-db -t identities -f pkcs12 -P "$P1" -o "$T/all.p12"  # ダイアログ 1 回
security create-keychain -p "$KCPASS" "$KC"
security import "$T/all.p12" -k "$KC" -P "$P1" -A

# 不要 identity を SHA-1 hash 指定で削除。
# `-c "Apple Development"` (名前指定) は中間証明書等に複数マッチして
# "ambiguous, matches more than one certificate" で失敗する。-Z が確実。
security find-identity -v "$KC"                      # hash を確認
security delete-identity -Z <不要identityのSHA1> "$KC"

security export -k "$KC" -t identities -f pkcs12 -P "$P2" -o "$T/devid.p12"
base64 -i "$T/devid.p12" | gh secret set APPLE_CERTIFICATE_BASE64 --repo "$REPO"
printf '%s' "$P2" | gh secret set APPLE_CERTIFICATE_PASSWORD --repo "$REPO"
# trap が一時 keychain と p12 を破棄
```

> 余分な identity が混入した p12 でも codesign は `$APPLE_SIGNING_IDENTITY` 名指しで
> 署名するため**動作はする**。問題は不要な秘密鍵の過剰共有であり、気づいたら上記で
> 作り直して secret を上書きすれば次のリリースから反映される (ローテーション不要の判断は
> 漏洩疑いの有無で)。

## 3. 共通値の投入

```bash
# Apple ID (メールアドレス)
gh secret set APPLE_ID --repo "$REPO"

# Team ID (10 文字。developer.apple.com の Membership details で確認)
gh secret set APPLE_TEAM_ID --repo "$REPO"

# 署名 identity の完全名。自分のマシンの値を確認:
security find-identity -v -p codesigning | grep "Developer ID Application"
# 例: "Developer ID Application: Yoshiaki Kawazu (XXXXXXXXXX)"
gh secret set APPLE_SIGNING_IDENTITY --repo "$REPO"
# 上記の "Developer ID Application: ..." 文字列を貼り付け
```

## 4. 投入確認

```bash
gh secret list --repo "$REPO"
# APPLE_ID / APPLE_TEAM_ID / APPLE_APP_SPECIFIC_PASSWORD /
# APPLE_CERTIFICATE_BASE64 / APPLE_CERTIFICATE_PASSWORD / APPLE_SIGNING_IDENTITY の 6 種
```

6 種が揃えば次回の version bump → main push で macOS ジョブの署名・notarization が通る。
未投入のまま release が走ると macOS ジョブが署名ステップで失敗する。

## ローテーション / 廃止

- App-Specific Password rotate: appleid.apple.com で旧パスワード無効化 → 手順 1 で再発行・再投入
- 証明書入れ替え: 手順 2 を再実行して `APPLE_CERTIFICATE_BASE64` / `APPLE_CERTIFICATE_PASSWORD` 更新
- プロダクト廃止: `gh secret delete <NAME> --repo "$REPO"` を 6 種分。
  App-Specific Password は appleid.apple.com 側でも無効化する

## ローカル署名 (CI を待たず手元で試す)

```bash
codesign --force --sign "Developer ID Application: 名前 (TEAMID)" --timestamp --options runtime <binary>
# 検証
codesign -dv --verbose=4 <binary-or-app>
spctl -a -vvv -t install <app>     # Gatekeeper 判定
```

## 関連

- `ci-release-pipeline.md` — 投入した secrets を消費する release.yml の署名ステップ
- `troubleshooting.md` — `Invalid credentials` (App-Specific Password 失効) 等の診断
